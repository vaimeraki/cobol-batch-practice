# Traitement batch bancaire de fin de journée (COBOL)

Petit projet COBOL qui reproduit le **traitement de fin de journée** d'une banque : chaque nuit, sur le mainframe, des programmes batch reprennent toutes les transactions du jour, rejettent les lignes invalides, les trient par compte, calculent les totaux et éditent un rapport.

Le projet tourne sur un ordinateur normal avec **GnuCOBOL** (compilateur COBOL libre). Un script Bash joue le rôle d'un **JCL** : il enchaîne les étapes, affecte les fichiers et contrôle les codes retour.

![CI](https://github.com/vaimeraki/cobol-batch-practice/actions/workflows/build.yml/badge.svg)

## Le job en un coup d'œil

```
 data/transactions.txt
          │
          ▼
 ┌──────────────────┐        output/rejets.txt
 │ STEP01  VALIDE   │──────► (lignes rejetées + code motif)
 │ contrôle         │
 └──────────────────┘
          │ work/transactions_valides.txt
          ▼
 ┌──────────────────┐
 │ STEP02  TRI      │  SORT par numéro de compte
 └──────────────────┘
          │ work/transactions_triees.txt
          ▼
 ┌──────────────────┐
 │ STEP03  RAPPORT  │──────► output/rapport.txt
 │ rupture/compte   │        (total par compte + total général)
 └──────────────────┘
```

| Étape | Programme | Rôle | Notions COBOL |
|---|---|---|---|
| STEP01 | `src/VALIDE.cbl` | Contrôle chaque transaction et sépare les valides des rejets | fichiers séquentiels, `FILE STATUS`, `REDEFINES`, `EVALUATE`, test `NUMERIC` |
| STEP02 | `src/TRI.cbl` | Trie les transactions valides par compte | `SORT ... USING ... GIVING`, `SD`, `SORT-RETURN` |
| STEP03 | `src/RAPPORT.cbl` | Édite le rapport : sous-total par compte et total général | rupture de contrôle (*control break*), zones d'édition, `DECIMAL-POINT IS COMMA` |
| Job | `jcl/FINJOUR.sh` | Compile et enchaîne les étapes comme un JCL | variables `DD_xxx` ≈ cartes DD, contrôle du RC, ABEND |

## Format des fichiers

**Transaction (entrée)** : 13 caractères, sans séparateur.

| Positions | Champ | Format |
|---|---|---|
| 1–6 | Numéro de compte | `ACCnnn` |
| 7–13 | Montant | `9(5)V99` : les 2 derniers chiffres sont les centimes |

Exemple : `ACC0010012550` = compte ACC001, montant 125,50 €.

**Codes motif de rejet**

| Code | Motif |
|---|---|
| 01 | Compte manquant |
| 02 | Compte invalide (format attendu `ACCnnn`) |
| 03 | Montant non numérique |
| 04 | Montant nul |

## Lancer le projet

1. Installer GnuCOBOL
   - Linux / WSL : `sudo apt install gnucobol`
   - Mac : `brew install gnucobol`
2. Lancer le job :
   ```bash
   ./jcl/FINJOUR.sh                      # fichier par défaut : data/transactions.txt
   ./jcl/FINJOUR.sh mon_fichier.txt      # ou un autre fichier
   ```
3. Lancer les tests :
   ```bash
   ./tests/run_tests.sh
   ```

## Résultat sur le jeu de données fourni

15 transactions lues, 10 valides, 5 rejetées.

`output/rapport.txt`
```
============================================================
 TRAITEMENT DE FIN DE JOURNEE            DATE : 23/10/2026
 RAPPORT DES TOTAUX PAR COMPTE
============================================================
 COMPTE     NB OPERATIONS           MONTANT (EUR)
 ------     -------------        ----------------
 ACC001                 3                  633,49
 ACC002                 2                1 034,99
 ACC003                 2                  539,75
 ACC004                 1                  200,00
 ACC005                 2                2 512,50
 ------     -------------        ----------------
 TOTAL GENERAL         10                4 920,73
 COMPTES TRAITES        5
============================================================
```

`output/rejets.txt`
```
      0002500 01 COMPTE MANQUANT
ACC00400015A0 03 MONTANT NON NUMERIQUE
ACC0030000000 04 MONTANT NUL
XYZ1230001000 02 COMPTE INVALIDE
ACC003        03 MONTANT NON NUMERIQUE
```

Résumé du job (comme le compte rendu d'exécution d'un JCL) :
```
STEP       PGM        RC
STEP00     COBC       0
STEP01     VALIDE     4     <- avertissement : des rejets existent, le job continue
STEP02     TRI        0
STEP03     RAPPORT    0
```

## Codes retour

| RC | Signification | Effet sur le job |
|---|---|---|
| 0 | Traitement normal | continue |
| 4 | Avertissement (rejets présents) | continue |
| 12 | Erreur fichier (ouverture impossible, fichier absent) | arrêt (ABEND) |
| 16 | Échec du tri | arrêt (ABEND) |

## Correspondance avec un vrai mainframe

| Ce projet | Sur mainframe IBM z/OS |
|---|---|
| Script `jcl/FINJOUR.sh` | JCL soumis au JES |
| `export DD_TRANSIN=...` | carte `//TRANSIN DD DSN=...` |
| Fichiers texte séquentiels | fichiers séquentiels / VSAM |
| `cobc -x` | compilation + link-edit |
| Contrôle `RC > 4` | paramètre `COND` / `IF RC` |
| `output/FINJOUR.log` | sortie SYSOUT du job |

## Structure du dépôt

```
cobol-batch-practice/
├── src/          programmes COBOL (VALIDE, TRI, RAPPORT)
├── jcl/          FINJOUR.sh : enchaînement des étapes
├── data/         transactions du jour (jeu de test)
├── tests/        tests de non-régression + résultats attendus
└── .github/      intégration continue (compile et teste à chaque push)
```

## Pistes d'évolution

- Mettre à jour un fichier de soldes clients (fichier maître) à partir des transactions.
- Ajouter un type d'opération (crédit / débit).
- Passer le fichier des comptes en fichier indexé (équivalent VSAM KSDS).

---
Auteur : Vaishnavi Jagtap · projet personnel de préparation à la formation développeur grand système (COBOL).
