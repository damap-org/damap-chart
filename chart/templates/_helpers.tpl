{{- /*
Determine the database password for DAMAP.
If a password is provided in the values, use it. Otherwise, check for a Kubernetes Secret named "damap" in the same namespace.
If the Secret exists and contains a key "dbPassword", use that value.
If neither is available, generate a random 32-character alphanumeric password.
*/ }}
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
Determine the CNPG secret name for credentials.
If a custom secret name is provided in the values, use it; otherwise, default to "<clusterName>-app".
*/}}
{{- define "cnpgSecretName" }}
  {{- if .Values.postgres.cnpg.secret.name }}
    {{- .Values.postgres.cnpg.secret.name }}
  {{- else }}
    {{- printf "%s-app" .Values.postgres.cnpg.clusterName }}
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
