      *================================================================
      * PROGRAMME : TRI
      * ETAPE 2 DU JOB FINJOUR - TRI DES TRANSACTIONS PAR COMPTE
      *
      * Trie les transactions valides par numero de compte avec
      * l'instruction SORT de COBOL. L'ordre d'arrivee est conserve
      * pour un meme compte (WITH DUPLICATES IN ORDER).
      *
      * Fichiers logiques : VALIDES (entree)  TRIES (sortie)
      *
      * Code retour : 0 = OK, 16 = echec du tri
      *================================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRI.
       AUTHOR. VAISHNAVI JAGTAP.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT VALID-FILE ASSIGN TO "VALIDES"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT SORTED-FILE ASSIGN TO "TRIES"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT SORT-WORK ASSIGN TO "SORTWK".

       DATA DIVISION.
       FILE SECTION.
       FD  VALID-FILE.
       01  VALID-REC               PIC X(13).

       FD  SORTED-FILE.
       01  SORTED-REC              PIC X(13).

       SD  SORT-WORK.
       01  SW-REC.
           05 SW-ACCOUNT           PIC X(6).
           05 SW-AMOUNT            PIC 9(5)V99.

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           SORT SORT-WORK
               ON ASCENDING KEY SW-ACCOUNT
               WITH DUPLICATES IN ORDER
               USING VALID-FILE
               GIVING SORTED-FILE

           IF SORT-RETURN NOT = 0
               DISPLAY "TRI    : ECHEC DU TRI, SORT-RETURN = "
                       SORT-RETURN
               MOVE 16 TO RETURN-CODE
           ELSE
               DISPLAY "TRI    : TRI PAR COMPTE TERMINE"
               MOVE 0 TO RETURN-CODE
           END-IF
           STOP RUN.
