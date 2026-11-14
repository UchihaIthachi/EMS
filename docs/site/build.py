#!/usr/bin/env python3
"""Build the EMS Architecture Atlas web page from docs/diagrams.md.

docs/diagrams.md is the single source of truth: this script takes its Mermaid
blocks in order and wraps them with captions, an index and two simulators.

  python3 docs/site/build.py              # -> docs/site/dist/index.html (GitHub Pages)
  python3 docs/site/build.py --fragment   # body-only fragment (for hosts that add their own <html> and render Mermaid)
"""
import html
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
MD = HERE.parent / "diagrams.md"
MERMAID = "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js"

CAP = {
 1: "Who uses EMS and what it depends on. Images come from CI, and operators work through Helm, kubectl and the runbook.",
 2: "Two domain services behind an edge of Gateway API and Spring Cloud Gateway. MySQL holds one database per service, RabbitMQ carries events, and Redis caches departments.",
 3: "The synchronous read. The department lookup is wrapped in a circuit breaker and served from Redis when possible. Measured: 46–110 ms for one traced request, p95 13–25 ms under k6.",
 4: "The write returns 201 as soon as the employee row commits. The stats update happens asynchronously through RabbitMQ, so it's eventually consistent.",
 5: "Resilience4j settings from employee-service: a 10-call count window, at least 5 calls, 50% failure or slow-call rate, 15 s open, 2 trial calls.",
 6: "What happens on every call. A 3 s time limiter means no request thread waits longer, and the fallback returns the employee without department data.",
 7: "Redis is an optimisation, never a dependency. Errors become cache misses, writes evict instead of updating, and Redis is left out of readiness.",
 8: "A topic exchange, so new consumers can bind without touching the producer. Rejected messages go through a direct dead-letter exchange to a durable DLQ.",
 9: "Transient failures are retried 3 times; poison messages skip retries and go straight to the DLQ. A consumer crash before the ack means a redelivery.",
 10: "The dedupe row and the read-model update commit in one transaction. That gives effectively-once processing on an at-least-once broker.",
 11: "Each service owns its tables. Employees reference departments by code, and the reference is checked over HTTP, not by a foreign key.",
 12: "A 16 GB laptop running three Lima VMs: kubeadm v1.37.2, Calico, metrics-server, local-path, Gateway API with kgateway, and KEDA.",
 13: "Every object behind one service. Config and secrets go in as env vars, and the HPA, PDB and NetworkPolicy each target the same pods by label.",
 14: "Two routing layers: Gateway API routes by path for the platform, and Spring Cloud Gateway routes by path for the application.",
 15: "Default deny in both directions. These edges are the only flows allowed, plus DNS for every pod.",
 16: "metrics-server feeds the HPA controller every 15 s. Measured: 1 → 2 replicas at 78% CPU against a 70% target.",
 17: "KEDA turns queue length into an external metric for an HPA it owns. Measured: queue depth 94 → 2 pods, then drained to 0 with an empty DLQ.",
 18: "maxSurge 1 / maxUnavailable 0 plus readiness gates mean a bad release never replaces a good pod. The PDB refuses the second eviction during a drain.",
 19: "Images are tagged by commit SHA, never latest. The deploy waits for CI, upgrades with Helm, and stops on a failed smoke test.",
 20: "Metrics show whether it's healthy, traces show where the time went, and logs show why it failed.",
 21: "Six layers, from the image to the secrets. Pod Security restricted is enforced on the namespace.",
 23: "Memory measured under load. The JVMs are capped at 448 MiB, and the namespace quota is 4 GiB requests / 5 GiB limits.",
 24: "The cluster operations practised on the lab: upgrade under load, etcd snapshot and restore, and certificate renewal.",
 25: "What changes as traffic grows. The Kustomize full overlay already covers the 10× column's replica counts.",
}

GROUPS = [
 ("overview", "Overview", "The system and its data.", [1, 2, 11]),
 ("paths", "Request paths", "What a read and a write actually do.", [3, 4, 14]),
 ("resilience", "Resilience", "Circuit breaker, cache and failure behaviour.", [5, "SIM_CB", 6, 7, 22]),
 ("messaging", "Messaging", "Events, retries, dead letters and idempotency.", [8, 9, 10]),
 ("kubernetes", "Kubernetes", "Cluster, objects, traffic and policy.", [12, 13, 15, 21]),
 ("scaling", "Scaling", "CPU and queue autoscaling, budget and growth path.", [16, 17, "SIM_SCALE", 23, 25]),
 ("delivery", "Delivery & ops", "Rollouts, pipeline, observability, operations.", [18, 19, 20, 24]),
]


def parse(md: str):
    """Return {section number: (title, mermaid source or None, markdown table or None)}."""
    parts = re.split(r"^## (\d+)\. (.+)$", md, flags=re.M)
    out = {}
    for i in range(1, len(parts), 3):
        n, title, body = int(parts[i]), parts[i + 1].strip(), parts[i + 2]
        m = re.search(r"```mermaid\n(.*?)```", body, re.S)
        t = re.search(r"((?:^\|.*\|\n)+)", body, re.M)
        out[n] = (title, m.group(1) if m else None, t.group(1) if t else None)
    return out


def md_table(tbl: str) -> str:
    rows = [r.strip().strip("|").split("|") for r in tbl.strip().splitlines()]
    rows = [[c.strip() for c in r] for r in rows if not re.match(r"^[\s:|-]+$", "|".join(r))]
    cell = lambda c: re.sub(r"`([^`]+)`", r"<code>\1</code>", html.escape(c))
    head = "".join(f"<th>{cell(c)}</th>" for c in rows[0])
    body = "".join("<tr>" + "".join(f"<td>{cell(c)}</td>" for c in r) + "</tr>" for r in rows[1:])
    return f'<div class="tablewrap"><table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>'


def figure(n, title, src, tbl):
    cap = CAP.get(n, "")
    if src:
        inner = f'<div class="diagram"><pre class="mermaid">{html.escape(src)}</pre></div>'
    else:
        inner = md_table(tbl)
        cap = cap or "What breaks, what a user sees, why, and where it was proven."
    return (f'<figure class="fig" id="d{n}"><figcaption><span class="num">{n:02d}</span><h3>{html.escape(title)}</h3>'
            f'<span class="figtools"><button type="button" data-zoom="d{n}">Expand</button></span></figcaption>'
            f'<p class="cap">{html.escape(cap)}</p>{inner}</figure>')


def build(fragment: bool) -> str:
    d = parse(MD.read_text())
    sims = {"SIM_CB": (HERE / "sim_cb.html").read_text(), "SIM_SCALE": (HERE / "sim_scale.html").read_text()}
    nav, index, sections = [], [], []
    for gid, title, sub, items in GROUPS:
        nav.append(f'<a href="#{gid}">{title}</a>')
        index.append(f'<h4>{title}</h4>')
        body = []
        for it in items:
            if it in sims:
                body.append(sims[it])
                index.append(f'<a href="#{"cb-sim" if it == "SIM_CB" else "scale-sim"}"><span>▶</span>Try it: {"circuit breaker" if it == "SIM_CB" else "HPA and KEDA"}</a>')
            else:
                t, src, tbl = d[it]
                body.append(figure(it, t, src, tbl))
                index.append(f'<a href="#d{it}"><span>{it:02d}</span>{html.escape(t)}</a>')
        sections.append(f'<section class="group" id="{gid}"><header class="ghead"><h2>{title}</h2><p>{sub}</p></header>{"".join(body)}</section>')

    page = (HERE / "template.html").read_text()
    head_extra = script_extra = ""
    if not fragment:
        script_extra = f'''<script src="{MERMAID}"></script>
<script>
  const dark = matchMedia('(prefers-color-scheme: dark)').matches;
  mermaid.initialize({{ startOnLoad: false, securityLevel: 'strict', theme: dark ? 'dark' : 'neutral',
    fontFamily: '"IBM Plex Sans", ui-sans-serif, system-ui, sans-serif', flowchart: {{ htmlLabels: true }} }});
  mermaid.run({{ querySelector: 'pre.mermaid' }});
</script>'''
    page = (page.replace("{{HEAD_EXTRA}}", head_extra).replace("{{NAV}}", "".join(nav))
                .replace("{{INDEX}}", "".join(index)).replace("{{SECTIONS}}", "\n".join(sections))
                .replace("{{SCRIPT_EXTRA}}", script_extra))
    if fragment:
        return page
    return ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
            '<meta name="description" content="EMS on Kubernetes: 25 architecture diagrams with circuit-breaker and HPA/KEDA simulators.">\n'
            '<style>html{color-scheme:light dark}body{margin:0}[hidden]{display:none!important}</style>\n'
            '</head>\n<body>\n' + page + '\n</body>\n</html>\n')


if __name__ == "__main__":
    frag = "--fragment" in sys.argv
    out = HERE / "dist" / ("fragment.html" if frag else "index.html")
    out.parent.mkdir(exist_ok=True)
    out.write_text(build(frag))
    print(out)
