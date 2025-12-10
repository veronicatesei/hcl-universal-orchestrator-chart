{{/* Generate the name of the service */}}
{{- define "rag.serviceName" -}}
{{- printf "%s-%s" .Release.Name .Values.service.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate the name of the deployment */}}
{{- define "rag.deploymentName" -}}
{{- printf "%s-%s" .Release.Name (default "rag-service" .Values.app.name) | trunc 63 | trimSuffix "-" -}}
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
{{- if and .Values.global.cloudCredentials .Values.global.cloudCredentials.gcp.serviceFile -}}
{{ .Values.global.cloudCredentials.gcp.serviceFile | quote }}
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

{{- define "rag.commonssl.volumeMounts.definition" -}}
{{ include "sltCommon.commonssl.volumeMounts.postgres" . }}
{{- end -}}

{{- define "rag.commonssl.volume.definition" -}}
{{- include "sltCommon.commonssl.volume.postgres" . }}
{{- end -}}

{{- define "rag.commonssl.env.definition" -}}
{{ include "sltCommon.commonssl.env.postgres" . }}
{{- end -}}

{{- define "common.postgres.fullname" -}}
{{- printf "%s-pg-db" .Release.Name | trunc 21 | trimSuffix "-" -}}
{{- end -}}