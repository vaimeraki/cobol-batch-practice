      *================================================================
      * PROGRAMME : RAPPORT
      * ETAPE 3 DU JOB FINJOUR - EDITION DU RAPPORT DE FIN DE JOURNEE
      *
      * Lit les transactions triees par compte et edite un rapport :
      *   - une ligne par compte (nombre d'operations, total)
      *     -> technique de la "rupture de controle" (control break)
      *   - un total general
      *
      * Fichiers logiques : TRIES (entree)  RAPPORT (sortie)
      *
      * Code retour : 0 = OK, 12 = erreur fichier
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. RAPPORT.
       AUTHOR. VAISHNAVI JAGTAP.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SORTED-FILE ASSIGN TO "TRIES"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-TRIES.
           SELECT REPORT-FILE ASSIGN TO "RAPPORT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-RAPPORT.

       DATA DIVISION.
       FILE SECTION.
       FD  SORTED-FILE.
       01  SORTED-REC.
           05 SR-ACCOUNT           PIC X(6).
           05 SR-AMOUNT            PIC 9(5)V99.

       FD  REPORT-FILE.
       01  REPORT-LINE             PIC X(60).

       WORKING-STORAGE SECTION.
       01  FS-TRIES                PIC XX.
       01  FS-RAPPORT              PIC XX.
       01  WS-EOF                  PIC X VALUE "N".
           88 FIN-FICHIER                VALUE "Y".

       01  WS-COMPTE-COURANT       PIC X(6).
       01  WS-NB-COMPTE            PIC 9(5)    VALUE 0.
       01  WS-TOTAL-COMPTE         PIC 9(7)V99 VALUE 0.
       01  WS-NB-COMPTES           PIC 9(5)    VALUE 0.
       01  WS-NB-GENERAL           PIC 9(5)    VALUE 0.
       01  WS-TOTAL-GENERAL        PIC 9(7)V99 VALUE 0.

       01  WS-DATE-SYS.
           05 WS-AAAA              PIC 9(4).
           05 WS-MM                PIC 99.
           05 WS-JJ                PIC 99.

      *---------------------------- LIGNES DU RAPPORT ------------------
       01  L-SEPARATEUR            PIC X(60) VALUE ALL "=".
       01  L-TITRE.
           05 FILLER               PIC X(41)
              VALUE " TRAITEMENT DE FIN DE JOURNEE".
           05 FILLER               PIC X(7)  VALUE "DATE : ".
           05 L-JJ                 PIC 99.
           05 FILLER               PIC X     VALUE "/".
           05 L-MM                 PIC 99.
           05 FILLER               PIC X     VALUE "/".
           05 L-AAAA               PIC 9(4).
       01  L-SOUS-TITRE            PIC X(60)
              VALUE " RAPPORT DES TOTAUX PAR COMPTE".
       01  L-ENTETE.
           05 FILLER               PIC X(12) VALUE " COMPTE".
           05 FILLER               PIC X(18) VALUE "NB OPERATIONS".
           05 FILLER               PIC X(20)
              VALUE "      MONTANT (EUR)".
       01  L-TIRETS.
           05 FILLER               PIC X(12) VALUE " ------".
           05 FILLER               PIC X(18) VALUE "-------------".
           05 FILLER               PIC X(20)
              VALUE "   ----------------".
       01  L-DETAIL.
           05 FILLER               PIC X     VALUE SPACE.
           05 L-COMPTE             PIC X(6).
           05 FILLER               PIC X(12) VALUE SPACES.
           05 L-NB                 PIC ZZ.ZZ9.
           05 FILLER               PIC X(12) VALUE SPACES.
           05 L-MONTANT            PIC ZBZZZBZZ9,99.
       01  L-TOTAL.
           05 FILLER               PIC X(19) VALUE " TOTAL GENERAL".
           05 L-NB-TOT             PIC ZZ.ZZ9.
           05 FILLER               PIC X(12) VALUE SPACES.
           05 L-MONTANT-TOT        PIC ZBZZZBZZ9,99.
       01  L-NB-COMPTES.
           05 FILLER               PIC X(19) VALUE " COMPTES TRAITES".
           05 L-NB-CPT             PIC ZZ.ZZ9.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-OUVERTURE
           PERFORM 1100-ENTETE
           PERFORM 2000-LECTURE
           IF NOT FIN-FICHIER
               MOVE SR-ACCOUNT TO WS-COMPTE-COURANT
           END-IF
           PERFORM UNTIL FIN-FICHIER
               IF SR-ACCOUNT NOT = WS-COMPTE-COURANT
                   PERFORM 3000-RUPTURE-COMPTE
                   MOVE SR-ACCOUNT TO WS-COMPTE-COURANT
               END-IF
               ADD 1         TO WS-NB-COMPTE
               ADD SR-AMOUNT TO WS-TOTAL-COMPTE
               PERFORM 2000-LECTURE
           END-PERFORM
           IF WS-NB-COMPTE > 0
               PERFORM 3000-RUPTURE-COMPTE
           END-IF
           PERFORM 4000-TOTAL-GENERAL
           PERFORM 9000-FERMETURE
           STOP RUN.

       1000-OUVERTURE.
           OPEN INPUT SORTED-FILE
           IF FS-TRIES NOT = "00"
               DISPLAY "RAPPORT: ERREUR OUVERTURE TRIES, STATUS "
                       FS-TRIES
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT REPORT-FILE
           IF FS-RAPPORT NOT = "00"
               DISPLAY "RAPPORT: ERREUR OUVERTURE RAPPORT, STATUS "
                       FS-RAPPORT
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

       1100-ENTETE.
           MOVE FUNCTION CURRENT-DATE(1:8) TO WS-DATE-SYS
           MOVE WS-JJ   TO L-JJ
           MOVE WS-MM   TO L-MM
           MOVE WS-AAAA TO L-AAAA
           WRITE REPORT-LINE FROM L-SEPARATEUR
           WRITE REPORT-LINE FROM L-TITRE
           WRITE REPORT-LINE FROM L-SOUS-TITRE
           WRITE REPORT-LINE FROM L-SEPARATEUR
           WRITE REPORT-LINE FROM L-ENTETE
           WRITE REPORT-LINE FROM L-TIRETS.

       2000-LECTURE.
           READ SORTED-FILE
               AT END SET FIN-FICHIER TO TRUE
           END-READ.

      *    Rupture de controle : le compte change, on edite le
      *    sous-total du compte precedent et on remet a zero.
       3000-RUPTURE-COMPTE.
           MOVE WS-COMPTE-COURANT TO L-COMPTE
           MOVE WS-NB-COMPTE      TO L-NB
           MOVE WS-TOTAL-COMPTE   TO L-MONTANT
           WRITE REPORT-LINE FROM L-DETAIL
           ADD 1               TO WS-NB-COMPTES
           ADD WS-NB-COMPTE    TO WS-NB-GENERAL
           ADD WS-TOTAL-COMPTE TO WS-TOTAL-GENERAL
           MOVE 0 TO WS-NB-COMPTE
           MOVE 0 TO WS-TOTAL-COMPTE.

       4000-TOTAL-GENERAL.
           MOVE WS-NB-GENERAL    TO L-NB-TOT
           MOVE WS-TOTAL-GENERAL TO L-MONTANT-TOT
           MOVE WS-NB-COMPTES    TO L-NB-CPT
           WRITE REPORT-LINE FROM L-TIRETS
           WRITE REPORT-LINE FROM L-TOTAL
           WRITE REPORT-LINE FROM L-NB-COMPTES
           WRITE REPORT-LINE FROM L-SEPARATEUR.

       9000-FERMETURE.
           CLOSE SORTED-FILE REPORT-FILE
           DISPLAY "RAPPORT: COMPTES   = " WS-NB-COMPTES
           DISPLAY "RAPPORT: OPERATIONS= " WS-NB-GENERAL
           MOVE 0 TO RETURN-CODE.
