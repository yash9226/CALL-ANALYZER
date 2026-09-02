#!/usr/bin/env bash
# Creates deepkakadiya7/CALL-ANALYZER and pushes. Run AFTER authenticating:
#   gh auth login          (choose GitHub.com > HTTPS > browser, sign in as deepkakadiya7)
# then:
#   bash scripts/push_to_github.sh
set -euo pipefail

REPO="CALL-ANALYZER"
OWNER="deepkakadiya7"

ACTIVE=$(gh api user --jq .login)
if [ "$ACTIVE" != "$OWNER" ]; then
  echo "Active gh account is '$ACTIVE', expected '$OWNER'."
  echo "Run:  gh auth switch --user $OWNER   (or: gh auth login)"
  exit 1
fi

gh repo create "$OWNER/$REPO" \
  --public \
  --source=. \
  --remote=origin \
  --description "AI-powered customer support call intelligence platform. Configurable hierarchical quality framework, multi-agent evaluation pipeline, explainable per-criterion scoring, and a hybrid RAG chatbot." \
  --push

echo
echo "Pushed: https://github.com/$OWNER/$REPO"
