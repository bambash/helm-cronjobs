{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart (respects nameOverride).
*/}}
{{- define "cronjobs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name + version string used by the helm.sh/chart label.
*/}}
{{- define "cronjobs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the release name (respects nameOverride).
*/}}
{{- define "cronjobs.releaseName" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels – applied to every resource.
Includes the chart version label which changes on each release.
Do NOT use these in selector / matchLabels (use cronjobs.selectorLabels instead).
*/}}
{{- define "cronjobs.labels" -}}
helm.sh/chart: {{ include "cronjobs.chart" . }}
{{ include "cronjobs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels – stable subset without the chart version.
Use these in selector / matchLabels blocks and NetworkPolicy podSelectors.
*/}}
{{- define "cronjobs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cronjobs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Build the base64-encoded .dockerconfigjson for the shared image pull secret.
Iterates all jobs that carry imagePullSecrets and merges their auth entries
into a single Secret that is mounted by every pod that references an
imagePullSecrets registry.
*/}}
{{- define "cronjobs.imageSecrets" -}}
{{- $secrets := dict -}}
{{- range $jobname, $job := .Values.jobs -}}
  {{- if hasKey $job "imagePullSecrets" -}}
    {{- range $ips := $job.imagePullSecrets -}}
      {{- $userInfo := dict
            "username" $ips.username
            "password" $ips.password
            "auth"     (printf "%s:%s" $ips.username $ips.password | b64enc) -}}
      {{- if hasKey $ips "email" -}}
        {{- $_ := set $userInfo "email" $ips.email -}}
      {{- end -}}
      {{- $_ := set $secrets $ips.registry $userInfo -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if gt (len $secrets) 0 -}}
  {{- dict "auths" $secrets | toJson | b64enc -}}
{{- else -}}
  {{- "" -}}
{{- end -}}
{{- end -}}
