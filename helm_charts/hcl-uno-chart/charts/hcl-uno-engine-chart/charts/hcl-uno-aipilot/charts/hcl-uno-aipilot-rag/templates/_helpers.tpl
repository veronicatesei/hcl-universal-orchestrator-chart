{{/* Generate the name of the service */}}
{{- define "rag.serviceName" -}}
{{- printf "%s-%s" .Release.Name .Values.service.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate the name of the deployment */}}
{{- define "rag.deploymentName" -}}
{{- printf "%s-%s" .Release.Name .Values.app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate the name of the HPA */}}
{{- define "rag.hpaName" -}}
{{- printf "%s-%s" .Release.Name .Values.hpa.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate the name of the ConfigMap */}}
{{- define "rag.configMapName" -}}
{{- printf "%s-%s" .Release.Name .Values.configMap.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rag.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName  }}
serviceAccountName: {{ tpl .Values.global.serviceAccountName .}}
{{- else if .Values.serviceAccount }}
serviceAccountName: {{ tpl .Values.serviceAccount  .}}
{{- end }}
{{- end }}


{{- define "rag.common.label" -}}
{{- /*COMMENT - This if is a dirty way to check if it's cloud or not (NEEDS TO BE CHANGED)-  */}}
{{- if .Values.global.customEnv }}
{{ include "uno.common.label" .}}
{{- else }}
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
{{- end -}}

{{- define "fullname" -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}


{{- define "uno.fullname" -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{- /* 
    {{- else if .Values.certificates.caPairSecretName -}}
    {{- tpl .Values.certificates.customIssuer . | default (printf "%s-aipilot-ca-issuer" (include "aipilot.fullName" . ))}}
*/ -}}

{{- define "aipilot.fullName" -}}
{{- if .Values.fullNameOverride }}
{{- .Values.fullNameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Release.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "rag.cert.issuer" -}}
{{- if .Values.certificates.issuerName -}}
    {{- tpl .Values.certificates.issuerName . -}}
{{- else -}}
    {{ $fullName := include "fullname" . }}
    {{- printf "%s-%s"  $fullName "aipilot-rag-ca-issuer" -}}
{{- end -}}
{{- end -}}

{{- define "rag.cert.secret.name" -}}
{{- tpl  .Values.certificates.certSecretName . }}
{{- end -}}


{{- define "rag.ca.secret.name" -}}
{{- if .Values.certificates.caPairSecretName -}}
{{- tpl  .Values.certificates.caPairSecretName . | quote }}
{{- else -}}
{{ $fullName := include "fullname" . }}
{{- printf "%s-%s"  $fullName "aipilot-rag-ca" -}}
{{- end -}}
{{- end -}}

{{- define "rag.apikey" -}}
{{- if .Values.global.cloudCredentials -}}
{{ .Values.global.cloudCredentials.gcp | quote }}
{{- else -}}
{{ .Values.config.gcp_key | b64enc | quote }}
{{- end -}}
{{- end -}}

{{- define "rag.postgres.password" -}}
{{- printf "%s-%s" .Release.Name  "postgres-password-secret" -}}
{{- end -}}

{{- define "rag.pull.secret" -}}
imagePullSecrets:
{{- if .Values.global.hclImagePullSecret  }}
    - name: {{ tpl .Values.global.hclImagePullSecret .}}
{{- end }}
{{- if .Values.additionalPullSecret }}
    - name: {{ tpl .Values.additionalPullSecret . }}
{{- end }}
    - name: sa-{{ .Release.Namespace }}
    - name: sa-uno
{{- end -}}

{{- define "postgres.password" -}}
{{ printf "%s-%s" .Release.Name  "postgres-password-secret" }}
{{- end -}}

{{- define "rag.sofy.env.variables" -}}
{{- if .Values.global.sofySolutionContext }}
- name : SOFY_HOSTNAME
  valueFrom:
    configMapKeyRef:
        name: {{ .Release.Name }}-domain
        key : HOST
{{- end }}
{{- end -}}

{{- define "rag.registry" -}}
{{- if eq .Values.global.hclImageRegistry "hclcr.io/sofy" -}}
hclcr.io/uno
{{- else if eq .Values.global.hclImageRegistry "hclcr.io" -}}
hclcr.io/uno
{{- else if eq .Values.global.hclImageRegistry "gcr.io/blackjack-209019" -}}
gcr.io/blackjack-209019/services/uno
{{- else if .Values.global.hclImageRegistry -}}
{{ print .Values.global.hclImageRegistry }}
{{- else -}}
{{ print .Values.container.registry }}
{{- end -}}
{{- end -}}