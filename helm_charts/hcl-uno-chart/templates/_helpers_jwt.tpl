
{{- define "common.dwc.hidden.secret.volumes" -}}
{{- $fullName := include "fullname" . -}}
- name: config-dwc-jwt-volume
  configMap:
    name: {{ $fullName }}-jwtsso
    items:
    - key: jwtsso.xml
      path: jwtsso.xml
{{- end -}}


{{- define "common.dwc.hidden.secret.volumes.mounts" -}}
{{- $fullName := include "fullname" . -}}
- name: config-dwc-jwt-volume
  mountPath: /home/wauser/wadata/usr/servers/dwcServer/configDropins/overrides/jwtsso.xml
  subPath: jwtsso.xml
{{- end -}}
