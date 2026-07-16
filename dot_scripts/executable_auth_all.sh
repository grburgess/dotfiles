#!/usr/bin/env bash
# Refresh Google (gcloud user + ADC) and mai/Claude auth — only when stale.
# Bound to the `reauth` alias (work profile). Google half reuses cloud_login.sh.
set -u

# --- Google: gcloud user token + ADC ----------------------------------------
# print-access-token silently refreshes if the refresh token is still valid,
# and fails (no browser) once it has TTL'd out — a clean staleness probe.
if gcloud auth print-access-token >/dev/null 2>&1 \
  && gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo "gcloud: creds valid — skipping"
else
  echo "gcloud: stale/expired — re-authenticating"
  source ~/.scripts/cloud_login.sh
fi

# --- mai / Claude ------------------------------------------------------------
# Re-auth if logged out, or if the token expires within BUFFER seconds.
BUFFER=300
if status=$(mai auth status 2>/dev/null); then
  exp=$(printf '%s\n' "$status" | sed -n 's/^Token expires: //p')
  exp_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$exp" +%s 2>/dev/null || echo 0)
  if (( exp_epoch - $(date +%s) > BUFFER )); then
    echo "mai: token valid until ${exp} — skipping"
  else
    echo "mai: token expiring/expired — re-authenticating"
    mai auth login
  fi
else
  echo "mai: not logged in — authenticating"
  mai auth login
fi
