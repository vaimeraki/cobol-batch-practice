#!/usr/bin/env bash
#=====================================================================
# JOB FINJOUR - Traitement batch bancaire de fin de journee
#
# Ce script joue le role d'un JCL sur mainframe :
#   - chaque etape (STEP) lance un programme COBOL ;
#   - les fichiers sont affectes par des variables DD_xxx,
#     comme les cartes DD d'un JCL ;
#   - le code retour (RC) de chaque etape est controle :
#       RC 0 = OK, RC 4 = avertissement (on continue),
#       RC > 4 = erreur -> le job s'arrete (ABEND).
#
# Usage : ./jcl/FINJOUR.sh [fichier_transactions]
#=====================================================================
set -u
cd "$(dirname "$0")/.."

INPUT="${1:-data/transactions.txt}"
MAXRC_OK=4
mkdir -p bin work output
LOG=output/FINJOUR.log
: > "$LOG"
SUMMARY=()

log() { echo "$*" | tee -a "$LOG"; }

# Termine le job en erreur
abend() {
    log "*** JOB FINJOUR ABEND : $1 ***"
    print_summary
    exit 12
}

print_summary() {
    log ""
    log "---------------- RESUME DU JOB FINJOUR ----------------"
    log "$(printf '%-10s %-10s %s' STEP PGM RC)"
    for line in "${SUMMARY[@]}"; do log "$line"; done
    log "--------------------------------------------------------"
}

# run_step NOM_STEP PROGRAMME
run_step() {
    local step=$1 pgm=$2 rc
    log ""
    log ">>> $step : EXEC PGM=$pgm"
    ./bin/"$pgm" 2>&1 | tee -a "$LOG"
    rc=${PIPESTATUS[0]}
    SUMMARY+=("$(printf '%-10s %-10s %s' "$step" "$pgm" "$rc")")
    log "<<< $step : RC=$rc"
    if [ "$rc" -gt "$MAXRC_OK" ]; then
        abend "$step termine avec RC=$rc"
    fi
}

log "=== JOB FINJOUR - DEBUT $(date '+%d/%m/%Y %H:%M:%S') ==="

#--- STEP00 : compilation des programmes ----------------------------
log ""
log ">>> STEP00 : COMPILATION"
for pgm in VALIDE TRI RAPPORT; do
    if ! cobc -x -o "bin/$pgm" "src/$pgm.cbl" >>"$LOG" 2>&1; then
        SUMMARY+=("$(printf '%-10s %-10s %s' STEP00 "$pgm" 8)")
        abend "erreur de compilation de $pgm (voir $LOG)"
    fi
    log "    $pgm compile"
done
SUMMARY+=("$(printf '%-10s %-10s %s' STEP00 COBC 0)")

[ -f "$INPUT" ] || abend "fichier d'entree introuvable : $INPUT"

#--- STEP01 : controle des transactions ------------------------------
export DD_TRANSIN="$INPUT"
export DD_VALIDES=work/transactions_valides.txt
export DD_REJETS=output/rejets.txt
run_step STEP01 VALIDE

#--- STEP02 : tri par compte -----------------------------------------
export DD_VALIDES=work/transactions_valides.txt
export DD_TRIES=work/transactions_triees.txt
export DD_SORTWK=work/sortwk.tmp
run_step STEP02 TRI

#--- STEP03 : edition du rapport -------------------------------------
export DD_TRIES=work/transactions_triees.txt
export DD_RAPPORT=output/rapport.txt
run_step STEP03 RAPPORT

print_summary
log "=== JOB FINJOUR - FIN NORMALE $(date '+%d/%m/%Y %H:%M:%S') ==="
log "Rapport : output/rapport.txt   Rejets : output/rejets.txt"
exit 0
