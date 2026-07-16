#!/usr/bin/env bash
# Refresh Google (gcloud user + ADC), COW kubeconfig, and mai/Claude auth — stale-gated.
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

# --- COW kubeconfig (ml-cow-gke) --------------------------------------------
# kubectl mints cluster tokens via the gcloud exec-helper, so this runs AFTER
# the gcloud refresh above. Prompt Security MITMs HTTPS on this machine, so the
# NO_PROXY bypass to the cluster endpoint is mandatory (else x509). Probe the
# cluster; only re-fetch the exec-helper entry when it fails.
COW_NO_PROXY="34.63.170.126"
if NO_PROXY="${COW_NO_PROXY},${NO_PROXY:-}" no_proxy="${COW_NO_PROXY},${no_proxy:-}" \
  kubectl get ns argo -o name >/dev/null 2>&1; then
  echo "kubectl: ml-cow-gke reachable — skipping"
else
  echo "kubectl: stale/unreachable — refreshing credentials"
  gcloud container clusters get-credentials ml-cow-gke --region us-central1 --project ml-dev-a7b7
fi

# --- mai / Claude ------------------------------------------------------------
# Re-auth if logged out, or if the token expires within BUFFER seconds.
BUFFER=300
if mai_status=$(mai auth status 2>/dev/null); then
  exp=$(printf '%s\n' "$mai_status" | sed -n 's/^Token expires: //p')
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
