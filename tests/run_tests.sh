#!/usr/bin/env bash
# Tests de non-regression du job FINJOUR
set -u
cd "$(dirname "$0")/.."
FAIL=0
ok()  { echo "  [OK]    $1"; }
ko()  { echo "  [ECHEC] $1"; FAIL=1; }

echo "TEST 1 : job complet sur le jeu de donnees de reference"
./jcl/FINJOUR.sh data/transactions.txt >/dev/null
[ $? -eq 0 ] && ok "le job se termine normalement" || ko "le job aurait du se terminer normalement"
diff -q output/rejets.txt tests/expected/rejets.txt >/dev/null \
    && ok "fichier des rejets conforme" || ko "fichier des rejets different"
grep -v 'DATE :' output/rapport.txt | diff -q - tests/expected/rapport_sans_date.txt >/dev/null \
    && ok "rapport conforme" || ko "rapport different"

echo "TEST 2 : fichier d'entree absent -> le job doit s'arreter (ABEND)"
./jcl/FINJOUR.sh data/inexistant.txt >/dev/null
[ $? -ne 0 ] && ok "ABEND detecte" || ko "le job aurait du s'arreter"

echo "TEST 3 : fichier sans aucune transaction valide"
TMP=$(mktemp); printf '%s\n' 'XYZ0010001000' '      0000100' > "$TMP"
./jcl/FINJOUR.sh "$TMP" >/dev/null
[ $? -eq 0 ] && ok "le job se termine (RC 4 accepte)" || ko "echec inattendu"
grep -Eq 'TOTAL GENERAL +0 +0,00' output/rapport.txt \
    && ok "total general a zero" || ko "total general incorrect"
[ "$(wc -l < output/rejets.txt)" -eq 2 ] && ok "2 rejets" || ko "nombre de rejets incorrect"
rm -f "$TMP"

# Remet les sorties de reference en place
./jcl/FINJOUR.sh >/dev/null
echo
[ $FAIL -eq 0 ] && echo "TOUS LES TESTS SONT OK" || echo "DES TESTS ONT ECHOUE"
exit $FAIL
