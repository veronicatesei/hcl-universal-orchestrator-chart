
{{- define "enable.testprereq" -}}
{{- if ((.Values).global).sofySolutionContext }}
{{- printf "false"  -}}
{{- else if ((.Values).global).enableTestPrereq }}
{{- printf "true"  -}}
{{- else -}}
{{- printf "false"  -}}
{{- end -}}

{{- end -}}


