{{/*
Expand the name of the chart.
*/}}
{{- define "aipilot.name" -}}
{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aipilot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aipilot.labels" -}}
helm.sh/chart: {{ include "aipilot.chart" . }}
{{ include "aipilot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aipilot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aipilot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
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

{{- define "uno.fullname" -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{- define "aipilot.selectorLabels.backend" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- include "aipilot.selectorLabels" $root }}
name: {{ include "aipilot.fullName" $root }}-{{ $container.name }}
track: {{ $root.Values.track }}
tier: backend
{{- end }}

{{- define "aipilot.selectorLabels.frontend" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{  include "aipilot.selectorLabels" $root }}
name: {{ include "aipilot.fullName" $root }}-{{ $container.name }}
track: {{ $root.Values.track }}
tier: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "aipilot.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName }}
serviceAccountName: {{ tpl .Values.global.serviceAccountName .}}
{{- else if .Values.serviceAccount }}
serviceAccountName: {{ tpl .Values.serviceAccount.name  .}}
{{- end }}
{{- end }}

{{/*
Create image name as "repository-name:tag".
*/}}
{{- define "aipilot.image" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- if $container.image -}} 
image: "{{ default $root.Values.image.repository $container.image.repository}}/hcl-aipilot-{{ $container.imageName }}:{{ default $root.Values.image.tag $container.image.tag }}"
{{- else -}}
image: "{{ $root.Values.image.repository }}/hcl-aipilot-{{ $container.imageName }}:{{ $root.Values.image.tag }}"
{{ end }}
{{- end }}

{{/*
Create image pull policy.
*/}}
{{- define "aipilot.imagePullPolicy" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- $pullPolicy := "" -}}
{{- if and $container $container.image -}} 
{{- $pullPolicy = default $root.Values.image.imagePullPolicy $container.image.imagePullPolicy -}} 
{{- else if $root.Values.image -}}
{{- $pullPolicy = $root.Values.image.imagePullPolicy -}}
{{- else -}}
{{- $pullPolicy = "Always" -}}
{{- end -}}
imagePullPolicy: {{ $pullPolicy }}
{{ end }}

{{- define "aipilot.microservices.list" -}}
{{- $myList := list "core" "actions" "nlg" "rag-service" "vector-db" "translator" "ui" -}}
{{ toJson $myList }}
{{- end -}}

{{/*
}}
{{- end }}

{{/*
Create the probe check for the liveness and readiness.
*/}}
{{- define "aipilot.probe" -}}
readinessProbe:
  httpGet:
    path: /ready
    port: port-{{ .port }}
    scheme: HTTPS
  initialDelaySeconds: 15
  periodSeconds: 5
  failureThreshold: 40
  timeoutSeconds: 5
livenessProbe:
  httpGet:
    path: /live
    port: port-{{ .port }}
    scheme: HTTPS
  initialDelaySeconds: 60
  periodSeconds: 10
  failureThreshold: 2
  timeoutSeconds: 5
{{- end}}

{{/*
Define the resources if found on the container values
*/}}
{{- define "aipilot.resources" -}}
{{- if .resources}}
resources:
  {{- if .resources.limits }}
  limits: {{ include "aipilot.resource.check" .resources.limits | indent 6}}
  {{- end}}
  {{- if .resources.requests }}
  requests: {{ include "aipilot.resource.check" .resources.requests | indent 6}}
  {{- end}}
{{- end }}
{{- end }}

{{- define "aipilot.resource.check" -}}
{{- if .cpu }}
cpu: {{ .cpu }}
{{- end }}
{{- if .memory}}
memory: {{ .memory }}
{{- end }}

{{- end }}

{{/*
Define the resources if found on the container values
*/}}
{{- define "aipilot.metrics" -}}
{{- if .hpa.metrics }}
  metrics:
  {{- if .hpa.metrics.cpu }}
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .hpa.metrics.cpu.targetAverageUtilization }}
  {{- end }}
  {{- if .hpa.metrics.memory }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ .hpa.metrics.memory.targetAverageUtilization }}
  {{- end }}
{{- end }}
{{- end }}


{{- define "aipilot.cert.name" -}}
{{- if .Values.certificates.certSecretName -}}
{{- tpl .Values.certificates.certSecretName . -}}
{{- else -}}
{{ $fullName := include "aipilot.fullName" . }}
{{- printf "%s-%s"  $fullName "aipilot-certificates-secret" -}}
{{- end -}}
{{- end -}}

{{- define "aipilot.cert.issuer" -}}
{{- if .Values.certificates.issuerName -}}
{{- tpl .Values.certificates.issuerName . -}}
{{- else -}}
{{ $fullName := include "aipilot.fullName" . }}
{{- printf "%s-%s"  $fullName "aipilot-ca-issuer" -}}
{{- end -}}
{{- end -}}

{{- define "aipilot.ca.secret.name" -}}
{{- if .Values.certificates.caPairSecretName -}}
{{- tpl  .Values.certificates.caPairSecretName . | quote }}
{{- else -}}
{{ $fullName := include "aipilot.fullName" . }}
{{- printf "%s-%s"  $fullName "aipilot-selfsigned-ca" -}}
{{- end -}}
{{- end -}}


{{- define "aipilot.root.ca.name" -}}
{{ $fullName := include "aipilot.fullName" . }}
{{- printf "%s-%s"  $fullName "aipilot-root-ca" -}}
{{- end -}}

{{- define "aipilot.apikey" -}}
{{- if .Values.global.cloudCredentials -}}
{{ .Values.global.cloudCredentials.gcp | b64enc | quote }}
{{- else -}}
{{ .Values.config.gcp_key | b64enc | quote }}
{{- end -}}
{{- end -}}


{{- define "postgres.password" -}}
{{ printf "%s-%s" .Release.Name  "postgres-password-secret" }}
{{- end -}}

{{/* Generate the name of the deployment */}}
{{- define "aipilot.rag.name" -}}
{{- printf "%s-%s" .Release.Name .Values.rag.app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "aipilot.pull.secret" -}}
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