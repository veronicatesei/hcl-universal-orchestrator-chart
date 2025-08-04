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
Create image name as "repository-name:tag".
*/}}
{{- define "agenticbuilder.image" -}}
{{- $root := index . 0 -}}
{{- $container := index . 1 -}}
{{- if $container.image -}} 
image: "{{ default $root.Values.image.repository $container.image.repository}}/{{ $container.imageName }}:{{ default $root.Values.image.tag $container.image.tag }}"
{{- else -}}
image: "{{ $root.Values.image.repository }}/{{ $container.imageName }}:{{ $root.Values.image.tag }}"
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
{{- $myList := list "ams" "executor-manager" "credential-manager" "apisix" "executor" "ui" "cm" -}}
{{ toJson $myList }}
{{- end -}}

{{/*
}}
{{- end }}

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
{{- end }}


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


{{- define "agenticbuilder.env.postgres.password" -}}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.common.postgres.postgresPassword . }}
      key: password
- name: DATABASE_URL
  value: "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@{{ tpl .Values.common.postgres.postgresService . }}:$(POSTGRES_PORT)/{{ tpl .Values.common.postgres.postgresDB . }}"
{{- end -}}

{{- define "agenticbuilder.postgres.certificate.env" -}}
- name: POSTGRES_SSLMODE
  value: "verify-ca"
- name: POSTGRES_SSLROOTCERT
  value: "/postgres/certs/ca.crt"
- name: POSTGRES_SSLCERT
  value: "/postgres/certs/tls.crt"
- name: POSTGRES_SSLKEY
  value: "/postgres/certs/tls.key"
{{- end -}}

{{- define "agenticbuilder.postgres.certificate.volume.mount" -}}
- name: postgres-client-certs
  mountPath: /postgres/certs
  readOnly: true
{{- end -}}

{{- define "agenticbuilder.env.postgres.adminpassword" -}}
- name: POSTGRES_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.common.postgres.postgresPassword . }}
      key: postgres-password
{{- end -}}

{{- define "agenticbuilder.env.apisix.apikey" -}}
{{- if .Values.common.apisix.existingSecret -}}
- name: APISIX_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.common.apisix.existingSecret . }}
      key: {{ tpl .Values.common.apisix.existingSecretAdminTokenKey . }}
{{- else if .Values.common.apisix.apiTokenAdmin -}}
- name: APISIX_API_KEY
  value: {{ tpl .Values.common.apisix.apiTokenAdmin . | quote }}
{{- else -}}
{{- fail "No APISIX API key provided. Please set common.apisix.existingSecret or common.apisix.apiTokenAdmin." -}}
{{- end -}}
{{- end -}}

{{- define "agenticbuilder.env.valkey.password" -}}
{{- if .Values.common.valkey.valkeyPasswordSecret -}}
- name: VALKEY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ tpl .Values.common.valkey.valkeyPasswordSecret . }}
      key: {{ tpl .Values.common.valkey.valkeyPasswordSecretKey . }}
{{- else if .Values.common.valkey.valkeyPassword -}}
- name: VALKEY_PASSWORD
  value: {{ tpl .Values.common.valkey.valkeyPassword . | quote }}
{{- else -}}
{{- fail "No VALKEY password provided. Please set common.valkey.valkeyPasswordSecret or common.valkey.valkeyPassword." -}}
{{- end -}}
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
{{- if .Values.common.postgres.clientCertificateSecret -}}
    secretName: {{ tpl .Values.common.postgres.clientCertificateSecret . | quote }}
{{- else -}}
    {{ $fullname := include "agenticbuilder.fullname" . }}
    secretName: {{ $fullname }}-postgres-client-certificate
{{- end }}
    defaultMode: 0640
{{- end -}}

{{- define "agenticbuilder.postgres.volume" -}}
{{- if .Values.common.postgres.postgresCertificateSecret -}}
- name: postgres-certs
  secret:
    secretName: {{ tpl .Values.common.postgres.postgresCertificateSecret . | quote }}
    defaultMode: 0640
{{- end }}
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
    {{- if .Values.common.postgres.postgresCertificateSecret }}
    volumeMounts:
      - name: postgres-certs
        mountPath: "/security/postgres/certs"
        readOnly: true
    {{- end }}
    env:
{{- include "agenticbuilder.env.postgres.adminpassword" . | nindent 6 }}
{{- include "agenticbuilder.env.postgres.password" . | nindent 6 }}
      - name: POSTGRES_HOST
        value: {{ tpl .Values.common.postgres.postgresService . | quote }}
      - name: POSTGRES_DB
        value: {{ tpl .Values.common.postgres.postgresDB . | default "agenticbuilder" | quote }}
      - name: POSTGRES_PORT
        value: {{ tpl .Values.common.postgres.postgresPort . | default "5432" | quote }}
      - name: POSTGRES_ADMIN_USER
        value: {{ tpl .Values.common.postgres.adminUser . | default "postgres" | quote }}
      - name: POSTGRES_USER
        value: {{ tpl .Values.common.postgres.postgresUser . | default "postgres"  | quote }}
      {{- if .Values.common.postgres.postgresCertificateSecret }}
      - name: PGSSLCERT 
        value: /security/postgres/certs/tls.crt
      - name: PGSSLKEY
        value: /security/postgres/certs/tls.key
      {{- end }}
    command:
      - sh
      - -c
      - |
        if ! PGPORT=$POSTGRES_PORT PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -lqt | cut -d \| -f 1 | grep -qw $POSTGRES_DB; then
          PGPORT=5432 PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"
        else
          echo "User $POSTGRES_USER already exists"
        fi  
  - name: init-create-postgres-db
    image: postgres:latest
    {{- if .Values.common.postgres.postgresCertificateSecret }}
    volumeMounts:
      - name: postgres-certs
        mountPath: "/security/postgres/certs"
        readOnly: true
    {{- end }}
    env:
      {{- if .Values.common.postgres.postgresCertificateSecret }}
      - name: PGSSLCERT 
        value: /security/postgres/certs/tls.crt
      - name: PGSSLKEY
        value: /security/postgres/certs/tls.key
      {{- end }}
      - name: POSTGRES_HOST
        value: {{ tpl .Values.common.postgres.postgresService . | quote }}
      - name: POSTGRES_DB
        value: {{ tpl .Values.common.postgres.postgresDB . | default "agenticbuilder" | quote }}
      - name: POSTGRES_PORT
        value: {{ tpl .Values.common.postgres.postgresPort . | default "5432" | quote }}
{{- include "agenticbuilder.env.postgres.adminpassword" . | nindent 6 }}
      - name: POSTGRES_USER
        value: {{ tpl .Values.common.postgres.postgresUser . | default "postgres"  | quote }}
      - name: POSTGRES_ADMIN_USER
        value: {{ tpl .Values.common.postgres.adminUser . | default "postgres" | quote }}
    command: ['sh', '-c', 'if ! PGPORT=5432 PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -lqt | cut -d \| -f 1 | grep -qw $POSTGRES_DB; then PGPORT=5432 PGPASSWORD=$POSTGRES_ADMIN_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_ADMIN_USER -c "CREATE DATABASE $POSTGRES_DB WITH OWNER $POSTGRES_USER ENCODING=UTF8 TEMPLATE=template0;"; else echo "Database $POSTGRES_DB already exists with this user $POSTGRES_USER"; fi']  
      {{- end }}
{{- end -}}

{{- define "agenticbuilder.replace.dash.percentdash" -}}
{{- replace "-" "%-" . -}}
{{- end -}}

{{- define "agenticbuilder.hclauthorization.env" -}}
{{- $root := . }}
{{- $unofullname := include "uno.fullname" . }}
{{- $ctx := merge (dict "unofullname" $unofullname) . }}
{{- if .Values.authorization.certs }}
{{- $idx := 0 }}
{{- range $key, $value := .Values.authorization.certs }}
- name: {{ $key }}
  value: /authcert/{{ tpl (lower $value) $ctx }}_{{ $idx }}.crt
{{- $idx = add $idx 1 }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.hclauthorization.volume.mount" -}}
{{- $root := . }}
{{- $unofullname := include "uno.fullname" . }}
{{- $ctx := merge (dict "unofullname" $unofullname) . }}
{{- if .Values.authorization.certs }}
{{- $idx := 0 }}
{{- range $key, $value := .Values.authorization.certs }}
- name: {{ tpl (lower $value) $ctx }}-cert-volume
  mountPath: /authcert/{{ tpl (lower $value) $ctx }}_{{ $idx }}.crt
  subPath: {{ tpl (lower $value) $ctx }}.crt
  readOnly: true
{{- $idx = add $idx 1 }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.hclauthorization.volume" -}}
{{- if .Values.authorization.certs }}
{{- $root := . }}
{{- $unofullname := include "uno.fullname" . }}
{{- $ctx := merge (dict "unofullname" $unofullname) . }}
{{- $seen := dict }}
{{- range $key, $value := .Values.authorization.certs }}
  {{- $val := tpl (lower $value) $ctx }}
  {{- if not (hasKey $seen $val) }}
- name: {{ $val }}-cert-volume
  secret:
    defaultMode: 0644
    secretName: {{ tpl (toString $value) $ctx | quote }}
    items:
    - key: tls.crt
      path: {{ $val }}.crt
  {{- $_ := set $seen $val true }}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "agenticbuilder.additionalCAs.volume" -}}
{{- range .Values.certificates.additionalCASecrets -}}
- name: {{ tpl . $}}-cert-volume
  secret:
    defaultMode: 0664
    secretName: {{ tpl . $ | quote }}
    items:
    - key: tls.crt
      path: {{ tpl . $}}.crt
{{- end }}
{{- end -}}

{{- define "agenticbuilder.additionalCAs.volumeMounts" -}}
{{- range .Values.certificates.additionalCASecrets }}
- name: {{ tpl . $}}-cert-volume
  mountPath: /ca/{{ tpl . $ }}
{{- end }}
{{- end -}}
