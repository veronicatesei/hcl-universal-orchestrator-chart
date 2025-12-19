{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. */}}
{{- define "name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 42 | trimSuffix "-" -}}
{{- end -}}
{{/* Create a default fully qualified app name. We truncate at 63 chars because . . . */}}
{{- define "fullname" -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{- define "baseImageName" -}}
{{- printf "%s"  "hcl-uno-" -}}
{{- end -}}

{{- define "uno.repouno" -}}
{{- if eq .Values.global.hclImageRegistry "hclcr.io/sofy" -}}
hclcr.io/uno
{{- else if eq .Values.global.hclImageRegistry "hclcr.io" -}}
hclcr.io/uno
{{- else if eq .Values.global.hclImageRegistry "gcr.io/blackjack-209019" -}}
gcr.io/blackjack-209019/services/uno
{{- else if .Values.global.hclImageRegistry -}}
{{ print .Values.global.hclImageRegistry }}
{{- else -}}
{{ print .Values.config.registry.name }}
{{- end -}}
{{- end -}}


{{- define "uno.serviceAccount" -}}
{{ $fullName := include "fullname" . }}
{{- $name := default .Values.global.serviceAccountName "uno-user" -}}
{{- printf "%s-%s" $fullName  $name  -}}
{{- end -}}

{{- define "uno.common.label" -}}
uno.microservice.version: 2.1.3.0
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



{{- define "uno.agent.configuration" -}}
{{ $fullName := include "fullname" . }}
- name: IS_KUBE
  value: 'TRUE'
- name: QUARKUS_OPENTELEMETRY_TRACER_EXPORTER_OTLP_ENDPOINT
  value: {{ .Values.config.tracing.otelEndpoint |quote }}
- name: QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ .Values.config.tracing.otelEndpoint |quote }}
- name: QUARKUS_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
  value: {{ .Values.config.tracing.otelEndpoint |quote }}
{{- if .Values.config.tracing.enabled }}
- name: QUARKUS_OTEL_TRACER_SAMPLER
  value: "always_on"
- name: QUARKUS_OTEL_SDK_DISABLED
  value: "false"
{{- else }}
- name: QUARKUS_OTEL_TRACER_SAMPLER
  value: "always_off"
- name: QUARKUS_OTEL_SDK_DISABLED
  value: "true"
{{- end }}
{{- if .Values.global.debug }}
- name: UNO_DEBUG_SCRIPTS
  value: {{ .Values.global.debug | quote }}
{{- end }}
{{- if eq (.Values.global.license | toString) "accept"  }}
- name: LICENSE_ACCEPTED
  value: "true"
{{- end }}
{{- if .Values.agent.configuration.insecure }}
- name: CERTIFICATE_ACCEPTED
  value: {{ .Values.agent.configuration.insecure | quote}}
{{- end }}
{{- if .Values.agent.configuration.name }}
- name: AGENT_NAME
  value: {{ .Values.agent.configuration.name | quote}}
{{- else }}
- name: AGENT_NAME
  value: UNO_AGENT
{{- end }}
- name: API_KEY
  valueFrom:
{{- if .Values.agent.configuration.apiKeySecretName }}
    secretKeyRef:
      name: {{ .Values.agent.configuration.apiKeySecretName }}
      key: AGENT_API_KEY
      optional: false
{{- else }}
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: AGENT_API_KEY
      optional: false
{{- end }}
{{- if .Values.agent.configuration.agentManagerUrl }}
- name: AGENT_MANAGER_URL
  value: {{ .Values.agent.configuration.agentManagerUrl | quote}}
{{- else }}
- name: AGENT_MANAGER_URL
  value: https://{{ $fullName }}-agentmanager:8443
{{- end }}
{{- if .Values.agent.configuration.proxy.url }}
- name: PROXY_URL
  value: {{ .Values.agent.configuration.proxy.url | quote}}
{{- end }}
{{- if .Values.agent.configuration.proxy.username }}
- name: PROXY_USER
  value: {{ .Values.agent.configuration.proxy.username | quote}}
{{- end }}
{{- if .Values.agent.configuration.proxy.password }}
- name: PROXY_PASSWORD
  value: {{ .Values.agent.configuration.log.level | quote}}
{{- end }}
{{- if .Values.agent.configuration.log.level }}
- name: LOG_LEVEL
  value: {{ .Values.agent.configuration.log.level | quote}}
{{- end }}
{{- if .Values.agent.configuration.log.size }}
- name: LOG_SIZE
  value: {{ .Values.agent.configuration.log.size | quote}}
{{- end }}
{{- if .Values.agent.configuration.log.rotation }}
- name: LOG_ROTATION
  value: {{ .Values.agent.configuration.log.rotation | quote}}
{{- end }}
{{- if .Values.agent.configuration.traceLog.level }}
- name: TRACE_LOG_LEVEL
  value: {{ .Values.agent.configuration.traceLog.level | quote}}
{{- end }}
{{- if .Values.agent.configuration.traceLog.size }}
- name: TRACE_LOG_SIZE
  value: {{ .Values.agent.configuration.traceLog.size | quote}}
{{- end }}
{{- if .Values.agent.configuration.traceLog.rotation }}
- name: TRACE_LOG_ROTATION
  value: {{ .Values.agent.configuration.traceLog.rotation | quote}}
{{- end }}
{{- if .Values.agent.configuration.completedTaskMaxAge }}
- name: COMPLETED_TASK_MAX_AGE
  value: {{ .Values.agent.configuration.completedTaskMaxAge | quote}}
{{- end }}
{{- if .Values.agent.configuration.commonTempPath }}
- name: COMMON_TEMP_PATH
  value: {{ .Values.agent.configuration.commonTempPath | quote}}
{{- end }}
{{- if .Values.agent.configuration.localJobLogStore }}
- name: LOCAL_JOB_STORE
  value: {{ .Values.agent.configuration.localJobLogStore | quote}}
{{- end }}
{{- if .Values.global.customEnv }}
{{ toYaml .Values.global.customEnv}}
{{ end -}}
{{- end -}}

{{- define "uno.agent.volume.mounts" -}}
- name: uno-agent
  mountPath: /opt/app/dataDir/
  subPath: dataDir
{{- if ne (len .Values.persistence.extraVolumeMounts) 0 }}
{{ toYaml .Values.persistence.extraVolumeMounts }}
{{- end }}
{{- end -}}

{{- define "uno.agent.volume" -}}
{{- if ne (len .Values.persistence.extraVolumes) 0 }}
{{ toYaml .Values.persistence.extraVolumes}}
{{- end }}
{{- end -}}

{{- define "uno.agent.volume.claim.template" -}}
{{- if .Values.persistence.useDynamicProvisioning }}
# if present, use the storageClassName from the values.yaml, else use the
# default storageClass setup by kube Administrator
# setting storageClassName to nil means use the default storage class
storageClassName: {{ default nil .Values.persistence.dataPVC.storageClassName | quote }}
{{- else }}
# bind to an existing pv.
# setting storageClassName to "" disables dynamic provisioning 
storageClassName: ""
  {{- if .Values.persistence.dataPVC.selector.label }}
# use selectors in the binding process
selector:
  matchLabels:
    {{ .Values.persistence.dataPVC.selector.label }}: {{ .Values.persistence.dataPVC.selector.value }}
  {{- end }}
{{- end }}
{{- end -}}


{{- define "uno.securityContext" -}}
hostNetwork: false
hostPID: false
hostIPC: false
securityContext:
        runAsNonRoot: true
        {{- if not (.Capabilities.APIVersions.Has "security.openshift.io/v1") }} 
        runAsUser: 1001
        fsGroupChangePolicy: OnRootMismatch
        runAsGroup: 1001
        fsGroup: 1001
        {{- end }}
        supplementalGroups: [{{ .Values.supplementalGroupId | default 999 }}]
{{- end -}}