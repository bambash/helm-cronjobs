{{/* vim: set filetype=mustache: */}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cronjobs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cronjobs.labels" -}}
helm.sh/chart: {{ include "cronjobs.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Expand the release name of the chart.
*/}}
{{- define "cronjobs.releaseName" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create payload for any image pull secret.
One kube secret will be created containing all the auths
and will be shared by all the job pods requiring it.
*/}}
{{- define "cronjobs.imageSecrets" -}}
    {{- $secrets := dict -}}
    {{- range $jobname, $job := .Values.jobs -}}
        {{- if hasKey $job "imagePullSecrets" -}}
            {{- range $ips := $job.imagePullSecrets -}}
                {{- $_ := set $secrets $ips.registry (dict "username" $ips.username "password" $ips.password "email" $ips.email "auth" (printf "%s:%s" $ips.username $ips.password | b64enc)) -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if gt (len $secrets) 0 -}}
        {{- $auth := dict "auths" $secrets -}}
        {{/* Emit secret content as base64 */}}
        {{- print ($auth | toJson | b64enc) -}}
    {{- else -}}
        {{/* There are no secrets*/}}
        {{- print "" -}}
    {{- end -}}
{{- end -}}