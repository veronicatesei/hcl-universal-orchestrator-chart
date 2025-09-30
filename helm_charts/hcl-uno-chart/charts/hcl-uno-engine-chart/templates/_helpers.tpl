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

{{- define "common.mhsUrl" -}}
{{- if .Values.licenseServerUrl }}
{{- printf "%s"  (tpl ( .Values.licenseServerUrl |default "") .)  -}}
{{- else if .Values.global.licenseServerUrl }}
{{- printf "%s"  (tpl ( .Values.global.licenseServerUrl |default "") .)  -}}
{{- else  }}
{{- printf "%s"  (tpl ( .Values.config.license.licenseServerUrl |default "") .)  -}}
{{- end -}}
{{- end -}}

{{- define "common.mhsKey" -}}
{{- if .Values.licenseServerKey }}
{{- printf "%s"  (tpl ( .Values.licenseServerKey |default "") .)  -}}
{{- else if .Values.global.licenseServerKey }}
{{- printf "%s"  (tpl ( .Values.global.licenseServerKey |default "") .)  -}}
{{- else  }}
{{- printf "%s"  (tpl ( .Values.config.license.licenseServerKey |default "") .)  -}}
{{- end -}}
{{- end -}}

{{- define "baseImageName" -}}
{{- printf "%s"  "hcl-uno-" -}}
{{- end -}}

{{- define "uno.microservices.list" -}}
{{- $myList := list ""  -}}

{{- if eq .Values.global.deploymentType  "full" }}
{{- $myList =  concat $myList (list "console" "agentmanager" "executor" "gateway" "eventmanager" "iaa" "orchestrator" "scheduler" "toolbox" "timer" "storage" "audit" "notification") -}}
{{- else if eq .Values.global.deploymentType  "aio" -}}
{{- $myList =  append $myList "console-aio"  -}}
{{- end -}}

{{- if .Values.global.enableUnoAIPilot }}
{{- $myList =  append $myList "pilot-notification" -}}
{{- end -}}

{{- if .Values.config.multitenant.enabled }}
{{- $myList =  append $myList "saas-controller" -}}
{{- end -}}

{{- if and .Values.config.genai.enabled .Values.config.genai.internal }}
{{- $myList =  append $myList "genai" -}}
{{- end -}}

{{ $myList = uniq $myList }}
{{ $myList = compact $myList }}
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

{{- define "uno.console.sofy.port" -}}
{{- printf "%s"  "443" -}}
{{- end -}}

{{- define "uno.serviceAccount" -}}
{{ $fullName := include "fullname" . }}
{{- $name := default .Values.global.serviceAccountName "uno-user" -}}
{{- printf "%s-%s" $fullName  $name  -}}
{{- end -}}

{{- define "common.baseDomainName" -}}
{{- if .Values.global.sofySolutionContext }}
{{- printf ".$(SOFY_HOSTNAME)" -}}
{{- else }}
{{- printf "%s" .Values.ingress.baseDomainName -}}
{{- end -}}
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


{{- define "uno.containerSecurityContext" -}}
securityContext:
  runAsNonRoot: true
  seccompProfile: 
    type: RuntimeDefault
  privileged: false
  readOnlyRootFilesystem: false
  allowPrivilegeEscalation: false     
  capabilities:
    drop:
    - ALL 
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
        {{- if not (.Capabilities.APIVersions.Has "security.openshift.io/v1") }} 
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
        {{- end }}
        supplementalGroups: [{{ .Values.supplementalGroupId | default 999 }}]
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
uno.microservice.version: 2.1.3.0-beta1
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


{{- define "uno.saas-controller.env" -}}
{{ $fullName := include "fullname" . }}
# uno.controller.tenant.db.prefix
- name: UNO_CONTROLLER_TENANT_DB_PREFIX
  value: {{ .Values.config.multitenant.tenantDbPrefix | quote }}
# uno.controller.tenant.trial.defaultExpiration
- name: UNO_CONTROLLER_TENANT_TRIAL_DEFAULTEXPIRATION
  value: {{ .Values.config.multitenant.trial.defaultExpiration | quote }}
# uno.controller.tenant.trial.cleanup.delay
- name: UNO_CONTROLLER_TENANT_TRIAL_CLEANUP_DELAY
  value: {{ .Values.config.multitenant.trial.cleanupDelay | quote }}
# uno.controller.tenant.subscribed.cleanup.delay
- name: UNO_CONTROLLER_TENANT_SUBSCRIBED_CLEANUP_DELAY
  value: {{ .Values.config.multitenant.subscribed.cleanupDelay | quote }}
# uno.controller.tenant.expirationCheck.interval
- name: UNO_CONTROLLER_TENANT_EXPIRATIONCHECK_INTERVAL
  value: {{ .Values.config.multitenant.expirationCheckInterval | quote }}
# uno.controller.region
- name: UNO_CONTROLLER_REGION
  value: {{ .Values.config.multitenant.region | quote }}
# uno.controller.authorization.userIds
- name: UNO_CONTROLLER_AUTHORIZATION_USERIDS
  value: {{ .Values.config.multitenant.admins.userIds | join "," | quote }}
# uno.controller.authorization.groupIds
- name: UNO_CONTROLLER_AUTHORIZATION_GROUPIDS
  value: {{ .Values.config.multitenant.admins.groupIds | join "," | quote }}
# uno.controller.authorization.userIdFilters
- name: UNO_CONTROLLER_AUTHORIZATION_USERIDFILTERS
  value: {{ .Values.config.multitenant.admins.userIdFilters | join "," | quote }}
# uno.controller.domain
- name: UNO_CONTROLLER_DOMAIN
  value: {{ .Values.ingress.baseDomainName | quote }}
# uno.controller.domain.hyphenated
- name: UNO_CONTROLLER_DOMAIN_HYPHENATED
  value: {{ .Values.ingress.baseDomainName | replace "." "-" | quote }}
# uno.controller.audit.max.retention.duration
- name: UNO_CONTROLLER_AUDIT_MAX_RETENTION_DURATION
  value: {{ .Values.config.controller.auditMaxRetentionDuration | quote }}
# uno.controller.audit.cleanup.frequency
- name: UNO_CONTROLLER_AUDIT_CLEANUP_FREQUENCY
  value: {{ .Values.config.controller.auditCleanupFrequency | quote }}

{{- if .Values.config.multitenant.marketplace.HCLSoftware.enabled }}
# HCL Software Marketplace integration

# uno.controller.marketplace.enabled
- name: UNO_CONTROLLER_MARKETPLACE_ENABLED
  value: "true"
# uno.controller.marketplace.regions
- name: UNO_CONTROLLER_MARKETPLACE_REGIONS
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.regions | join "," | quote }}
# uno.controller.marketplace.planIds
- name: UNO_CONTROLLER_MARKETPLACE_PLANIDS
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.planIds | join "," | quote }}
# uno.controller.marketplace.kafka.bootstrap.servers
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_BOOTSTRAP_SERVERS
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.kafka.url | quote }}
# uno.controller.marketplace.kafka.topic
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_TOPIC
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.kafka.topic | quote }}
# uno.controller.marketplace.kafka.user
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_USER
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.kafka.username | quote }}
# uno.controller.marketplace.kafka.password
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: MARKETPLACE_KAFKA_PASSWORD
      optional: false
# uno.controller.marketplace.kafka.schema.registry.url
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_SCHEMA_REGISTRY_URL
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.schemaRegistry.url | quote }}
# uno.controller.marketplace.kafka.schema.registry.user
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_SCHEMA_REGISTRY_USER
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.schemaRegistry.username | quote }}
# mp.messaging.incoming.marketplace-incoming.value-deserialization-failure-handler=marketplace-failure-handler
- name: MP_MESSAGING_INCOMING_MARKETPLACE_INCOMING_VALUE_DESERIALIZATION_FAILURE_HANDLER
  value: "marketplace-failure-handler"
# uno.controller.marketplace.kafka.schema.registry.password
- name: UNO_CONTROLLER_MARKETPLACE_KAFKA_SCHEMA_REGISTRY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: MARKETPLACE_KAFKA_REGISTRY_PASSWORD
      optional: false
#uno.controller.marketplace.tokenizer.url
- name: UNO_CONTROLLER_MARKETPLACE_TOKENIZER_URL
  value: {{ .Values.config.multitenant.marketplace.HCLSoftware.tokenizer.url | quote }}
#uno.controller.marketplace.tokenizer.auth.token
- name: UNO_CONTROLLER_MARKETPLACE_TOKENIZER_AUTH_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: MARKETPLACE_TOKENIZER_AUTH_TOKEN
      optional: false
# End of HCL Software Marketplace integration

{{- end -}}
{{- end -}}


{{- define "uno.console.env.variable" -}}
{{ $fullName := include "fullname" . }}
{{ $consolePublicHost :=  include "uno.console.public.host" . }}
{{ $consolePublicPort :=  include "uno.console.public.port" . }}
{{ $consoleSofyPort :=  include "uno.console.sofy.port" . }}

{{- if ((.Values).global).sofySolutionContext }}
- name: HOSTNAME_DOMAIN
  valueFrom:
    configMapKeyRef:
      name: {{ $fullName }}-domain
      key: HOST
- name: UNO_AUTHENTICATION_CONSOLE_HOSTNAME
  value: "waconsole.$(HOSTNAME_DOMAIN)"
- name: UNO_AUTHENTICATION_CONSOLE_PORT
  value: {{ $consoleSofyPort | quote }}
{{- else if ((.Values).global).enableConsole }}
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

{{- define "uno.sofy.env.variables" -}}
{{- if .Values.global.sofySolutionContext }}
- name: SOFY_HOSTNAME
  valueFrom:
    configMapKeyRef:
      name: {{ .Release.Name }}-domain
      key: HOST
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
{{- if or .Values.authentication.oidc.enabled .Values.global.sofySolutionContext}}
- name: QUARKUS_OIDC_TENANT_ENABLED
  value: "true"
{{- if (.Values.global.sofySolutionContext) }}
- name: QUARKUS_OIDC_AUTH_SERVER_URL
  value: https://sofy-kc.$(SOFY_HOSTNAME)/auth/realms/sofySolution
{{- else }}
- name: QUARKUS_OIDC_AUTH_SERVER_URL
  value: {{ tpl .Values.authentication.oidc.server . | quote }}
{{- end }}
- name: QUARKUS_OIDC_CLIENT_ID
  value: {{ .Values.authentication.oidc.clientId | quote }}
{{- if (.Values.global.sofySolutionContext) }}
- name: QUARKUS_OIDC_CREDENTIALS_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ printf "%s-%s-%s" .Release.Name "client" "secret" }}
      key: client-secret
      optional: true
{{- else }}
- name: QUARKUS_OIDC_CREDENTIALS_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: OIDC_SECRET
      optional: true
{{- end }}
- name: QUARKUS_OIDC_TOKEN_STATE_MANAGER_ENCRYPTION_REQUIRED
  value: {{ .Values.authentication.oidc.encryptTokensInCookie | quote }}
- name: QUARKUS_OIDC_TOKEN_STATE_MANAGER_SPLIT_TOKENS
  value: {{ .Values.authentication.oidc.splitTokensInCookie | quote }}
- name: QUARKUS_OIDC_TLS_VERIFICATION
  value: {{ .Values.authentication.oidc.tlsVerification | quote }}
{{- else }}
- name: QUARKUS_OIDC_TENANT_ENABLED
  value: "false"
- name: QUARKUS_OIDC_AUTH_SERVER_URL
  value: "https://undefined-host/realms"
{{- end }}
{{- end -}}

{{- define "uno.oidc.enabled.variable" -}}
{{- if or .Values.authentication.oidc.enabled .Values.global.sofySolutionContext}}
- name: UNO_AUTHENTICATION_OIDC_ENABLE
  value: "true"
{{- if .Values.authentication.oidc.groupClaimPath }}
- name: QUARKUS_OIDC_ROLES_ROLE_CLAIM_PATH
  value: {{ .Values.authentication.oidc.groupClaimPath | quote }}
{{- end }}
{{- if .Values.authentication.oidc.principalClaim }}
- name: QUARKUS_OIDC_TOKEN_PRINCIPAL_CLAIM
  value: {{ .Values.authentication.oidc.principalClaim | quote }}
{{- end }}
{{- if .Values.authentication.oidc.authenticationScope }}
- name: QUARKUS_OIDC_AUTHENTICATION_SCOPES
  value: {{ .Values.authentication.oidc.authenticationScope | quote }}
{{- end }}
{{- if .Values.authentication.oidc.jwtGroupClaimPath }}
- name: SMALLRYE_JWT_PATH_GROUPS
  value: {{ .Values.authentication.oidc.jwtGroupClaimPath | quote }}
{{- end }}
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
{{- if .Values.config.multitenant.enabled }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: "{0}.gateway{{ include "common.baseDomainName" . }}"
  {{- else }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: "gateway{{ include "common.baseDomainName" . }}"
  {{- end }}
{{- else }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: {{ .Values.authentication.apiHostname | quote }}
{{- end }}
{{- else }}
- name: UNO_AUTHENTICATION_API_HOSTNAME
  value: {{ .Values.authentication.apiHostname | quote }}
{{- end }}
{{- end -}}

{{- define "uno.extra.packages.url" -}}
  {{- $size := len .Values.global.extraImages -}}
  {{ $fullName := include "fullname" . }}
  {{- range $index, $_ := .Values.global.extraImages -}}
    {{- printf "http://%s-extra-%d:8080" $fullName $index -}}
    {{ if ne $index (sub $size 1) }},{{- end -}}
  {{- end }}
{{- end -}}

{{- define "common.env.variable" -}}
{{ $mhsUrl := include "common.mhsUrl" . }}
{{ $mhsKey := include "common.mhsKey" . }}
{{ $fullName := include "fullname" . }}
{{- if .Values.deployment.global.debug }}
- name: UNO_DEBUG_SCRIPTS
  value: {{ .Values.deployment.global.debug | quote }}
{{- end }}
{{- if .Values.config.multitenant.enabled }}
- name: QUARKUS_PROFILE
  value: saas
- name: UNO_MULTI_TENANT_HOSTNAME_PATTERN
  value: {{ .Values.config.multitenant.hostnamePattern | quote }}
- name: UNO_SAAS_CONTROLLER_CLIENT_URL
  value: "https://{{ $fullName }}-saas-controller:8443"
{{- end }}
- name: UNO_LICENSE_SERVER_MHS_URL
  value: {{ $mhsUrl | quote }}
- name: UNO_LICENSE_SERVER_MHS_KEY
  value: {{ $mhsKey  | quote }}
- name: UNO_LICENSE_PROXY_HOSTNAME
  value: {{ .Values.config.license.proxy.hostname | quote }}
- name: UNO_LICENSE_PROXY_PORT
  value: {{ .Values.config.license.proxy.port | quote }}
- name: UNO_LICENSE_PROXY_USER
  value: {{ .Values.config.license.proxy.username | quote }}
- name: UNO_LICENSE_PROXY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: LICENSE_PROXY_PASSWORD
      optional: true
- name: LICENSE
  value: {{ .Values.global.license | quote }} 
- name: UNO_PLANNING_NOT_ACTIVE_WINDOW_MAX
  value: {{ .Values.config.planning.notActiveWindowMax | quote }} 
- name: UNO_PLANNING_NOT_ACTIVE_WINDOW_MIN
  value: {{ .Values.config.planning.notActiveWindowMin | quote }} 
- name: UNO_PLANNING_CLEANUP_RETENTION_DURATION
  value: {{ .Values.config.planning.daysRetentionPlan | quote }} 
- name: UNO_PLANNING_CLEANUP_FAILED_JOBS_RETENTION_DURATION
  value: {{ .Values.config.planning.daysRetentionFailPlan | quote }} 
- name: UNO_PLANNING_CLEANUP_FAILED_JOBS_FREQUENCY
  value: {{ .Values.config.planning.frequencyFailJobCleanUp | quote }} 
- name: UNO_PLANNING_ACTIVE_WINDOW_EXTENSION
  value: {{ .Values.config.planning.activeWindowExtension | quote }} 
- name: UNO_PLANNING_ACTIVE_WINDOW_LICENSE
  value: {{ .Values.config.planning.activeWindow | quote }}
{{- if .Values.config.orchestrator.maxNestingLevel}}
- name: UNO_MAX_NESTING_LEVEL
  value: {{ .Values.config.orchestrator.maxNestingLevel | quote }}
{{- end }}
{{- if .Values.config.orchestrator.humanTaskCancelWindowSeconds }}
- name: UNO_HUMAN_TASK_CANCEL_TIMEOUT_SECONDS
  value: {{ .Values.config.orchestrator.humanTaskCancelWindowSeconds | quote }}
{{- end }}
{{- if .Values.config.orchestrator.humanTaskMailTaskCreatedTemplate }}
- name: UNO_HUMAN_TASK_MAIL_TEMPLATE_CREATED
  value: {{ .Values.config.orchestrator.humanTaskMailTaskCreatedTemplate | quote }}
{{- end }}
{{- if .Values.config.orchestrator.humanTaskMailTaskAssignedTemplate }}
- name: UNO_HUMAN_TASK_MAIL_TEMPLATE_ASSIGNED
  value: {{ .Values.config.orchestrator.humanTaskMailTaskAssignedTemplate | quote}}
{{- end }}
{{- if .Values.global.sofySolutionContext}}
- name: UNO_GENAI_CLIENT_ENABLED
  value: {{ .Values.config.genai.enabled | quote }}
{{ else }}
- name: UNO_GENAI_CLIENT_ENABLED
  value: {{ .Values.config.genai.enabled | quote }}
{{- end }}
{{- if and .Values.config.genai.enabled .Values.config.genai.internal }}
- name: UNO_GENAI_INTERNAL
  value: {{ .Values.config.genai.internal | quote }}
- name: UNO_GENAI_CLIENT_URL
  value: https://{{ $fullName }}-genai:8443
{{- else }}
- name: UNO_GENAI_CLIENT_URL
  value: {{ .Values.config.genai.serviceUrl | quote }}
{{- end }}
- name: UNO_GENAI_CLIENT_PROXY_HOSTNAME
  value: {{ .Values.config.genai.proxy.hostname | quote }}
- name: UNO_GENAI_CLIENT_PROXY_PORT
  value: {{ .Values.config.genai.proxy.port | quote }}
- name: UNO_GENAI_CLIENT_PROXY_USERNAME
  value: {{ .Values.config.genai.proxy.username | quote }}
- name: UNO_GENAI_CLIENT_PROXY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: GENAI_PROXY_PASSWORD
      optional: true
- name: UNO_GENAI_LICENSE_CUSTOM_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: GENAI_API_KEY
      optional: true
{{- if .Values.config.endpoint.console }}
- name: UNO_CONSOLE_ENDPOINT
  value: {{ .Values.config.endpoint.console | quote }}
{{- else }}
- name: UNO_CONSOLE_ENDPOINT
  value: {{ printf "https://%s.%s" .Values.deployment.console.ingressPrefix (trimPrefix "." .Values.ingress.baseDomainName) | quote }}
{{- end }}
{{- if .Values.ingress.enabled }}
{{- if .Values.config.multitenant.enabled }}
- name: UNO_AGENTMANAGER_URL
  value: {{ printf "https://%s.%s.%s"  "{0}" .Values.deployment.agentmanager.ingressPrefix (trimPrefix "." .Values.ingress.baseDomainName) | quote }}
{{- else }}
- name: UNO_AGENTMANAGER_URL
  value: {{ printf "https://%s.%s" .Values.deployment.agentmanager.ingressPrefix (trimPrefix "." .Values.ingress.baseDomainName) | quote }}
{{- end }}
{{- end }}

{{- if .Values.config.endpoint.gateway }}
- name: UNO_GATEWAY_ENDPOINT
  value: {{ .Values.config.endpoint.gateway | quote }}
{{- else }}
- name: UNO_GATEWAY_ENDPOINT
  value: {{ printf "https://%s.%s" .Values.deployment.gateway.ingressPrefix (trimPrefix "." .Values.ingress.baseDomainName) | quote }}
{{- end }}
{{- if eq .Values.global.deploymentType  "aio" }}
- name: UNO_GATEWAY_PRIVATE_ENDPOINT
  value: {{ printf "https://%s-console-aio:8443" $fullName | quote }}
{{- else }}
- name: UNO_GATEWAY_PRIVATE_ENDPOINT
  value: {{ printf "https://%s-gateway:8443" $fullName | quote }}
{{- end }}

- name: UNO_MAIL_ENABLED
  value: {{ .Values.config.mail.enabled | quote }}
- name: UNO_MAIL_SMTP_HOST
  value: {{ .Values.config.mail.smtp.host | quote }}
- name: UNO_MAIL_SMTP_PORT
  value: {{ .Values.config.mail.smtp.port | quote }}
- name: UNO_MAIL_SMTP_STARTTLS_ENABLED
  value: {{ .Values.config.mail.smtp.startTlsEnabled | quote }}
- name: UNO_MAIL_SMTP_SSL_CHECKSERVERIDENTITY
  value: {{ .Values.config.mail.smtp.sslCheckServerIdentity | quote }}
- name: UNO_MAIL_SMTP_SSL_TRUST
  value: {{ .Values.config.mail.smtp.sslTrust | quote }}
- name: UNO_MAIL_SMTP_CONNECTION_TIMEOUT
  value: {{ .Values.config.mail.smtp.connectionTimeoutMs | quote }}
- name: UNO_MAIL_FROM
  value: {{ .Values.config.mail.from | quote }}
- name: UNO_MAIL_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.mail.credentialsSecretName }}
      key: USERNAME
      optional: true
- name: UNO_MAIL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.mail.credentialsSecretName }}
      key: PASSWORD
      optional: true
- name: ENGINE_JUSTIFICATION_ENABLED
  value: {{ .Values.config.engine.justificationEnabled | quote }}
- name: ENGINE_JUSTIFICATION_CATEGORY_REQUIRED
  value: {{ .Values.config.engine.justificationCategoryRequired | quote }}
- name: ENGINE_JUSTIFICATION_TICKET_NUMBER_REQUIRED
  value: {{ .Values.config.engine.justificationTicketNumberRequired | quote }}
- name: ENGINE_JUSTIFICATION_DESCRIPTION_REQUIRED
  value: {{ .Values.config.engine.justificationDescriptionRequired | quote }}
- name: UNO_EXTERNAL_NGINX_URL
  value: {{ include "uno.extra.packages.url" . }}
- name: QUARKUS_MONGODB_CONNECTION_STRING
  value: {{ (tpl ( .Values.database.url) .) | quote}}
- name: QUARKUS_MONGODB_CREDENTIALS_USERNAME
  value: {{ .Values.database.username | quote}}
- name: QUARKUS_MONGODB_CREDENTIALS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: DB_PASSWORD
      optional: false
- name: QUARKUS_MONGODB_TLS
  value: {{ .Values.database.tls | quote}}
- name: QUARKUS_MONGODB_TLS_INSECURE
  value: {{ .Values.database.tlsInsecure | quote}}
- name: UNO_DATABASE_TYPE
  value: {{ .Values.database.type | quote }}
- name: KAFKA_BOOTSTRAP_SERVERS
  # if additional bootstrap servers are required, add a comma separated list
  value: {{ (tpl ( .Values.kafka.url) .) | quote}}
{{- if .Values.kafka.kerberosServiceName }}
- name: KAFKA_SASL_KERBEROS_SERVICE_NAME
  value: {{ .Values.kafka.kerberosServiceName | quote}}
{{- end }}
{{- if .Values.kafka.oauthLoginCallbackHandlerClass }}
- name: KAFKA_SASL_LOGIN_CALLBACK_HANDLER_CLASS
  value: {{ .Values.kafka.oauthLoginCallbackHandlerClass | quote}}
{{- end }}
{{- if .Values.kafka.oauthTokenEndpointUrl }}
- name: KAFKA_SASL_OAUTHBEARER_TOKEN_ENDPOINT_URL
  value: {{ .Values.kafka.oauthTokenEndpointUrl | quote}}
{{- end }}
{{- if .Values.kafka.prefix }}
- name: KAFKA_DEPLOYMENT_PREFIX
  value: {{ .Values.kafka.prefix | quote}}
{{- end }}
{{- if .Values.kafka.username }}
- name: KAFKA_USER
  value: {{ .Values.kafka.username | quote}}
- name: KAFKA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-uno-secret
      key: KAFKA_PASSWORD
      optional: false
{{- end }}
{{- if .Values.kafka.tls }}
{{- if .Values.kafka.tlsInsecure }}
- name: KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM
  value: ""
{{- else }}
- name: KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM
  value: "https"
{{- end }}
- name: KAFKA_SASL_MECHANISM
  value: {{ .Values.kafka.saslMechanism | default "PLAIN"| quote}}
- name: KAFKA_SECURITY_PROTOCOL
  value: {{ .Values.kafka.securityProtocol |default "SASL_SSL" | quote}}
{{- if .Values.kafka.jaasConfig }}
- name: KAFKA_SASL_JAAS_CONFIG
  value: {{ .Values.kafka.jaasConfig | quote}}
{{- end }}
{{- else }}
- name: MP_MESSAGING_CONNECTOR_SMALLRYE_KAFKA_SSL_TRUSTSTORE_LOCATION
  value: ""
- name: MP_MESSAGING_CONNECTOR_SMALLRYE_KAFKA_SSL_TRUSTSTORE_PASSWORD
  value: ""
- name: MP_MESSAGING_CONNECTOR_SMALLRYE_KAFKA_SSL_TRUSTSTORE_TYPE
  value: ""
- name: KAFKA_SASL_JAAS_CONFIG
  value: {{ .Values.kafka.jaasConfig | quote }}
- name: KAFKA_SASL_MECHANISM
  value: {{ .Values.kafka.saslMechanism | quote}}
- name: KAFKA_SECURITY_PROTOCOL
  value: {{ .Values.kafka.securityProtocol |default "PLAINTEXT" | quote}}
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
- name: UNO_CREATE_TOPICS_REPLICA
  value: {{ .Values.kafka.topicReplicas | quote }}
- name: QUARKUS_LOG_CATEGORY__COM_HCL__LEVEL
  value: {{ .Values.deployment.global.traceLevel | quote }}
- name: QUARKUS_LOG_LEVEL
  value: {{ .Values.deployment.global.quarkusTraceLevel |default "INFO" | quote }}
- name: QUARKUS_SHUTDOWN_TIMEOUT
  value: "PT20S"
- name: UNO_SECURITY_ENABLE_EXECUTOR_SANDBOX
  value: {{ .Values.deployment.executor.enableExecutorSandbox | quote}}
- name: UNO_IAA_ADMIN_USERNAME
  value: {{ .Values.authentication.adminName | quote}}
- name: UNO_DISABLE_HOSTNAMEVERIFY
  value: {{ .Values.config.certificates.disableHostnameVerification | quote}}
{{- if eq .Values.global.deploymentType  "aio" }}
- name: UNO_IAA_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_CALENDAR_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_ORCHESTRATOR_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_SCHEDULER_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_STORAGE_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_VARIABLETABLE_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_AGENTMANAGER_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_AUDIT_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_TIMER_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_EVENTMANAGER_CLIENT_URL
  value: "https://localhost:8443"
- name: UNO_NOTIFICATION_CLIENT_URL
  value: "https://localhost:8443"
{{- else }}
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
- name: UNO_EVENTMANAGER_CLIENT_URL
  value: https://{{ $fullName }}-eventmanager:8443
- name: UNO_NOTIFICATION_CLIENT_URL
  value: https://{{ $fullName }}-notification:8443
{{- end }}
- name: CONSOLE_LOGOUT_ENABLED
  value: {{ .Values.config.console.enableLogout | default "false" | quote}}
- name: CONSOLE_SESSION_TIMEOUT_MINUTES
  value: {{ .Values.config.console.sessionTimeoutMinutes | default "30" | quote}}
- name: UNO_AES_ENCRYPTION_PASSKEY
  valueFrom:
      secretKeyRef:
        name: {{ .Release.Name }}-uno-secret
        key: ENCRYPTION_KEY
        optional: false
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

{{- define "uno.dwcissuer" -}}
{{- if (.Values.global.dwcconsole).dwcissuer }}
{{- printf "%s"  (.Values.global.dwcconsole).dwcissuer  -}}
{{- else if .Values.global.enableConsole }}
{{- printf "%s%s%s" "https://" .Release.Name "-waconsole-h:9443"    -}}
{{- else  }}
{{- printf "%s%s%s" "https://" .Release.Name "-waconsole-h:9443"    -}}
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
{{- if and .Values.global.enableAgenticAIBuilder .Values.agenticAIBuilder.common.apisix.certificateSecret }}
  - name: {{ tpl .Values.agenticAIBuilder.common.apisix.certificateSecret . }}-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ tpl .Values.agenticAIBuilder.common.apisix.certificateSecret . | quote }}
      items:
      - key: tls.crt
        path: {{ tpl .Values.agenticAIBuilder.common.apisix.certificateSecret . }}.crt
{{- end }}
{{- if and .Values.global.enableAgenticAIBuilder .Values.agenticAIBuilder.certificates.certSecretName }}
  - name: {{ tpl .Values.agenticAIBuilder.certificates.certSecretName . }}-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ tpl .Values.agenticAIBuilder.certificates.certSecretName . | quote }}
      items:
      - key: tls.crt
        path: {{ tpl .Values.agenticAIBuilder.certificates.certSecretName . }}.crt
{{- end }}
  - name: ext-agent-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ .Values.config.certificates.certExtAgtSecretName | quote }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{ tpl . $}}-cert-volume
    secret:
      defaultMode: 0664
      secretName: {{ tpl . $ | quote }}
      items:
      - key: tls.crt
        path: {{ tpl . $}}.crt
{{- end }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{ tpl . $}}-cert-ext-volume
    secret:
      defaultMode: 0664
      secretName: {{ tpl . $ | quote }}
      items:
      - key: tls.crt
        path: {{ tpl . $}}.crt
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
  - name: {{ tpl . $}}-cert-volume
    mountPath: /security/certs/additionalCAs/{{ tpl . $}}
{{- end }}
{{- range .Values.config.certificates.additionalCASecrets }}
  - name: {{ tpl . $}}-cert-ext-volume
    mountPath: /security/ext_agt_depot/additionalCAs/{{ tpl . $}}
{{- end }}
{{- if and .Values.global.enableAgenticAIBuilder .Values.agenticAIBuilder.common.apisix.certificateSecret }}
  - name: {{ tpl .Values.agenticAIBuilder.common.apisix.certificateSecret . }}-cert-volume
    mountPath: /security/certs/additionalCAs/{{ tpl .Values.agenticAIBuilder.common.apisix.certificateSecret . }}
{{- end }}
{{- if and .Values.global.enableAgenticAIBuilder .Values.agenticAIBuilder.certificates.certSecretName }}
  - name: {{ tpl .Values.agenticAIBuilder.certificates.certSecretName . }}-cert-volume
    mountPath: /security/certs/additionalCAs/{{ tpl .Values.agenticAIBuilder.certificates.certSecretName . }}
{{- end }}
{{- end -}}


{{- define "uno.cert.issuer" -}}
{{- if .Values.config.certificates.customIssuer -}}
{{- print .Values.config.certificates.customIssuer -}}
{{- else -}}
{{ $fullName := include "fullname" . }}
{{- printf "%s-%s"  $fullName "uno-issuer" -}}
{{- end -}}
{{- end -}}

{{- define "uno.cert.ingressIssuer" -}}
{{- if .Values.config.certificates.customIngressIssuer -}}
{{- print .Values.config.certificates.customIngressIssuer -}}
{{- else -}}
{{ include "uno.cert.issuer" . }}
{{- end -}}
{{- end -}}

{{- define "uno.cert.ingressControllerIssuer" -}}
{{- if .Values.config.multitenant.controllerIngressCertIssuer -}}
{{- print .Values.config.multitenant.controllerIngressCertIssuer -}}
{{- else -}}
{{ include "uno.cert.ingressIssuer" . }}
{{- end -}}
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

{{- define "uno.extraImages" -}}
  {{- $root := . -}}
  {{- $imagesList := list -}}
  {{- range $_, $images := $root.Values.global.extraImages -}}
    {{- $imagesRepository := "" -}}
    {{- if eq $root.Values.global.hclImageRegistry "hclcr.io/sofy" -}}
        {{- if contains "/uno" $images.registry -}}
          {{ $imagesRepository = "hclcr.io/uno" }}
        {{- else -}}
          {{ $imagesRepository = "hclcr.io/wa" }}
        {{- end -}}
    {{- else if eq $root.Values.global.hclImageRegistry "hclcr.io" -}}
        {{- if contains "/uno" $images.registry -}}
          {{ $imagesRepository = "hclcr.io/uno" }}
        {{- else -}}
          {{ $imagesRepository = "hclcr.io/wa" }}
        {{- end -}}
    {{- else if eq $root.Values.global.hclImageRegistry "gcr.io/blackjack-209019" -}}
        {{- if contains "/uno" $images.registry -}}
            {{ $imagesRepository = "gcr.io/blackjack-209019/services/uno"}}
        {{- else if contains "/wa" $images.registry -}}
            {{ $imagesRepository = "gcr.io/blackjack-209019/services/workload-automation"}}
        {{- else -}}
            {{ $imagesRepository = "gcr.io/blackjack-209019/services"}}
        {{- end -}}
    {{- else if $root.Values.global.hclImageRegistry  -}}
    {{ $imagesRepository = print $root.Values.global.hclImageRegistry }}
    {{- else -}}
    {{ $imagesRepository = print $images.registry }}
    {{- end -}}
    {{- $completeImage := printf "%s/%s" $imagesRepository $images.name  -}}
    {{- $imagesList = append $imagesList $completeImage -}}
  {{- end -}}
  {{- toJson $imagesList -}}
{{- end -}}

{{- define "uno.eventmanager.plugins" -}}
{{- if .Values.eventmanager.plugins.gcp.baseServicePath }}
- name: UNO_EVENTMANAGER_GCP_BASESERVICEACCOUNTPATH
  value: {{ .Values.eventmanager.plugins.gcp.baseServicePath | quote}}
{{- end }}
{{- end -}}

{{- define "uno.plugins.max.size" -}}
{{- if .Values.config.plugins.maxSize }}
- name: QUARKUS_HTTP_LIMITS_MAX_BODY_SIZE
  value: {{ .Values.config.plugins.maxSize | quote}}
{{- end }}
{{- end -}}

{{- define "uno.genai.env.configuration" -}}
{{- if .Values.config.defaultVertexAiModel }}
- name: UNO_GENAI_AGENT_PLATFORM_VERTEX_AI_MODEL
  value: {{ .Values.config.genai.defaultVertexAiModel | quote }}
{{- end }}
{{- if .Values.config.genai.agentModels.vertexAiModels }}
- name: UNO_AIAGENT_MODELS_VERTEXAI
  value: {{ .Values.config.genai.agentModels.vertexAiModels | quote }}
{{- end }}
{{- if .Values.config.genai.agentModels.openAiModels }}
- name: UNO_AIAGENT_MODELS_OPENAI
  value: {{ .Values.config.genai.agentModels.openAiModels | quote }}
{{- end }}
{{- if .Values.config.genai.agentModels.bedrockModels }}
- name: UNO_AIAGENT_MODELS_BEDROCK
  value: {{ .Values.config.genai.agentModels.bedrockModels | quote }}
{{- end }}
{{- if .Values.config.genai.maxUserPrompts }}
- name: UNO_GENAI_AGENT_MAX_USER_PROMPT_FOR_CONTEXT
  value: {{ .Values.config.genai.maxUserPrompts | quote }}
{{- end }}
{{- if .Values.config.genai.maxActionPerConversation }}
- name: UNO_GENAI_AGENT_MAX_ACTION
  value: {{ .Values.config.genai.maxActionPerConversation | quote }}
{{- end }}
{{- if .Values.config.genai.maxUnattendedActions }}
- name: UNO_GENAI_AGENT_MAX_UNATTENDED
  value: {{ .Values.config.genai.maxUnattendedActions | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.gcp.serviceFile }}
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: /security/credentials/gcp-vertexai-svc.json
{{- end }}
{{- if .Values.config.genai.timeout }}
- name: UNO_GENAI_ENDPOINT_TIMEOUT
  value: {{ .Values.config.genai.timeout | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.gcp.projectId }}
- name: UNO_GENAI_PLATFORM_VERTEX_AI_PROJECT_ID
  value: {{ .Values.global.cloudCredentials.gcp.projectId | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.aws.accessKeyId }}
- name: UNO_GENAI_PLATFORM_BEDROCK_ACCESSKEY
  value: {{ .Values.global.cloudCredentials.aws.accessKeyId | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.aws.secretAccessKey }}
- name: UNO_GENAI_PLATFORM_BEDROCK_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-cloud-credentials
      key: AWS_SECRET_KEY
      optional: false
{{- end }}
{{- if .Values.global.cloudCredentials.aws.region }}
- name: UNO_GENAI_PLATFORM_BEDROCK_LOCATION
  value: {{ .Values.global.cloudCredentials.aws.region | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.aws.roleArn }}
- name: UNO_GENAI_PLATFORM_BEDROCK_ROLE
  value: {{ .Values.global.cloudCredentials.aws.roleArn | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.azure.serviceUrl }}
- name: UNO_GENAI_PLATFORM_AZURE_OPENAI_URL
  value: {{ .Values.global.cloudCredentials.azure.serviceUrl | quote }}
{{- end }}
{{- if .Values.global.cloudCredentials.azure.apiKey }}
- name: UNO_GENAI_PLATFORM_AZURE_OPENAI_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-cloud-credentials
      key: AZURE_AI_SERVICE_APIKEY
      optional: false
{{- end }}
{{- if .Values.global.cloudCredentials.openai.baseUrl }}
- name: UNO_GENAI_PLATFORM_OPENAI_BASE_URL
  value: {{ .Values.global.cloudCredentials.openai.baseUrl | quote }}
{{- end }}
{{- if and .Values.global.cloudCredentials.openai.baseUrl .Values.global.cloudCredentials.openai.genaiUri }}
- name: UNO_GENAI_PLATFORM_OPENAI_URL
  value: {{ printf "%s%s" .Values.global.cloudCredentials.openai.baseUrl .Values.global.cloudCredentials.openai.genaiUri | quote}}
{{- end }}
{{- if .Values.global.cloudCredentials.openai.apiKey }}
- name: UNO_GENAI_PLATFORM_OPENAI_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-cloud-credentials
      key: OPEN_AI_SERVICE_APIKEY
      optional: false
{{- end }}
{{- if .Values.hclaipilot.rag.sharedKeySecretName }}
- name: UNO_GENAI_PLATFORM_RAG_URL
  value: https://{{ .Release.Name }}-rag-service:9999
- name: UNO_GENAI_PLATFORM_RAG_SHARED_KEY
  valueFrom:
    secretKeyRef:
      name: {{ (tpl ( .Values.hclaipilot.rag.sharedKeySecretName) .)}}
      key: shared-key
{{- end }}
{{- end -}}