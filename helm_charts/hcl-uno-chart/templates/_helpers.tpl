{{- define "uno.global.chart" -}}
microservice.version: "version"
{{- end -}}

{{- define "fullname" -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{- define "unofullname" -}}
{{- $name :=  .Release.Name  -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{- define "waMdm.ServiceName" -}}
{{ $fullName := include "unofullname" . }}
{{- printf "%s-%s" $fullName "gateway" -}}
{{- end -}}

{{- define "wa.console.waUser" -}}
{{ $fullName := include "unofullname" . }}
{{- $name := default .Values.global.serviceAccountName "uno-user" -}}
{{- printf "%s-%s" $fullName  $name  -}}
{{- end -}}

{{- define "uno.console.public.host" -}}
{{ $fullName := include "fullname" . }}
{{- if ((((.Values).waconsole).console).ingress).hostname -}}
{{- printf "%s"  .Values.waconsole.console.ingress.hostname -}}
{{- else  -}}
{{- printf "%s-%s"  $fullName "waconsole" -}}
{{- end -}}
{{- end -}}

{{- define "uno.console.public.port" -}}
{{ $fullName := include "fullname" . }}
{{- if ((((.Values).waconsole).console).ingress).hostname -}}
{{- printf "%s"  "443" -}}
{{- else  -}}
{{- printf "%s"  "9443" -}}
{{- end -}}
{{- end -}}

{{- define "uno.chart.common.label" -}}
uno.microservice.version: 1.1.2.0
app.kubernetes.io/name: {{ .Release.Name | quote}}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
helm.sh/chart: {{ .Chart.Name | quote }}
meta.helm.sh/release-name: {{ .Release.Name | quote }}
release: {{ .Release.Name | quote }}
{{- range .Values.global.customLabels }}
{{ .name }}: {{ .value | quote }} 
{{- end }}
{{- end -}}

{{- define "uno.cert.issuer" -}}
{{- printf "%s"  "wa-ca-issuer" -}}
{{- end -}}

{{- define "common.dwc.hidden.env" -}}
- name: ENGINE_TYPE
  value: "uno"
- name: IS_UNO
  value: "true"
{{- end -}}

{{- define "waconsole.packagesUrl" -}}
{{- $name := default .Release.Name -}}
{{- printf "%s%s-%s" "https://" $name "storage:8443/ui/downloads/" -}}
{{- end -}}


