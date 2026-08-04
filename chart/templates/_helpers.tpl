{{- /*
Determine the database password for DAMAP.
If a password is provided in the values, use it.
Otherwise, check for a Kubernetes Secret named "damap" in the same namespace.
If the Secret exists and contains a key "dbPassword", use that value.
If neither is available, generate a random 32-character alphanumeric password.
*/}}
{{- define "damapDatabasePassword" }}
  {{- if .Values.damap.dbPassword }}
    {{- .Values.damap.dbPassword }}
  {{- else }}
    {{- $secret := lookup "v1" "Secret" .Release.Namespace "damap" }}
    {{- if and $secret $secret.data (hasKey $secret.data "dbPassword") }}
      {{- index $secret.data "dbPassword" | b64dec }}
    {{- else }}
      {{- randAlphaNum 32 }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
Determine the PostgreSQL host based on the selected mode (simple, external, or cnpg).
*/}}
{{- define "postgresHost" }}
  {{- if eq .Values.postgres.mode "cnpg" }}
    {{- printf "%s-rw" .Values.postgres.cnpg.clusterName }}
  {{- else }}
    {{- .Values.postgres.host }}
  {{- end }}
{{- end }}

{{- /*
Read the CNPG application role name from the existing basic-auth Secret.
*/}}
{{- define "cnpgOwner" }}
  {{- $secretName := include "cnpgSecretName" . }}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName }}

  {{- if and $secret $secret.data (hasKey $secret.data "username") }}
    {{- index $secret.data "username" | b64dec }}
  {{- else }}
    {{- .Values.damap.dbUser }}
  {{- end }}
{{- end }}

{{- /*
Determine the CNPG secret name for credentials.
If a custom secret name is provided in the values, use it; otherwise, default to "<clusterName>-app".
NOTE: This secret will be created by the chart if it does not already exist.
*/}}
{{- define "cnpgSecretName" }}
  {{- if .Values.postgres.cnpg.authSecretName }}
    {{- .Values.postgres.cnpg.authSecretName }}
  {{- else }}
    {{- printf "%s-app" .Values.postgres.cnpg.clusterName }}
  {{- end }}
{{- end }}

{{- /*
Resolve the primary DAMAP database name.
Prefer the value from the "damap" Secret if it exists; otherwise, use the value from the chart's values.
*/}}
{{- define "databaseName" }}
  {{- $secretName := "damap" }}
  {{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName }}

  {{- if and $secret $secret.data (hasKey $secret.data "dbDatabase") }}
    {{- index $secret.data "dbDatabase" | b64dec }}
  {{- else }}
    {{- .Values.damap.dbName }}
  {{- end }}
{{- end }}

{{- /*
Determine if DAMAP and Keycloak share the same host.
If yes, prefix Keycloak paths with /auth to avoid collisions.
*/}}
{{- define "keycloakPath" }}
  {{- $sameHost := eq .Values.keycloak.hostname .Values.damap.hostname }}
  {{- if $sameHost }}
    /auth
  {{- else }}
    /
  {{- end }}
{{- end }}
