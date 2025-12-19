{{/*
Expand the name of the chart.
*/}}
{{- define "agenticbuilder.name" -}}
{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "agenticbuilder.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "agenticbuilder.runner.list" -}}
{{- $myList := list "test" "prod" -}}
{{ toJson $myList }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agenticbuilder.labels" -}}
helm.sh/chart: {{ include "agenticbuilder.chart" . }}
{{ include "agenticbuilder.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agenticbuilder.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agenticbuilder.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "agenticbuilder.fullname" -}}
{{- if .Values.fullNameOverride }}
{{- .Values.fullNameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $releaseName := default .Release.Name .Values.nameOverride }}
{{- if contains $releaseName .Release.Name }}
{{- printf "%s-agentic" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-agentic" .Release.Name $releaseName | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "uno.fullname" -}}
{{- $name := default .Release.Name .Values.nameOverride -}}
{{- printf "%s"  $name | trunc 42 | trimSuffix "-" -}}
{{- end -}}


{{- define "agenticbuilder.selectorLabels.backend" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- include "agenticbuilder.selectorLabels" $root }}
name: {{ include "agenticbuilder.fullname" $root }}-{{ $container.name }}
track: {{ $root.Values.track }}
tier: backend
{{- end }}

{{- define "agenticbuilder.selectorLabels.frontend" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{  include "agenticbuilder.selectorLabels" $root }}
name: {{ include "agenticbuilder.fullname" $root }}-{{ $container.name }}
track: {{ $root.Values.track }}
tier: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "agenticbuilder.serviceAccountName" -}}
{{- if .Values.global.serviceAccountName }}
serviceAccountName: {{ tpl .Values.global.serviceAccountName .}}
{{- else if .Values.serviceAccount.name }}
serviceAccountName: {{ tpl .Values.serviceAccount.name  .}}
{{- end }}
{{- end }}

{{/*
Create image name as "repository/name:tag".
If imageName already has :tag or @digest, return it as-is.
*/}}
{{- define "agenticbuilder.image" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- $img := $container.imageName | trim -}}
{{- $last := last (splitList "/" $img) -}}
{{- $hasTag := contains ":" $last -}}
{{- $hasDigest := contains "@" $img -}}

{{- if or $hasTag $hasDigest -}}
image: "{{ $img }}"
{{- else -}}
  {{- if $container.image -}}
image: "{{ default $root.Values.image.repository $container.image.repository }}/{{ $container.imageName }}:{{ default $root.Values.image.tag $container.image.tag }}"
  {{- else -}}
image: "{{ $root.Values.image.repository }}/{{ $container.imageName }}:{{ $root.Values.image.tag }}"
  {{- end -}}
{{- end -}}
{{- end -}}
{{/*
Create image pull policy.
*/}}
{{- define "agenticbuilder.imagePullPolicy" -}}
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
{{- end -}}

{{- define "agenticbuilder.microservices.list" -}}
{{- $myList := list "ams" "executor-manager" "credential-manager" "executor" "ui" "cm" -}}
{{ toJson $myList }}
{{- end -}}

{{/*
Create the probe check for the liveness and readiness.
*/}}
{{- define "agenticbuilder.probe" -}}
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
{{- define "agenticbuilder.resources" -}}
{{- if .resources -}}
resources:
  {{- if .resources.limits }}
  limits: {{ include "agenticbuilder.resource.check" .resources.limits | indent 6}}
  {{- end -}}
  {{- if .resources.requests }}
  requests: {{ include "agenticbuilder.resource.check" .resources.requests | indent 6}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "agenticbuilder.resource.check" -}}
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
{{- define "agenticbuilder.metrics" -}}
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
{{- end -}}

{{- define "agenticbuilder.exists.value" -}}
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

{{- define "agenticbuilder.get.value" -}}
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


{{- define "agenticbuilder.cert.name" -}}
{{- if .Values.certificates.certSecretName -}}
{{- tpl .Values.certificates.certSecretName . -}}
{{- else -}}
{{ $fullname := include "agenticbuilder.fullname" . }}
{{- printf "%s-%s"  $fullname "certificates-secret" -}}
{{- end -}}
{{- end -}}

{{- define "agenticbuilder.cert.issuer" -}}
{{- if .Values.certificates.issuerName -}}
{{- tpl .Values.certificates.issuerName . -}}
{{- else -}}
{{ $fullname := include "agenticbuilder.fullname" . }}
{{- printf "%s-%s"  $fullname "agentic-ca-issuer" -}}
{{- end -}}
{{- end -}}

{{- define "agenticbuilder.ca.secret.name" -}}
{{- if .Values.certificates.caPairSecretName -}}
{{- tpl  .Values.certificates.caPairSecretName . | quote }}
{{- else -}}
{{ $fullname := include "agenticbuilder.fullname" . }}
{{- printf "%s-%s"  $fullname "selfsigned-ca" -}}
{{- end -}}
{{- end -}}

{{- define "agenticbuilder.root.ca.name" -}}
{{ $fullname := include "agenticbuilder.fullname" . }}
{{- printf "%s-%s"  $fullname "root-ca" -}}
{{- end -}}

{{- define "agenticbuilder.apikey" -}}
{{- if .Values.global.cloudCredentials -}}
{{ .Values.global.cloudCredentials.gcp | b64enc | quote }}
{{- else -}}
{{ .Values.config.gcp_key | b64enc | quote }}
{{- end -}}
{{- end -}}

{{- define "agenticbuilder.env.valueOrSecret" -}}
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
{{- if include "agenticbuilder.exists.value" (list $root $secretFieldPath) }}
{{- if (include "agenticbuilder.exists.value" (list $root $secretKeyFieldPath))}}
  {{- $secretKeyValue = include "agenticbuilder.get.value" (list $root $secretKeyFieldPath) -}}
{{- else if not $secretKeyValue -}}
    {{- fail (printf "Error: SecretKey field '%s' is missing in values and no default key provided. Please make sure to fill '%s'" $secretKeyFieldPath $secretKeyFieldPath ) -}}
{{- end }}
- name: {{ $envName }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl (include "agenticbuilder.get.value" (list $root $secretFieldPath)) $root | quote }}
      key: {{ tpl $secretKeyValue $root | quote }}
{{- else if include "agenticbuilder.exists.value" (list $root $base) }}
- name: {{ $envName }}
  value: {{ tpl (include "agenticbuilder.get.value" (list $root $base)) $root | quote }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.volume.valueOrSecret" -}}
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
{{- if (include "agenticbuilder.exists.value" (list $root $secretKeyFieldPath))}}
  {{- $secretKeyValue = include "agenticbuilder.get.value" (list $root $secretKeyFieldPath) -}}
{{- else if not $secretKeyValue -}}
    {{- fail (printf "Error: SecretKey field '%s' is missing in values and no default key provided. Please make sure to fill '%s'" $secretKeyFieldPath $secretKeyFieldPath ) -}}
{{- end }}
{{- if include "agenticbuilder.exists.value" (list $root $secretFieldPath) }}
- name: {{ tpl $volumeName $root }}
  secret:
    defaultMode: {{ tpl $defaultMode $root  }}
    secretName: {{ tpl (include "agenticbuilder.get.value" (list $root $secretFieldPath)) $root | quote }}
    items:
    - key:  {{ tpl $secretKeyValue $root | quote }}
      path: {{ tpl $filePath $root }}
{{- else if include "agenticbuilder.exists.value" (list $root $base) }}
- name: {{ tpl $volumeName $root }}
  emptyDir:
    medium: Memory
    sizeLimit: 50Mi
{{- end }}
{{- end }}

{{- define "agenticbuilder.exists.valueOrSecret" -}}
{{- $root := index . 0 -}}
{{- $base := index . 1 -}}
{{- $baseParts := splitList "." $base -}}
{{- $parentPath := join "." ($baseParts | initial) -}}
{{- $secretField := printf "%sSecretName" (last $baseParts) -}}
{{- $secretKeyField := printf "%sSecretKey" (last $baseParts) -}}
{{- $secretFieldPath := printf "%s.%s" $parentPath $secretField -}}
{{- $secretKeyFieldPath := printf "%s.%s" $parentPath $secretKeyField -}}
{{- if include "agenticbuilder.exists.value" (list $root $secretFieldPath) }}
true
{{- else if include "agenticbuilder.exists.value" (list $root $base) }}
true
{{- end }}
{{- end -}}

{{- define "agenticbuilder.mergestring.underscore" -}}
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

{{- define "agenticbuilder.env.commonssl" -}}
{{- $root := index . 0 -}}
{{- $envPrefix := index . 1 -}}
{{- $base := index . 2 -}}
{{- $folder := index . 3 -}}
{{- $certName := (or $envPrefix "cert") -}}
{{- $caName := (or $envPrefix "ca") -}}
{{- $certField := printf "%s.cert" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certField )) }}
{{- $envName := upper ( include "agenticbuilder.mergestring.underscore" (list $envPrefix "CERT_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/tls.crt" $folder }}
{{- end }}
{{- $keyField := printf "%s.certKey" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $keyField )) }}
{{- $envName := upper ( include "agenticbuilder.mergestring.underscore" (list $envPrefix "CERT_KEY_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/tls.key" $folder  }}
{{- end }}
{{- $certKeyPassword := printf "%s.certKeyPassword" $base -}}
{{- if include "agenticbuilder.exists.value" (list $root $certKeyPassword) }}
{{- $envName := upper ( include "agenticbuilder.mergestring.underscore" (list $envPrefix "CERT_KEY_PASSWORD")) }}
- name: {{ $envName }}
  value: {{ tpl (include "agenticbuilder.get.value" (list $root $certKeyPassword)) $root }}
{{- end }}
{{- $certCaField := printf "%s.caCert" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certCaField )) }}
{{- $envName := upper ( include "agenticbuilder.mergestring.underscore" (list $envPrefix "CA_CERT_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/certCA.crt" $folder }}
{{- end }}
{{- $caField := printf "%s.ca" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $caField )) }}
{{- $envName := upper ( include "agenticbuilder.mergestring.underscore" (list $envPrefix "CA_PATH")) }}
- name: {{ $envName }}
  value: {{ printf "%s/ca.crt" $folder }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.env.postgres.password" -}}
{{ include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_PASSWORD" "common.postgres.postgresPassword") }}
{{ include "agenticbuilder.postgres.database.url.env" . }}
{{- end -}}

{{- define "agenticbuilder.init.postgres.certificate.env" -}}
- name: POSTGRES_SSLMODE
  value: {{ tpl .Values.common.postgres.ssl.sslMode . | default "prefer" | quote }}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list . "common.postgres.ssl.ca")) }}
- name: POSTGRES_SSLROOTCERT
  value: "/security/postgres/ca.crt"
{{- end }}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list . "common.postgres.ssl.cert")) }}
- name: POSTGRES_SSLCERT
  value: "/security/postgres/tls.crt"
{{- end }}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list . "common.postgres.ssl.certKey")) }}
- name: POSTGRES_SSLKEY
  value: "/security/postgres/tls.key"
{{- end }}
{{- end -}}

{{- define "agenticbuilder.env.postgres.adminpassword" -}}
{{- include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_ADMIN_USER" "common.postgres.postgresAdminUser") }}
{{ include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_ADMIN_PASSWORD" "common.postgres.postgresAdminPassword") }}
{{- end -}}

{{- define "agenticbuilder.env.valkey.password" -}}
{{- if .Values.common.valkey.valkeyPasswordSecret }}
- name: VALKEY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.common.valkey.valkeyPasswordSecret . }}
      key: {{ tpl .Values.common.valkey.valkeyPasswordSecretKey . }}
{{- else if .Values.common.valkey.valkeyPassword }}
- name: VALKEY_PASSWORD
  value: {{ tpl .Values.common.valkey.valkeyPassword . | quote }}
{{- else }}
{{- fail "No VALKEY password provided. Please set common.valkey.valkeyPasswordSecret or common.valkey.valkeyPassword." -}}
{{- end }}
{{- end -}}

{{/* Generate the name of the deployment */}}
{{- define "agenticbuilder.rag.name" -}}
{{- printf "%s-%s" .Release.Name .Values.rag.app.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "agenticbuilder.pull.secret" -}}
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

{{- define "agenticbuilder.postgres.client.volume" -}}
- name: postgres-client-certs
  secret:
{{- if .Values.common.postgres.clientCertificateSecret }}
    secretName: {{ tpl .Values.common.postgres.clientCertificateSecret . | quote }}
{{- else -}}
    {{ $fullname := include "agenticbuilder.fullname" . }}
    secretName: {{ $fullname }}-postgres-client-certificate
{{- end }}
    defaultMode: 0640
{{- end -}}

{{- define "agenticbuilder.postgres.initContainer" -}}
{{- if .Values.common.postgres.initDatabases -}}
initContainers:
  - name: init-wait-for-postgres
    image: busybox
    env:
      - name: POSTGRES_HOST
        value: {{ tpl .Values.common.postgres.postgresService . | quote }}
    command: ['sh', '-c', 'until nc -z $POSTGRES_HOST:5432; do echo waiting for $POSTGRES_HOST:5432; sleep 30; done;']
  - name: init-create-postgres-user
    image: postgres:latest
    volumeMounts:
{{- include "agenticbuilder.commonssl.volumeMounts.postgres" . | nindent 4 }}
    env:
{{- include "agenticbuilder.env.postgres.adminpassword" . | nindent 6 }}
{{- include "agenticbuilder.env.postgres.password" . | nindent 6 }}
{{- include "agenticbuilder.init.postgres.certificate.env" . | nindent 6 }}
{{- include "agenticbuilder.postgres.envs.common" . | nindent 6 }}
    command:
      - sh
      - -c
      - |
        if ! PGPORT=$POSTGRES_PORT PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -tAc "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'" | grep -q 1; then
          PGPORT=$POSTGRES_PORT PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -c "CREATE USER \"$POSTGRES_USER\" WITH PASSWORD '$POSTGRES_PASSWORD';"
        else
          echo "User $POSTGRES_USER already exists"
        fi
  - name: init-create-postgres-db
    image: postgres:latest
    volumeMounts:
{{- include "agenticbuilder.commonssl.volumeMounts.postgres" . | nindent 4 }}
    env:
{{- include "agenticbuilder.init.postgres.certificate.env" . | nindent 6 }}
{{- include "agenticbuilder.env.postgres.adminpassword" . | nindent 6 }}
{{- include "agenticbuilder.postgres.envs.common" . | nindent 6 }}
    command:
      - sh
      - -c
      - |
        if ! PGPORT=5432 PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -lqt | cut -d '|' -f 1 | grep -qw $POSTGRES_DB; then
          PGPORT=5432 PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -c "CREATE DATABASE $POSTGRES_DB WITH OWNER \"$POSTGRES_USER\" ENCODING=UTF8 TEMPLATE=template0;"
        else
          echo "Database $POSTGRES_DB already exists with this user $POSTGRES_USER"
        fi
        PGPORT=5432 PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql "host=$POSTGRES_HOST user=$POSTGRES_ADMIN_USER dbname=$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS vector;"
      {{- end }}
{{- end -}}

{{- define "agenticbuilder.replace.dash.percentdash" -}}
{{- replace "-" "%-" . -}}
{{- end -}}

{{- define "agenticbuilder.hclauthorization.env" -}}
{{- $root := . -}}
{{- $unofullname := include "uno.fullname" . -}}
{{- $ctx := merge (dict "unofullname" $unofullname) . -}}
{{- if .Values.authorization.certs }}
{{- $idx := 0 -}}
{{- range $key, $value := .Values.authorization.certs }}
- name: {{ $key }}
  value: /authcert/{{ tpl (lower $value) $ctx }}_{{ $idx }}.crt
{{- $idx = add $idx 1 }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.hclauthorization.volume.mount" -}}
{{- $root := . }}
{{- $unofullname := include "uno.fullname" . -}}
{{- $ctx := merge (dict "unofullname" $unofullname) . -}}
{{- if .Values.authorization.certs }}
{{- $idx := 0 -}}
{{- range $key, $value := .Values.authorization.certs }}
- name: {{ tpl (lower $value) $ctx }}-cert-volume
  mountPath: /authcert/{{ tpl (lower $value) $ctx }}_{{ $idx }}.crt
  subPath: {{ tpl (lower $value) $ctx }}.crt
  readOnly: true
{{- $idx = add $idx 1 -}}
{{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.hclauthorization.volume" -}}
{{- if .Values.authorization.certs }}
{{- $root := . -}}
{{- $unofullname := include "uno.fullname" . -}}
{{- $ctx := merge (dict "unofullname" $unofullname) . -}}
{{- $seen := dict -}}
{{- range $key, $value := .Values.authorization.certs -}}
{{- $val := tpl (lower $value) $ctx -}}
{{- if not (hasKey $seen $val) }}
- name: {{ $val }}-cert-volume
  secret:
    defaultMode: 0644
    secretName: {{ tpl (toString $value) $ctx | quote }}
    items:
    - key: tls.crt
      path: {{ $val }}.crt
{{- $_ := set $seen $val true -}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.additionalCAs.volume" -}}
{{- range .Values.common.truststore.agenticAdditionalCASecrets }}
  {{- if kindIs "string" . }}
- name: {{ tpl . $ }}-cert-volume
  secret:
    defaultMode: 0664
    secretName: {{ tpl . $ | quote }}
    items:
    - key: ca.crt
      path: {{ tpl . $ }}.crt
  {{- else if and (hasKey . "secretName") (hasKey . "secretKey") }}
- name: {{ tpl .secretName $ }}-cert-volume
  secret:
    defaultMode: 0664
    secretName: {{ tpl .secretName $ | quote }}
    items:
    - key: {{ tpl .secretKey $ | quote }}
      path: {{ tpl .secretKey $ }}.crt
  {{- else }}
    {{- fail "agenticAdditionalCASecrets must be a string or an object with secretName and secretKey" }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.additionalCAs.volumeMounts" -}}
{{- range .Values.common.truststore.agenticAdditionalCASecrets }}
- name: {{ tpl . $}}-cert-volume
  mountPath: /ca/{{ tpl . $ }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.otel.volume" -}}
{{- if or ( eq (tpl .Values.telemetry.telemetryTraceInsecure .) "false")  (eq (tpl .Values.telemetry.telemetryMetricInsecure .) "false") }}
- name: {{ tpl .Values.telemetry.telemetryExporterCertificate . }}-cert-volume
  secret:
    defaultMode: 0664
    secretName: {{ tpl .Values.telemetry.telemetryExporterCertificate . | quote }}
    items:
    - key: tls.crt
      path: {{ tpl .Values.telemetry.telemetryExporterCertificate .  }}.crt
{{- end }}
{{- end -}}

{{- define "agenticbuilder.otel.volumeMounts" -}}
{{- if or ( eq (tpl .Values.telemetry.telemetryTraceInsecure .) "false")  (eq (tpl .Values.telemetry.telemetryMetricInsecure .) "false") }}
- name: {{ tpl .Values.telemetry.telemetryExporterCertificate . }}-cert-volume
  mountPath: /ca/otel/
{{- end }}
{{- end -}}

{{- define "agenticbuilder.postgres.database.url.env" -}}
- name: DATABASE_URL
  value: "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@{{ tpl .Values.common.postgres.postgresService . }}:$(POSTGRES_PORT)/{{ tpl .Values.common.postgres.postgresDB . }}"
{{- end -}}

{{- define "agenticbuilder.postgres.database.adminurl.env" -}}
- name: DATABASE_URL
  value: "postgresql://$(ADMIN_POSTGRES_USER):$(ADMIN_POSTGRES_PASSWORD)@{{ tpl .Values.common.postgres.postgresService . }}:$(POSTGRES_PORT)/{{ tpl .Values.common.postgres.postgresDB . }}"
{{- end -}}

{{- define "agenticbuilder.postgres.envs.common" -}}
{{- include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_HOST" "common.postgres.postgresService") }}
{{- include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_PORT" "common.postgres.postgresPort") }}
{{- include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_DB" "common.postgres.postgresDB") }}
{{- include "agenticbuilder.env.valueOrSecret" (list . "POSTGRES_USER" "common.postgres.postgresUser") }}
{{- end -}}

{{- define "agenticbuilder.commonssl.volumeMounts" -}}
{{- $root := index . 0 -}}
{{- $volumeNamePrefix := index . 1  | lower -}}
{{- $base := index . 2 -}}
{{- $folder := index . 3 -}}

{{- $certField := printf "%s.cert" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-cert-volume
  mountPath: {{ printf "%s/tls.crt" (tpl $folder $root) }}
  subPath: tls.crt
{{- end }}
{{- $certKeyField := printf "%s.certKey" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certKeyField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-cert-key-volume
  mountPath: {{ printf "%s/tls.key" (tpl $folder $root) }}
  subPath: tls.key 
{{- end }}
{{- $certCaField := printf "%s.certCa" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certKeyField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-cert-ca-volume
  mountPath: {{ printf "%s/certCA.crt" (tpl $folder $root) }}
  subPath: certCA.crt
{{- end }}
{{- $caField := printf "%s.ca" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $caField )) }}
- name: {{ tpl $volumeNamePrefix $root }}-common-ssl-ca-volume
  mountPath: {{ printf "%s/ca.crt" (tpl $folder $root) }}
  subPath: ca.crt
{{- end }}
{{- end -}}

{{- define "agenticbuilder.commonssl.volume" -}}
{{- $root := index . 0 -}}
{{- $volumeNamePrefix := index . 1  | lower -}}
{{- $base := index . 2 -}}
{{- $certField := printf "%s.cert" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certField )) }}
{{ include "agenticbuilder.volume.valueOrSecret" (list $root (printf "%s-common-ssl-cert-volume" $volumeNamePrefix) $certField "0644" "tls.crt" "tls.crt") }}
{{- end }}
{{- $certKeyField := printf "%s.certKey" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certKeyField )) }}
{{- include "agenticbuilder.volume.valueOrSecret" (list $root (printf "%s-common-ssl-cert-key-volume" $volumeNamePrefix) $certKeyField "0600" "tls.key" "tls.key") }}
{{- end }}
{{- $certCaField := printf "%s.certCa" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $certCaField )) }}
{{- include "agenticbuilder.volume.valueOrSecret" (list $root (printf "%s-common-ssl-cert-ca-volume" $volumeNamePrefix) $certCaField "0644" "certCA.crt" "ca.crt") }}
{{- end }}
{{- $caField := printf "%s.ca" $base -}}
{{- if (include "agenticbuilder.exists.valueOrSecret" (list $root $caField )) }}
{{- include "agenticbuilder.volume.valueOrSecret" (list $root (printf "%s-common-ssl-ca-volume" $volumeNamePrefix) $caField "0644" "ca.crt" "ca.crt ") }}
{{- end }}
{{- end -}}


{{- define "agenticbuilder.commonssl.volumeMounts.postgres" -}}
{{- include "agenticbuilder.commonssl.volumeMounts" (list . "postgres" "common.postgres.ssl" "/security/postgres") -}}
{{- end -}}

{{- define "agenticbuilder.commonssl.volume.postgres" -}}
{{- include "agenticbuilder.commonssl.volume" (list . "postgres" "common.postgres.ssl") -}}
{{- end -}}

{{- define "agenticbuilder.commonssl.env.postgres" -}}
{{ include "agenticbuilder.env.commonssl" (list . "POSTGRES" "common.postgres.ssl" "/security/postgres") }}
{{- end -}}

{{- define "agenticbuilder.commonssl.volumeMounts.definition" -}}
{{ include "agenticbuilder.commonssl.volumeMounts" (list . "client" "common.ssl" "/security/client") }}
{{ include "agenticbuilder.commonssl.volumeMounts.postgres" . }}
{{ include "agenticbuilder.commonssl.volumeMounts" (list . "valkey" "common.valkey.ssl" "/security/valkey") }}
{{- end -}}

{{- define "agenticbuilder.commonssl.volume.definition" -}}
{{- include "agenticbuilder.commonssl.volume.postgres" . -}}
{{- include "agenticbuilder.commonssl.volume" (list . "client" "common.ssl") -}}
{{- include "agenticbuilder.commonssl.volume" (list . "valkey" "common.valkey.ssl") -}}
{{- end -}}

{{- define "agenticbuilder.commonssl.env.definition" -}}
{{ include "agenticbuilder.env.commonssl" (list . "" "common.ssl" "/security/client") }}
{{ include "agenticbuilder.commonssl.env.postgres" . }}
{{ include "agenticbuilder.env.commonssl" (list . "VALKEY" "common.valkey.ssl" "/security/valkey") }}
{{- end -}}

{{- define "common.postgres.fullname" -}}
{{- printf "%s-pg-db" .Release.Name | trunc 21 | trimSuffix "-" -}}
{{- end -}}