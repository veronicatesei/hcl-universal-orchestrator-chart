{{- define "common.dwc.hidden.env" -}}
{{- end -}}


{{- define "common.dwc.hidden.secret.volumes" -}}
{{- end -}}


{{- define "common.dwc.hidden.secret.volumes.mounts" -}}
{{- end -}}


{{- define "wa.imageRepoPlugin" -}}
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