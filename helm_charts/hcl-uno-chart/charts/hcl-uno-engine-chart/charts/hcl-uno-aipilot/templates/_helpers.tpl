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
image: {{ include "pilot.registry" . }}/hcl-aipilot-{{ $container.imageName }}:{{ default $root.Values.image.tag $container.image.tag }}
{{- else -}}
image: {{ include "pilot.registry" . }}/hcl-aipilot-{{ $container.imageName }}:{{ $root.Values.image.tag }}
{{ end }}
{{- end }}

{{- define "pilot.registry" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- if eq $root.Values.global.hclImageRegistry "hclcr.io/sofy" -}}
hclcr.io/uno
{{- else if eq $root.Values.global.hclImageRegistry "hclcr.io" -}}
hclcr.io/uno
{{- else if eq $root.Values.global.hclImageRegistry "gcr.io/blackjack-209019" -}}
gcr.io/blackjack-209019/services/uno
{{- else if $root.Values.global.hclImageRegistry -}}
{{ print $root.Values.global.hclImageRegistry }}
{{- else if and $container.image $container.image.repository -}}
{{ print $container.image.repository }}
{{- else -}}
{{ print $root.Values.image.repository  }}
{{- end -}}
{{- end -}}

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
{{ printf "%s-%s" .Release.Name  "postgres-password" }}
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


{{- define "aipilot.pgvector.pull.secret" -}}
"sa-{{ .Release.Namespace }}"
{{- end -}}

{{- define "aipilot.pgvector.hclimagepull.secret" -}}
"{{ .Values.global.hclImagePullSecret }}"
{{- end -}}

{{- define "aipilot.pgvector.credentials.secret.name" -}}
{{ printf "%s-%s" $.Release.Name  "postgres-password-secret" }}
{{- end -}}

{{- define "aipilot.pgvector.cert.secret.name" -}}
{{ printf "%s-%s" $.Release.Name  "postgres-certificates-secret" }}
{{- end -}}

{{- define "aipilot.pgvector.cert.default.ca.name" -}}
{{ printf "%s-%s" $.Release.Name  "aipilot-selfsigned-ca" }}
{{- end -}}


{{- define "sltCommon.postgres.env.common" -}}
{{- include "sltCommon.env.valueOrSecret" (list . "POSTGRES_HOST" "postgres.postgresService") }}
{{- include "sltCommon.env.valueOrSecret" (list . "POSTGRES_PORT" "postgres.postgresPort") }}
{{- include "sltCommon.env.valueOrSecret" (list . "POSTGRES_DB" "postgres.postgresDB") }}
{{- include "sltCommon.env.valueOrSecret" (list . "POSTGRES_USER" "postgres.postgresUser") }}
{{- end -}}

{{- define "sltCommon.postgres.env.adminpassword" -}}
{{- include "sltCommon.env.valueOrSecret" (list . "POSTGRES_ADMIN_USER" "postgres.postgresAdminUser") }}
{{ include "sltCommon.env.valueOrSecret" (list . "POSTGRES_ADMIN_PASSWORD" "postgres.postgresAdminPassword") }}
{{- end -}}

{{- define "sltCommon.postgres.env.password" -}}
{{ include "sltCommon.env.valueOrSecret" (list . "POSTGRES_PASSWORD" "postgres.postgresPassword") }}
{{- end -}}

{{- define "sltCommon.init.postgres.certificate.env" -}}
- name: POSTGRES_SSLMODE
  value: {{ tpl .Values.postgres.ssl.sslMode . | default "prefer" | quote }}
{{- if (include "sltCommon.exists.valueOrSecret" (list . "postgres.ssl.ca")) }}
- name: POSTGRES_SSLROOTCERT
  value: "/security/postgres/ca.crt"
{{- end }}
{{- if (include "sltCommon.exists.valueOrSecret" (list . "postgres.ssl.cert")) }}
- name: POSTGRES_SSLCERT
  value: "/security/postgres/tls.crt"
{{- end }}
{{- if (include "sltCommon.exists.valueOrSecret" (list . "postgres.ssl.certKey")) }}
- name: POSTGRES_SSLKEY
  value: "/security/postgres/tls.key"
{{- end }}
{{- end -}}

{{- define "sltCommon.env.valueOrSecret" -}}
{{- $root := index . 0 -}}
{{- $envName := index . 1 -}}
{{- $base := index . 2 -}}
{{- $defaultKey := "" -}}
{{- if gt (len .) 3 }}
  {{- $defaultKey = index . 3 -}}
{{- end }}
{{- $baseParts := splitList "." $base -}}
{{- $parentPath := join "." ($baseParts | initial) -}}
{{- $secretField := printf "%sSecretName" (last $baseParts) -}}
{{- $secretKeyField := printf "%sSecretKey" (last $baseParts) -}}
{{- $secretFieldPath := printf "%s.%s" $parentPath $secretField -}}
{{- $secretKeyFieldPath := printf "%s.%s" $parentPath $secretKeyField -}}
{{- $secretKeyValue := $defaultKey | trim -}}
{{- if include "sltCommon.exists.value" (list $root $secretFieldPath) }}
{{- if (include "sltCommon.exists.value" (list $root $secretKeyFieldPath))}}
  {{- $secretKeyValue = include "sltCommon.get.value" (list $root $secretKeyFieldPath) -}}
{{- else if not $secretKeyValue -}}
    {{- fail (printf "Error: SecretKey field '%s' is missing in values and no default key provided. Please make sure to fill '%s'" $secretKeyFieldPath $secretKeyFieldPath ) -}}
{{- end }}
- name: {{ $envName }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl (include "sltCommon.get.value" (list $root $secretFieldPath)) $root | quote }}
      key: {{ tpl $secretKeyValue $root | quote }}
{{- else if include "sltCommon.exists.value" (list $root $base) }}
- name: {{ $envName }}
  value: {{ tpl (include "sltCommon.get.value" (list $root $base)) $root | quote }}
{{- end }}
{{- end -}}

{{- define "sltCommon.postgres.connectionString" -}}
{{- $connectionString := "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}" }}
{{- if eq (tpl .Values.postgres.ssl.sslMode .) "disable" -}}
{{- $connectionString = printf "%s?sslmode=disable" $connectionString -}}
{{- else if or (eq (tpl .Values.postgres.ssl.sslMode .) "require") (eq (tpl .Values.postgres.ssl.sslMode . ) "prefer") -}}
{{- $connectionString = printf "%s?sslmode=require&sslrootcert=${POSTGRES_CA_PATH}" $connectionString -}}
{{- else if eq (tpl .Values.postgres.ssl.sslMode .) "verify-ca" -}}
{{- $connectionString = printf "%s?sslmode=verify-ca&sslrootcert=${POSTGRES_CA_PATH}" $connectionString -}}
{{- else if eq (tpl .Values.postgres.ssl.sslMode .) "verify-full" -}}
{{- $connectionString = printf "%s?sslmode=verify-full&sslrootcert=${POSTGRES_CA_PATH}" $connectionString -}}
{{- end -}}
{{- $connectionString -}}
{{- end -}}

{{- define "sltCommon.volume.valueOrSecret" -}}
{{- $root := index . 0 -}}
{{- $volumeName := index . 1 -}}
{{- $base := index . 2 -}}
{{- $defaultMode := index . 3 -}}
{{- $filePath := index . 4 -}}
{{- $defaultKey := "" -}}
{{- if gt (len .) 5 }}
  {{- $defaultKey = index . 5 -}}
{{- end }}
{{- $baseParts := splitList "." $base -}}
{{- $parentPath := join "." ($baseParts | initial) -}}
{{- $secretField := printf "%sSecretName" (last $baseParts) -}}
{{- $secretKeyField := printf "%sSecretKey" (last $baseParts) -}}
{{- $secretFieldPath := printf "%s.%s" $parentPath $secretField -}}
{{- $secretKeyFieldPath := printf "%s.%s" $parentPath $secretKeyField -}}
{{- $secretKeyValue := $defaultKey | trim -}}
{{- if include "sltCommon.exists.value" (list $root $secretFieldPath) }}
{{- if (include "sltCommon.exists.value" (list $root $secretKeyFieldPath))}}
  {{- $secretKeyValue = include "sltCommon.get.value" (list $root $secretKeyFieldPath) -}}
{{- else if not $secretKeyValue -}}
    {{- fail (printf "Error: SecretKey field '%s' is missing in values and no default key provided. Please make sure to fill '%s'" $secretKeyFieldPath $secretKeyFieldPath ) -}}
{{- end }}
- name: {{ tpl $volumeName $root }}
  secret:
    defaultMode: {{ tpl $defaultMode $root  }}
    secretName: {{ tpl (include "sltCommon.get.value" (list $root $secretFieldPath)) $root | quote }}
    items:
    - key:  {{ tpl $secretKeyValue $root | quote }}
      path: {{ tpl $filePath $root }}
{{- else if include "sltCommon.exists.value" (list $root $base) }}
- name: {{ tpl $volumeName $root }}
  emptyDir:
    medium: Memory
    sizeLimit: 50Mi
{{- end }}
{{- end }}

{{- define "sltCommon.commonssl.volumeMounts" -}}
{{- $root := index . 0 -}}
{{- $volumeNamePrefix := index . 1  | lower -}}
{{- $base := index . 2 -}}
{{- $folder := index . 3 -}}

{{- $certField := printf "%s.cert" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-cert-volume
  mountPath: {{ printf "%s/tls.crt" (tpl $folder $root) }}
  subPath: tls.crt
{{- end }}
{{- $certKeyField := printf "%s.certKey" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certKeyField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-cert-key-volume
  mountPath: {{ printf "%s/tls.key" (tpl $folder $root) }}
  subPath: tls.key 
{{- end }}
{{- $certCaField := printf "%s.certCa" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certKeyField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-cert-ca-volume
  mountPath: {{ printf "%s/certCA.crt" (tpl $folder $root) }}
  subPath: certCA.crt
{{- end }}
{{- $caField := printf "%s.ca" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $caField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-ca-volume
  mountPath: {{ printf "%s/ca.crt" (tpl $folder $root) }}
  subPath: ca.crt
{{- end }}
{{- end -}}

{{- define "sltCommon.commonssl.volume" -}}
{{- $root := index . 0 -}}
{{- $volumeNamePrefix := index . 1  | lower -}}
{{- $base := index . 2 -}}
{{- $certField := printf "%s.cert" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certField )) }}
{{ include "sltCommon.volume.valueOrSecret" (list $root (printf "%s-common-ssl-cert-volume" $volumeNamePrefix) $certField "0644" "tls.crt" "tls.crt") }}
{{- end }}
{{- $certKeyField := printf "%s.certKey" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certKeyField )) }}
{{- include "sltCommon.volume.valueOrSecret" (list $root (printf "%s-common-ssl-cert-key-volume" $volumeNamePrefix) $certKeyField "0600" "tls.key" "tls.key") }}
{{- end }}
{{- $certCaField := printf "%s.certCa" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certCaField )) }}
{{- include "sltCommon.volume.valueOrSecret" (list $root (printf "%s-common-ssl-cert-ca-volume" $volumeNamePrefix) $certCaField "0644" "certCA.crt" "ca.crt") }}
{{- end }}
{{- $caField := printf "%s.ca" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $caField )) }}
{{- include "sltCommon.volume.valueOrSecret" (list $root (printf "%s-common-ssl-ca-volume" $volumeNamePrefix) $caField "0644" "ca.crt" "ca.crt ") }}
{{- end }}
{{- end -}}

{{- define "sltCommon.exists.valueOrSecret" -}}
{{- $root := index . 0 -}}
{{- $base := index . 1 -}}
{{- $baseParts := splitList "." $base -}}
{{- $parentPath := join "." ($baseParts | initial) -}}
{{- $secretField := printf "%sSecretName" (last $baseParts) -}}
{{- $secretKeyField := printf "%sSecretKey" (last $baseParts) -}}
{{- $secretFieldPath := printf "%s.%s" $parentPath $secretField -}}
{{- $secretKeyFieldPath := printf "%s.%s" $parentPath $secretKeyField -}}
{{- if include "sltCommon.exists.value" (list $root $secretFieldPath) }}
true
{{- else if include "sltCommon.exists.value" (list $root $base) }}
true
{{- end }}
{{- end -}}

{{- define "sltCommon.mergestring.underscore" -}}
{{- $result := "" -}}
{{- $string1 :=  index . 0 -}}
{{- $string2 :=  index . 1 -}}
{{- if and $string1 $string2 -}}
{{- $result = printf "%s_%s" $string1 $string2 -}}
{{- else if $string1 -}}
{{- $result = $string1 -}}
{{- else if $string2 -}}
{{- $result = $string2 -}}
{{- end -}}
{{- $result -}}
{{- end -}}

{{- define "sltCommon.env.commonssl" -}}
{{- $root := index . 0 -}}
{{- $envPrefix := index . 1 -}}
{{- $base := index . 2 -}}
{{- $folder := index . 3 -}}
{{- $certName := (or $envPrefix "cert") -}}
{{- $caName := (or $envPrefix "ca") -}}
{{- $certField := printf "%s.cert" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certField )) }}
{{- $envName := upper ( include "sltCommon.mergestring.underscore" (list $envPrefix "CERT_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/tls.crt" $folder }}
{{- end }}
{{- $keyField := printf "%s.certKey" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $keyField )) }}
{{- $envName := upper ( include "sltCommon.mergestring.underscore" (list $envPrefix "CERT_KEY_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/tls.key" $folder  }}
{{- end }}
{{- $certKeyPassword := printf "%s.certKeyPassword" $base -}}
{{- if include "sltCommon.exists.value" (list $root $certKeyPassword) }}
{{- $envName := upper ( include "sltCommon.mergestring.underscore" (list $envPrefix "CERT_KEY_PASSWORD")) }}
- name: {{ $envName }}
  value: {{ tpl (include "sltCommon.get.value" (list $root $certKeyPassword)) $root }}
{{- end }}
{{- $certCaField := printf "%s.caCert" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $certCaField )) }}
{{- $envName := upper ( include "sltCommon.mergestring.underscore" (list $envPrefix "CA_CERT_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/certCA.crt" $folder }}
{{- end }}
{{- $caField := printf "%s.ca" $base -}}
{{- if (include "sltCommon.exists.valueOrSecret" (list $root $caField )) }}
{{- $envName := upper ( include "sltCommon.mergestring.underscore" (list $envPrefix "CA_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/ca.crt" $folder }}
{{- end }}
{{- end -}}

{{- define "sltCommon.exists.value" -}}
{{- $root := index . 0 -}}
{{- $base := index . 1 -}}
{{- $baseParts := splitList "." $base -}}
{{- $parent := $baseParts | initial -}}
{{- $parentMap := $root.Values -}}
{{- range $parent -}}
  {{- $parentMap = index $parentMap . }}
{{- end }}
{{- $key := last $baseParts -}}
{{- if and (hasKey $parentMap $key) (index $parentMap $key) (ne (toString (index $parentMap $key)) "") }}
true
{{- end }}
{{- end -}}

{{- define "sltCommon.get.value" -}}
{{- $root := index . 0 -}}
{{- $base := index . 1 -}}
{{- $baseParts := splitList "." $base -}}
{{- $parent := $baseParts | initial -}}
{{- $parentMap := $root.Values -}}
{{- range $parent }}
  {{- $parentMap = index $parentMap . }}
{{- end }}
{{- $key := last $baseParts -}}
{{- index $parentMap $key -}}
{{- end -}}

{{- define "sltCommon.commonssl.volumeMounts.postgres" -}}
{{- include "sltCommon.commonssl.volumeMounts" (list . "postgres" "postgres.ssl" "/security/postgres") }}
{{- end -}}

{{- define "sltCommon.commonssl.volume.postgres" -}}
{{- include "sltCommon.commonssl.volume" (list . "postgres" "postgres.ssl") }}
{{- end -}}

{{- define "sltCommon.commonssl.env.postgres" -}}
{{ include "sltCommon.env.commonssl" (list . "POSTGRES" "postgres.ssl" "/security/postgres") }}
{{- end -}}

{{- define "aipilot.commonssl.volumeMounts.definition" -}}
{{ include "sltCommon.commonssl.volumeMounts.postgres" . }}
{{- end -}}

{{- define "aipilot.commonssl.volume.definition" -}}
{{- include "sltCommon.commonssl.volume.postgres" . }}
{{- end -}}

{{- define "aipilot.commonssl.env.definition" -}}
{{ include "sltCommon.commonssl.env.postgres" . }}
{{- end -}}

{{- define "common.postgres.fullname" -}}
{{- printf "%s-pg-db" .Release.Name | trunc 21 | trimSuffix "-" -}}
{{- end -}}