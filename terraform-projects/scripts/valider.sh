#!/usr/bin/env bash
# =============================================================================
#  scripts/valider.sh  –  de fire offline-kontrollene
# -----------------------------------------------------------------------------
#  Samme skript lokalt og i CI (jobben «kodekontroll» i ci.yml):
#
#      bash terraform-projects/scripts/valider.sh
#
#  Kjører alle kontrollene selv om en tidlig feiler, så du ser alle funnene på
#  én gang. Reglene står i .tflint.hcl og .checkov.yaml, ikke her.
# =============================================================================

STACKS="nettverk data plattform"

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

feilet=""

kontroll() {
  echo
  echo "=== $1 ==="
}

kontroll "1/4 terraform fmt"
if ! terraform fmt -check -recursive; then
  echo "→ Rett med: terraform fmt -recursive"
  feilet="$feilet fmt"
fi

kontroll "2/4 terraform validate"
for stack in $STACKS; do
  echo "--- $stack"
  if ! (cd "stacks/$stack" &&
        terraform init -backend=false -input=false > /dev/null &&
        terraform validate -no-color); then
    feilet="$feilet validate($stack)"
  fi
done

kontroll "3/4 TFLint"
tflint --init > /dev/null
if ! tflint --recursive --config "$(pwd)/.tflint.hcl"; then
  feilet="$feilet tflint"
fi

kontroll "4/4 Checkov"
if ! checkov -d .; then
  feilet="$feilet checkov"
fi

echo
if [ -z "$feilet" ]; then
  echo "✅ Alle kontrollene er grønne."
  exit 0
else
  echo "❌ Feilet:$feilet"
  exit 1
fi
