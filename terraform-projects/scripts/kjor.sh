#!/usr/bin/env bash
# =============================================================================
#  scripts/kjor.sh  –  plan, apply eller drift-sjekk for alle stackene
# -----------------------------------------------------------------------------
#  Bruk:
#      bash terraform-projects/scripts/kjor.sh <test|prod> <plan|apply|drift>
#
#  Stackene kjøres i rekkefølgen under. Rekkefølgen betyr noe: plattform leser
#  outputs fra nettverk og data, så de må være rullet ut først.
#
#    plan   Planlegger alle stackene. Fortsetter selv om én feiler.
#    apply  Planlegger og ruller ut, én stack om gangen. Stopper ved første
#           feil – en halvferdig nettverksendring skal ikke få følge av
#           plattform.
#    drift  Som plan, men exit-kode 2 betyr «Azure stemmer ikke med koden».
#
#  Skriver et sammendrag i Markdown til $RAPPORT (standard: rapport.md i
#  terraform-projects/). Workflowene legger det på PR-en eller i jobb-
#  sammendraget.
#
#  Lokalt kjører du som deg selv: `az login` først, og ARM_USE_CLI=true.
# =============================================================================

set -uo pipefail

STACKS="nettverk data plattform"

MILJO="${1:-}"
HANDLING="${2:-}"

case "$MILJO" in test|prod) ;; *) echo "Miljø må være test eller prod" >&2; exit 64 ;; esac
case "$HANDLING" in plan|apply|drift) ;; *) echo "Handling må være plan, apply eller drift" >&2; exit 64 ;; esac

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
ROT="$(pwd)"
RAPPORT="${RAPPORT:-$ROT/rapport.md}"
: > "$RAPPORT"

resultat=0   # 0 = ingen endringer, 2 = endringer/drift, 1 = feil

for stack in $STACKS; do
  echo "::group::$stack ($MILJO)"
  cd "$ROT/stacks/$stack" || exit 1

  if ! terraform init -input=false -reconfigure \
        -backend-config="$ROT/shared/backend.hcl" \
        -backend-config="key=fjellbekk/$MILJO/$stack.tfstate" > init.log 2>&1; then
    cat init.log
    echo "::endgroup::"
    echo "### ❌ $stack – init feilet" >> "$RAPPORT"
    resultat=1
    [ "$HANDLING" = apply ] && break || continue
  fi

  VARFIL="$ROT/config/$MILJO/$stack.tfvars"

  if [ "$HANDLING" = apply ]; then
    # Vent på låsen i stedet for å feile hvis en annen kjøring holder den.
    if terraform plan -input=false -lock-timeout=5m -var-file="$VARFIL" -out=tfplan -no-color > plan.txt 2>&1; then
      terraform apply -input=false -lock-timeout=5m -no-color tfplan >> plan.txt 2>&1
      kode=$?
    else
      kode=1
    fi
  else
    # Planen skriver ingenting, så den skal ikke ta låsen fra en utrulling.
    terraform plan -input=false -lock=false -detailed-exitcode -var-file="$VARFIL" -no-color > plan.txt 2>&1
    kode=$?
  fi

  cat plan.txt
  echo "::endgroup::"

  sammendrag="$(grep -E '^(Plan:|No changes|Apply complete)' plan.txt | head -2 | tr '\n' ' ')"
  case $kode in
    0) ikon="✅" ;;
    2) ikon="🟡"; [ $resultat -eq 0 ] && resultat=2 ;;
    *) ikon="❌"; resultat=1; sammendrag="feilet – se loggen" ;;
  esac
  [ "$HANDLING" = drift ] && [ $kode -eq 2 ] && ikon="⚠️" && sammendrag="DRIFT – $sammendrag"

  {
    echo "### $ikon $stack – ${sammendrag:-ingen oppsummering}"
    echo
    echo "<details><summary>Hele utskriften</summary>"
    echo
    echo '```text'
    cat plan.txt
    echo '```'
    echo
    echo "</details>"
    echo
  } >> "$RAPPORT"

  rm -f init.log
  [ "$HANDLING" = apply ] && [ $kode -ne 0 ] && break
done

exit $resultat
