{{/* Common labels for a component. Usage: include "ems.labels" (dict "ctx" $ "name" "mysql") */}}
{{- define "ems.labels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/part-of: ems
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
helm.sh/chart: {{ .ctx.Chart.Name }}-{{ .ctx.Chart.Version }}
{{- end }}

{{- define "ems.selector" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
{{- end }}

{{- define "ems.image" -}}
{{ .ctx.Values.image.registry }}/{{ .image }}:{{ .ctx.Values.image.tag }}
{{- end }}

{{/* Pod-level security context that satisfies Pod Security "restricted". */}}
{{- define "ems.podSecurity" -}}
runAsNonRoot: true
runAsUser: {{ .uid | default 10001 }}
runAsGroup: {{ .uid | default 10001 }}
fsGroup: {{ .uid | default 10001 }}
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "ems.containerSecurity" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: {{ .readOnly | default false }}
capabilities:
  drop: ["ALL"]
{{- end }}

{{/* Init container that waits for host:port pairs (CKA: init containers). */}}
{{- define "ems.waitFor" -}}
{{- if .targets }}
initContainers:
  - name: wait-for-deps
    image: busybox:1.36
    command:
      - sh
      - -c
      - |
        for t in {{ join " " .targets }}; do
          until nc -z -w 2 ${t%%:*} ${t##*:}; do echo "waiting for $t"; sleep 3; done
        done
    securityContext:
      {{- include "ems.containerSecurity" (dict "readOnly" true) | nindent 6 }}
    resources:
      requests: { cpu: 5m, memory: 8Mi }
      limits: { memory: 16Mi }
{{- end }}
{{- end }}

{{- define "ems.required" -}}
{{ required (printf "set secrets.%s (see secrets.local.yaml.example)" .key) (index .ctx.Values.secrets .key) }}
{{- end }}

{{- /* Peer selector: "gateway" means the kgateway proxy pods, anything else an app label. */}}
{{- define "ems.peer" -}}
{{- if eq .peer "gateway" }}
- podSelector:
    matchLabels: {{- toYaml .ctx.Values.gateway.proxyPodLabels | nindent 6 }}
{{- else }}
- podSelector:
    matchLabels:
      app.kubernetes.io/name: {{ .peer }}
{{- end }}
{{- end }}
