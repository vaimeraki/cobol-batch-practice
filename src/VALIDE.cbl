      *================================================================
      * PROGRAMME : VALIDE
      * ETAPE 1 DU JOB FINJOUR - CONTROLE DES TRANSACTIONS DU JOUR
      *
      * Lit les transactions du jour, controle chaque enregistrement
      * et les repartit en deux fichiers :
      *   - VALIDES : transactions correctes (pour l'etape de tri)
      *   - REJETS  : transactions rejetees avec un code motif
      *
      * Fichiers logiques (affectes par le job, comme des DD en JCL) :
      *   TRANSIN  (entree)  VALIDES (sortie)  REJETS (sortie)
      *
      * Codes motif de rejet :
      *   01 Compte manquant
      *   02 Compte invalide (format attendu ACCnnn)
      *   03 Montant non numerique
      *   04 Montant nul
      *
      * Code retour : 0 = OK, 4 = rejets presents, 12 = erreur fichier
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. VALIDE.
       AUTHOR. VAISHNAVI JAGTAP.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE ASSIGN TO "TRANSIN"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-TRANS.
           SELECT VALID-FILE ASSIGN TO "VALIDES"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-VALID.
           SELECT REJET-FILE ASSIGN TO "REJETS"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-REJET.

       DATA DIVISION.
       FILE SECTION.
       FD  TRANS-FILE.
       01  TRANS-REC.
           05 TR-ACCOUNT.
              10 TR-ACC-PREFIX     PIC X(3).
              10 TR-ACC-NUM        PIC X(3).
           05 TR-AMOUNT-X          PIC X(7).
           05 TR-AMOUNT REDEFINES TR-AMOUNT-X
                                   PIC 9(5)V99.

       FD  VALID-FILE.
       01  VALID-REC               PIC X(13).

       FD  REJET-FILE.
       01  REJET-REC.
           05 RJ-DATA              PIC X(13).
           05 FILLER               PIC X.
           05 RJ-CODE              PIC XX.
           05 FILLER               PIC X.
           05 RJ-LIBELLE           PIC X(30).

       WORKING-STORAGE SECTION.
       01  FS-TRANS                PIC XX.
       01  FS-VALID                PIC XX.
       01  FS-REJET                PIC XX.
       01  WS-EOF                  PIC X VALUE "N".
           88 FIN-FICHIER                VALUE "Y".
       01  WS-CODE                 PIC XX.
       01  WS-LIBELLE              PIC X(30).
       01  WS-COMPTEURS.
           05 WS-NB-LUS            PIC 9(5) VALUE 0.
           05 WS-NB-VALIDES        PIC 9(5) VALUE 0.
           05 WS-NB-REJETS         PIC 9(5) VALUE 0.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           PERFORM 1000-OUVERTURE
           PERFORM 2000-LECTURE
           PERFORM UNTIL FIN-FICHIER
               PERFORM 3000-CONTROLE
               PERFORM 2000-LECTURE
           END-PERFORM
           PERFORM 9000-FERMETURE
           STOP RUN.

       1000-OUVERTURE.
           OPEN INPUT TRANS-FILE
           IF FS-TRANS NOT = "00"
               DISPLAY "VALIDE : ERREUR OUVERTURE TRANSIN, STATUS "
                       FS-TRANS
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT VALID-FILE
           OPEN OUTPUT REJET-FILE
           IF FS-VALID NOT = "00" OR FS-REJET NOT = "00"
               DISPLAY "VALIDE : ERREUR OUVERTURE FICHIERS DE SORTIE"
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF.

       2000-LECTURE.
           READ TRANS-FILE
               AT END SET FIN-FICHIER TO TRUE
               NOT AT END ADD 1 TO WS-NB-LUS
           END-READ.

       3000-CONTROLE.
           MOVE SPACES TO WS-CODE WS-LIBELLE
           EVALUATE TRUE
               WHEN TR-ACCOUNT = SPACES
                   MOVE "01" TO WS-CODE
                   MOVE "COMPTE MANQUANT" TO WS-LIBELLE
               WHEN TR-ACC-PREFIX NOT = "ACC"
                 OR TR-ACC-NUM NOT NUMERIC
                   MOVE "02" TO WS-CODE
                   MOVE "COMPTE INVALIDE" TO WS-LIBELLE
               WHEN TR-AMOUNT-X NOT NUMERIC
                   MOVE "03" TO WS-CODE
                   MOVE "MONTANT NON NUMERIQUE" TO WS-LIBELLE
               WHEN TR-AMOUNT = ZERO
                   MOVE "04" TO WS-CODE
                   MOVE "MONTANT NUL" TO WS-LIBELLE
           END-EVALUATE

           IF WS-CODE = SPACES
               WRITE VALID-REC FROM TRANS-REC
               ADD 1 TO WS-NB-VALIDES
           ELSE
               MOVE SPACES     TO REJET-REC
               MOVE TRANS-REC  TO RJ-DATA
               MOVE WS-CODE    TO RJ-CODE
               MOVE WS-LIBELLE TO RJ-LIBELLE
               WRITE REJET-REC
               ADD 1 TO WS-NB-REJETS
           END-IF.

       9000-FERMETURE.
           CLOSE TRANS-FILE VALID-FILE REJET-FILE
           DISPLAY "VALIDE : LUS     = " WS-NB-LUS
           DISPLAY "VALIDE : VALIDES = " WS-NB-VALIDES
           DISPLAY "VALIDE : REJETS  = " WS-NB-REJETS
           IF WS-NB-REJETS > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
