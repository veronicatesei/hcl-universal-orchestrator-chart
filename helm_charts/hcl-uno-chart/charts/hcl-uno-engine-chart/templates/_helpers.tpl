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

{{- define "common.flexUrl" -}}
{{- if .Values.hclFlexnetURL }}
{{- printf "%s"  (tpl ( .Values.hclFlexnetURL |default "") .)  -}}
{{- else if .Values.global.hclFlexnetURL }}
{{- printf "%s"  (tpl ( .Values.global.hclFlexnetURL |default "") .)  -}}
{{- else  }}
{{- printf "%s"  (tpl ( .Values.config.license.licenseServerUrl |default "") .)  -}}
{{- end -}}
{{- end -}}

{{- define "common.flexId" -}}
{{- if .Values.hclFlexnetID }}
{{- printf "%s"  (tpl ( .Values.hclFlexnetID |default "") .)  -}}
{{- else if .Values.global.hclFlexnetID }}
{{- printf "%s"  (tpl ( .Values.global.hclFlexnetID |default "") .)  -}}
{{- else  }}
{{- printf "%s"  (tpl ( .Values.config.license.licenseServerId |default "") .)  -}}
{{- end -}}
{{- end -}}

{{- define "baseImageName" -}}
{{- printf "%s"  "hcl-uno-" -}}
{{- end -}}

{{- define "uno.microservices.list" -}}
{{- $myList := list "agentmanager" "executor" "gateway" "iaa" "orchestrator" "scheduler" "toolbox" "timer" "storage" "audit" -}}
{{ toJson $myList }}
{{- end -}}

{{- define "uno.console.public.host" -}}
{{ $fullName := include "fullname" . }}
{{- printf "%s-%s"  $fullName "waconsole" -}}
{{- end -}}

{{- define "uno.console.internal.host" -}}
{{ $fullName := include "fullname" . }}
{{- printf "%s-%s"  $fullName "waconsole" -}}
{{- end -}}

{{- define "uno.console.public.port" -}}
{{ $fullName := include "fullname" . }}
{{- printf "%s"  "9443" -}}
{{- end -}}

{{- define "uno.serviceAccount" -}}
{{ $fullName := include "fullname" . }}
{{- $name := default .Values.global.serviceAccountName "uno-user" -}}
{{- printf "%s-%s" $fullName  $name  -}}
{{- end -}}

{{/*
Returns the readinessProbe
*/}}
{{- define "uno.readiness" -}}
readinessProbe:
  httpGet:
    path: /q/health/ready
    port: https
    scheme: HTTPS
  initialDelaySeconds: 15
  periodSeconds: 5
  failureThreshold: 40
  timeoutSeconds: 5
livenessProbe:
  httpGet:
    path: /q/health/live
    port: https
    scheme: HTTPS
  initialDelaySeconds: 60
  periodSeconds: 10
  failureThreshold: 2
  timeoutSeconds: 5

{{- end -}}

{{/*
Returns the securityContext
*/}}
{{- define "uno.securityContext" -}}
hostNetwork: false
hostPID: false
hostIPC: false
securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
{{- end -}}





{{- define "uno.resources" -}}
resources:
  requests:
    {{- if (((.item).resources).requests).cpu  }}
    cpu: {{ .item.resources.requests.cpu  | quote }}
    {{- else }}
    cpu: {{ .root.Values.deployment.global.resources.requests.cpu | quote}}
    {{- end }} 
    {{- if  (((.item).resources).requests).memory  }}
    memory: {{ .item.resources.requests.memory  | quote }}
    {{- else }}
    memory: {{ .root.Values.deployment.global.resources.requests.memory | quote }}
    {{- end }} 
  limits:
    {{- if  (((.item).resources).limits).cpu  }}
    cpu: {{ .item.resources.limits.cpu  | quote}}
    {{- else }}
    cpu: {{ .root.Values.deployment.global.resources.limits.cpu | quote }}
    {{- end }} 
    {{- if (((.item).resources).limits).memory  }}
    memory: {{ .item.resources.limits.memory  | quote }}
    {{- else }}
    memory:  {{ .root.Values.deployment.global.resources.limits.memory | quote}}
    {{- end }} 
{{- end -}}

{{- define "uno.resourcesM" -}}
resources:
  limits:
    cpu: '2'
    memory: 1024Mi
  requests:
    cpu: '0.3'
    memory: 512Mi
{{- end -}}


{{- define "uno.annotationKeepResource" -}}
"helm.sh/resource-policy": "keep"
{{- end -}}


{{- define "uno.prometheus.annotation" -}}
prometheus.io/scrape: "true"
prometheus.io/scheme: "https"
prometheus.io/port: "8443"
prometheus.io/path: "/q/metrics"
{{- end -}}



{{- define "uno.common.label" -}}
uno.microservice.version: 1.1.0.0
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

{{- define "uno.console.env.variable" -}}
{{ $fullName := include "fullname" . }}
{{ $consolePublicHost :=  include "uno.console.public.host" . }}
{{ $consolePublicPort :=  include "uno.console.public.port" . }}

{{- if ((.Values).global).enableConsole }}
- name: UNO_AUTHENTICATION_CONSOLE_HOSTNAME
  valueFrom:
    configMapKeyRef:
      name: {{ $fullName }}-dwc-config
      key: dwc.public.host
- name: UNO_AUTHENTICATION_CONSOLE_PORT
  valueFrom:
    configMapKeyRef:
      name: {{ $fullName }}-dwc-config
      key: dwc.public.port
{{- else }}
- name: UNO_AUTHENTICATION_CONSOLE_HOSTNAME
  value: {{ .Values.config.console.hostname | default $consolePublicHost | quote }}
- name: UNO_AUTHENTICATION_CONSOLE_PORT
  value: {{ .Values.config.console.port | default $consolePublicPort | quote}}
{{- end }}
{{- end -}}

{{- define "uno.apikey.cleanup.variable" -}}
{{- if .Values.config.apiKey.cleanupFrequencyForPending }}
- name: UNO_PENDING_APIKEYS_CLEANUP_FREQUENCY
  value: {{ .Values.config.apiKey.cleanupFrequencyForPending | quote }}
{{- else }}
- name: UNO_PENDING_APIKEYS_CLEANUP_FREQUENCY
  value: "5m"
{{- end }}
{{- if .Values.config.apiKey.cleanupTimeoutForPending }}
- name: UNO_PENDING_APIKEYS_CLEANUP_TIMEOUT
  value: {{ .Values.config.apiKey.cleanupTimeoutForPending | quote }}
{{- else }}
- name: UNO_PENDING_APIKEYS_CLEANUP_TIMEOUT
  value: "15m"
{{- end }}
{{- end }}

{{- define "uno.apikey.warning.variable" -}}
{{- if .Values.config.apiKey.lifespanWarningDays }}
- name: UNO_MICROSERVICE_APIKEY_LIFESPAN_WARNING_DAYS
  value: {{ .Values.config.apiKey.lifespanWarningDays | quote }}
{{- end }}
{{- end -}}

{{- define "uno.oidc.env.variable" -}}
{{- if .Values.authentication.oidc.connectionTimeout }}
- name: QUARKUS_OIDC_CONNECTION_TIMEOUT
  value: {{ .Values.authentication.oidc.connectionTimeout | quote }}
{{- else }}
- name: QUARKUS_OIDC_CONNECTION_TIMEOUT
  value: "PT1M"
{{- end }}
{{- if .Values.authentication.oidc.enabled }}
- name: QUARKUS_OIDC_TENANT_ENABLED
  value: "true"
- name: QUARKUS_OIDC_AUTH_SERVER_URL
  value: {{ .Values.authentication.oidc.server | quote }}
- name: QUARKUS_OIDC_CLIENT_ID
  value: {{ .Values.authentication.oidc.clientId | quote }}
- name: QUARKUS_OIDC_CREDENTIALS_SECRET
  value: {{ .Values.authentication.oidc.credentialSecret | quote }}
- name: QUARKUS_OIDC_TOKEN_STATE_MANAGER_ENCRYPTION_REQUIRED
  value: {{ .Values.authentication.oidc.encryptTokensInCookie | quote }}
- name: QUARKUS_OIDC_TOKEN_STATE_MANAGER_SPLIT_TOKENS
  value: {{ .Values.authentication.oidc.splitTokensInCookie | quote }}
- name: QUARKUS_OIDC_TLS_VERIFICATION
  value: {{ .Values.authentication.oidc.tlsVerification | quote }}
- name: QUARKUS_OIDC_APPLICATION_TYPE
  value: {{ .Values.authentication.oidc.applicationType | quote }}
{{- else }}
- name: QUARKUS_OIDC_TENANT_ENABLED
  value: "false"
- name: QUARKUS_OIDC_AUTH_SERVER_URL
  value: "https://undefined-host/realms"
{{- end }}
{{- end -}}

{{- define "uno.oidc.enabled.variable" -}}
{{- if .Values.authentication.oidc.enabled }}
- name: UNO_AUTHENTICATION_OIDC_ENABLE
  value: "true"
{{- if .Values.authentication.oidc.useToManageApiKeys }}
- name: UNO_AUTHENTICATION_ON_FAIL_USE_OIDC
  value: "true"
{{- else }}
- name: UNO_AUTHENTICATION_ON_FAIL_USE_OIDC
  value: "false"
{{- end }}
{{- else }}
- name: UNO_AUTHENTICATION_OIDC_ENABLE
  value: "false"
- name: UNO_AUTHENTICATION_ON_FAIL_USE_OIDC
  value: "false"
{{- end }}
{{- end -}}

{{- define "uno.bulkhead.env.value" -}}
{{- if .Values.bulkhead.request.maxValue }}
- name: BULKHEAD_VALUE
  value: {{ .Values.bulkhead.request.maxValue | quote }}
{{- else }}
- name: BULKHEAD_VALUE
  value: "12"
{{- end }}
{{- if .Values.bulkhead.request.waitingTaskQueue }}
- name: BULKHEAD_WAITINGTASKQUEUE
  value: {{ .Values.bulkhead.request.waitingTaskQueue | quote }}
{{- else }}
- name: BULKHEAD_WAITINGTASKQUEUE
  value: "12"
{{- end }}
{{- end -}}

{{- define "uno.authentication.api.env.variable" -}}
{{- if .Values.ingress.enabled }}
{{- if .Values.ingress.baseDomainName }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: "gateway{{ .Values.ingress.baseDomainName }}"
{{- else }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: {{ .Values.authentication.apiHostname | quote }}
{{- end }}
{{- else }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: {{ .Values.authentication.apiHostname | quote }}
{{- end }}
{{- end -}}

{{- define "common.env.variable" -}}
{{ $flexUrl := include "common.flexUrl" . }}
{{ $flexId := include "common.flexId" . }}
{{ $fullName := include "fullname" . }}
{{- if .Values.deployment.global.debug }}
- name: UNO_DEBUG_SCRIPTS
  value: {{ .Values.deployment.global.debug | quote }}
{{- end }}
- name: UNO_LICENSE_SERVER_FLEXERA_URL
  value: {{ $flexUrl | quote }} 
- name: UNO_LICENSE_SERVER_FLEXERA_ID
  value: {{ $flexId  | quote }}   
- name: LICENSE
  value: {{ .Values.global.license | quote }} 
- name: UNO_PLANNING_NOT_ACTIVE_WINDOW_MAX
  value: {{ .Values.config.planning.notActiveWindowMax | quote }} 
- name: UNO_PLANNING_NOT_ACTIVE_WINDOW_MIN
  value: {{ .Values.config.planning.notActiveWindowMin | quote }} 
- name: UNO_PLANNING_ACTIVE_WINDOW_EXTENSION
  value: {{ .Values.config.planning.activeWindowExtension | quote }} 
- name: UNO_PLANNING_ACTIVE_WINDOW_LICENSE
  value: {{ .Values.config.planning.activeWindow | quote }} 
- name: UNO_EXTERNAL_NGINX_URL
  value: http://{{ $fullName }}-extra:8080 
- name: QUARKUS_MONGODB_CONNECTION_STRING
  value: {{ (tpl ( .Values.database.url) .) | quote}}
- name: QUARKUS_MONGODB_CREDENTIAL.USERNAME
  value: {{ .Values.database.username | quote}}
- name: QUARKUS_MONGODB_CREDENTIAL.PASSWORD
  value: {{ .Values.database.password | quote}}
- name: QUARKUS_MONGODB_TLS
  value: {{ .Values.database.tls | quote}}
- name: QUARKUS_MONGODB_TLS_INSECURE
  value: {{ .Values.database.tlsInsecure | quote}}
- name: UNO_DATABASE_TYPE
  value: {{ .Values.database.type | quote }}
- name: KAFKA_BOOTSTRAP_SERVERS
  # if additional bootstrap servers are required, add a comma separated list
  value: {{ (tpl ( .Values.kafka.url) .) | quote}}
{{- if .Values.kafka.username }}
- name: KAFKA_USER
  value: {{ .Values.kafka.username | quote}}
- name: KAFKA_PASSWORD
  value: {{ .Values.kafka.password | quote}}
{{- else }}
- name: KAFKA_SASL_JAAS_CONFIG
  value: ""
- name: KAFKA_SASL_MECHANISM
  value: ""
- name: KAFKA_SECURITY_PROTOCOL
  value: "PLAINTEXT"
{{- end }}
{{- if .Values.kafka.tls }}
{{- if .Values.kafka.tlsInsecure }}
- name: KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM
  value: ""
{{- else }}
- name: KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM
  value: "https"
{{- end }}
{{- else }}
- name: MP_MESSAGING_CONNECTOR_SMALLRYE_KAFKA_SSL_TRUSTSTORE_LOCATION
  value: ""
- name: MP_MESSAGING_CONNECTOR_SMALLRYE_KAFKA_SSL_TRUSTSTORE_PASSWORD
  value: ""
- name: MP_MESSAGING_CONNECTOR_SMALLRYE_KAFKA_SSL_TRUSTSTORE_TYPE
  value: ""
{{- end }}
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
- name: UNO_TRACING_ENABLE_ALL
  value: {{ .Values.config.tracing.traceAll | quote }}
- name:  UNO_CREATE_TOPICS_ENABLE
  value: "true"
- name: UNO_CREATE_TOPICS_PARTITION
  value: {{ mul .Values.deployment.global.maxTargetReplicas 2 | quote }}
- name: QUARKUS_LOG_CATEGORY__COM_HCL__LEVEL
  value: {{ .Values.deployment.global.traceLevel | quote }}
- name: QUARKUS_LOG_LEVEL
  value: "ALL"
- name: QUARKUS_SHUTDOWN_TIMEOUT
  value: "PT20S"
- name: UNO_IAA_CLIENT_URL
  value: https://{{ $fullName }}-iaa:8443
- name: UNO_CALENDAR_CLIENT_URL
  value: https://{{ $fullName }}-toolbox:8443
- name: UNO_ORCHESTRATOR_CLIENT_URL
  value: https://{{ $fullName }}-orchestrator:8443
- name: UNO_SCHEDULER_CLIENT_URL
  value: https://{{ $fullName }}-scheduler:8443
- name: UNO_STORAGE_CLIENT_URL
  value: https://{{ $fullName }}-storage:8443
- name: UNO_VARIABLETABLE_CLIENT_URL
  value: https://{{ $fullName }}-toolbox:8443
- name: UNO_AGENTMANAGER_CLIENT_URL
  value: https://{{ $fullName }}-agentmanager:8443
- name: UNO_AUDIT_CLIENT_URL
  value: https://{{ $fullName }}-audit:8443
- name: UNO_TIMER_CLIENT_URL
  value: https://{{ $fullName }}-timer:8443
{{- end -}}

{{- define "common.custom.env.variable" -}}
{{- if .Values.global.customEnv }}
{{- range .Values.global.customEnv }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
{{ end -}}
{{- end -}}

{{- define "uno.dwcsecretname" -}}
{{- if (.Values.global.dwcconsole).certSecretName }}
{{- printf "%s"  (.Values.global.dwcconsole).certSecretName  -}}
{{- else if .Values.global.enableConsole }}
{{- printf "waconsole-cert-secret"    -}}
{{- else  }}
{{- printf ""    -}}
{{- end -}}
{{- end -}}


{{- define "uno.secret.volumes" -}}
{{ $fullName := include "fullname" . }}
{{ $jwtKeyDef :=printf "%s-%s" $fullName  "jwt-key"}}
{{ $dwcsecretname := include "uno.dwcsecretname" . }}
volumes:
  - name: emptydir
    emptyDir: {}
  - name: plugindir
    emptyDir: {}
  - name: cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ .Values.config.certificates.certSecretName | quote }}
  - name: jwt-volume
    secret:
      defaultMode: 0664
      secretName: {{ .Values.config.jwt.jwtSecretName  | default $jwtKeyDef  | quote }}
{{- if $dwcsecretname }}
  - name: jwt-dwc-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ $dwcsecretname  | quote }}
{{- end }}
  - name: ext-agent-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ .Values.config.certificates.certExtAgtSecretName | quote }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{.}}-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ .| quote }}
      items:
      - key: tls.crt
        path: {{.}}.crt
{{- end }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{.}}-cert-ext-volume
    secret:
      defaultMode: 0664
      secretName: {{ .| quote }}
      items:
      - key: tls.crt
        path: {{.}}.crt
{{- end }}  
{{- end -}}

{{- define "uno.secret.volumes.mounts" -}}
{{ $fullName := include "fullname" . }}
{{ $dwcsecretname := include "uno.dwcsecretname" . }}

volumeMounts: 
  - name: cert-volume
    mountPath: /security/certs
  - name: jwt-volume
    mountPath: /security/jwt
  - name: ext-agent-cert-volume
    mountPath: /security/ext_agt_depot
{{- if $dwcsecretname }}
  - name: jwt-dwc-cert-volume
    mountPath: /security/dwc-certs
{{- end }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{.}}-cert-volume
    mountPath: /security/certs/additionalCAs
{{- end }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{.}}-cert-ext-volume
    mountPath: /security/ext_agt_depot/additionalCAs
{{- end }}    
{{- end -}}


{{- define "uno.cert.issuer" -}}
{{ $fullName := include "fullname" . }}
{{- printf "%s-%s"  $fullName "uno-issuer" -}}

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


{{- define "uno.pluginImageRepository" -}}
{{- if eq .Values.global.hclImageRegistry "hclcr.io/sofy" -}}
hclcr.io/wa
{{- else if eq .Values.global.hclImageRegistry "hclcr.io" -}}
hclcr.io/wa
{{- else if eq .Values.global.hclImageRegistry "gcr.io/blackjack-209019" -}}
gcr.io/blackjack-209019/services
{{- else if  .Values.global.hclImageRegistry  -}}
{{ print .Values.global.hclImageRegistry }}
{{- else -}}
{{ print .Values.global.pluginImageRepository }}
{{- end -}}
{{- end -}}


{{- define "uno.extraImageRepository" -}}
{{- if eq .Values.global.hclImageRegistry "hclcr.io/sofy" -}}
hclcr.io/wa
{{- else if eq .Values.global.hclImageRegistry "hclcr.io" -}}
hclcr.io/wa
{{- else if eq .Values.global.hclImageRegistry "gcr.io/blackjack-209019" -}}
gcr.io/blackjack-209019/services
{{- else if  .Values.global.hclImageRegistry  -}}
{{ print .Values.global.hclImageRegistry }}
{{- else -}}
{{ print .Values.global.extraImageRepository }}
{{- end -}}
{{- end -}}