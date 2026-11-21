import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gridiagram import Canvas
K = "k8s/"
d = Canvas(1100, 700, "Every Kubernetes object behind one service", "employee-service in namespace ems; the other services follow the same pattern")
d.legend(560, 40, [("control", "controls"), ("ok", "traffic"), ("default", "config"), ("metric", "admission / policy")])
d.group("namespace ems", 30, 95, 1040, 590, "blue")
# controllers row
d.node("hpa", K+"clusterconfig/hpa.png", "HPA\n1-2 replicas, CPU 70%", 110, 215)
d.node("deploy", K+"compute/deploy.png", "Deployment\nsurge 1, unavailable 0", 285, 215)
d.node("rs", K+"compute/rs.png", "ReplicaSet\nper image SHA", 455, 215)
# traffic row
d.node("svc", K+"network/svc.png", "Service\nClusterIP :8080", 285, 395)
d.node("ep", K+"network/ep.png", "EndpointSlice\nready pods only", 455, 395)
# pods
d.group("Pods", 560, 140, 240, 340, "white", gid="pods")
d.node("p1", K+"compute/pod.png", "pod", 625, 215)
d.node("p2", K+"compute/pod.png", "pod", 735, 215)
for i, t in enumerate(["uid 10001, non-root", "read-only root FS", "drop ALL capabilities", "probes: startup · live · ready",
                       "JVM capped at 448 Mi", "PDB: minAvailable 1"]):
    d.note("· " + t, 582, 300 + i * 22, size=12)
# config column
d.group("config and identity", 850, 140, 190, 340, "white")
d.node("cm", K+"podconfig/cm.png", "ConfigMap\nenv, JAVA_TOOL_OPTIONS", 945, 205)
d.node("sec", K+"podconfig/secret.png", "Secrets\nmysql, rabbitmq", 945, 300)
d.node("sa", K+"rbac/sa.png", "ServiceAccount\nno token mounted", 945, 395)
# guards row
d.node("np", K+"network/netpol.png", "NetworkPolicy\nin: api-gateway  out: dept, db, mq", 285, 590)
d.group("namespace guards", 560, 520, 480, 150, "white")
d.node("quota", K+"clusterconfig/quota.png", "ResourceQuota\n4 Gi requests", 640, 590)
d.node("limits", K+"clusterconfig/limits.png", "LimitRange\ndefaults", 800, 590)
d.node("psa", K+"others/psp.png", "Pod Security\nrestricted", 960, 590)

d.edge("hpa", "deploy", "scale", kind="control", route="h")
d.edge("deploy", "rs", kind="control", route="h")
d.edge("rs", "pods", "owns", kind="control", route="h", tp=-95)
d.edge("svc", "ep", kind="ok", route="h")
d.edge("ep", "pods", "routes", kind="ok", route="h", tp=85)
d.edge("cm", "pods", "envFrom", route="h", tp=-105)
d.edge("sec", "pods", "secretKeyRef", route="h", tp=-10)
d.edge("sa", "pods", route="h", tp=85)
d.edge("np", "pods", "selects", kind="metric", via=[(590, 590)], sides=("r", "b"), tp=-90, lpos=(470, 590))
d.edge("quota", "pods", kind="metric", route="v", tp=-40, sides=("t", "b"))
d.edge("limits", "pods", "admit", kind="metric", via=[(800, 500), (720, 500)], sides=("t", "b"), tp=40, lpos=(880, 500))
d.edge("psa", "pods", kind="metric", via=[(960, 500), (720, 500)], sides=("t", "b"), tp=40)
d.save(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "img", "k8s-objects"))
