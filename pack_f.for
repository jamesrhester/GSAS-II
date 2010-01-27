      SUBROUTINE PACK_F(N,CMPR,M,IMG)

Cf2py intent(in) N
Cf2py intent(in) CMPR
Cf2py depend(N) CMPR
Cf2py intent(in) M
Cf2py intent(in,out) IMG
Cf2py depend(M) IMG

      IMPLICIT NONE
      INTEGER*4 IPOS,ISIZE,BITDECODE(0:7),SETBITS(0:32),IN,N,M,BITNUM
      INTEGER*4 PIXEL,SPILLBITS,USEDBITS,VALIDS,WINDOW,TOTAL,IR
      INTEGER*4 IMG(0:M-1,0:M-1),NEXTINT,I      
      INTEGER*4 SPILL,ROW,COL,PIXNUM,MM1
      INTEGER*2 TMP
      CHARACTER*(*) CMPR(0:N-1)
      DATA BITDECODE /0,4,5,6,7,8,16,32/
      DATA SETBITS /Z'00000000',Z'00000001',Z'00000003',Z'00000007',
     1  Z'0000000F',Z'0000001F',Z'0000003F',Z'0000007F',Z'000000FF',
     1  Z'000001FF',Z'000003FF',Z'000007FF',Z'00000FFF',Z'00001FFF',
     1  Z'00003FFF',Z'00007FFF',Z'0000FFFF',Z'0001FFFF',Z'0003FFFF',
     1  Z'0007FFFF',Z'000FFFFF',Z'001FFFFF',Z'003FFFFF',Z'007FFFFF',
     1  Z'00FFFFFF',Z'01FFFFFF',Z'03FFFFFF',Z'07FFFFFF',Z'0FFFFFFF',
     1  Z'1FFFFFFF',Z'3FFFFFFF',Z'7FFFFFFF',Z'FFFFFFFF'/

      PIXEL = 0
      SPILLBITS = 0
      SPILL = 0
      USEDBITS = 0
      VALIDS = 0
      WINDOW = 0
      ROW = 0
      COL = 0
      TOTAL = M**2
      MM1 = M-1
      IN = 0
      DO WHILE (PIXEL .LT. TOTAL)
        IF (VALIDS .LT. 6) THEN
          IF (SPILLBITS .GT. 0) THEN
            WINDOW = IOR(WINDOW,ISHFT(SPILL,VALIDS))
            VALIDS = VALIDS + SPILLBITS
            SPILLBITS = 0
          ELSE
            SPILL = ICHAR(CMPR(IN))
            IN = IN+1
            SPILLBITS = 8
          END IF
        ELSE
          PIXNUM = ISHFT(1,IAND(WINDOW,SETBITS(3)))
          WINDOW = ISHFT(WINDOW,-3)
          BITNUM = BITDECODE(IAND(WINDOW,SETBITS(3)))
          WINDOW = ISHFT(WINDOW,-3)
          VALIDS = VALIDS-6
          DO WHILE ( (PIXNUM .GT. 0) .AND. (PIXEL .LT. TOTAL) )
            IF ( VALIDS .LT. BITNUM ) THEN
              IF ( SPILLBITS .GT. 0 ) THEN
                WINDOW = IOR(WINDOW,ISHFT(SPILL,VALIDS))
                IF ( (32-VALIDS) .GT. SPILLBITS ) THEN
                  VALIDS = VALIDS + SPILLBITS
                  SPILLBITS = 0
                ELSE
                  USEDBITS = 32-VALIDS
                  SPILL = ISHFT(SPILL,-USEDBITS)
                  SPILLBITS = SPILLBITS-USEDBITS
                  VALIDS = 32
                END IF
              ELSE
                SPILL = ICHAR(CMPR(IN))
                IN = IN+1
                SPILLBITS = 8
              END IF                
            ELSE
              PIXNUM = PIXNUM-1
              IF ( BITNUM .EQ. 0 ) THEN
                NEXTINT = 0
              ELSE
                NEXTINT = IAND(WINDOW,SETBITS(BITNUM))
                VALIDS = VALIDS-BITNUM
                WINDOW = ISHFT(WINDOW,-BITNUM)
                IF ( BTEST(NEXTINT,BITNUM-1) ) 
     1            NEXTINT = IOR(NEXTINT,NOT(SETBITS(BITNUM)))
              END IF

              ROW = PIXEL/M
              COL = MOD(PIXEL,M)
              IF ( PIXEL .GT. M ) THEN
                IF ( COL .EQ. 0 ) THEN
                  TMP = NEXTINT +
     1              (IMG(MM1,ROW-1)+IMG(COL+1,ROW-1)+
     1              IMG(COL,ROW-1)+IMG(MM1,ROW-2) +2)/4
                ELSE IF ( COL.EQ.MM1 ) THEN
                  TMP = NEXTINT +
     1              (IMG(COL-1,ROW)+IMG(0,ROW)+
     1              IMG(MM1,ROW-1)+IMG(MM1-1,ROW-1) +2)/4
                ELSE
                  TMP = NEXTINT + 
     1              (IMG(COL-1,ROW)+IMG(COL+1,ROW-1)+
     1              IMG(COL,ROW-1)+IMG(COL-1,ROW-1) +2)/4
                END IF
              ELSE IF (PIXEL .NE. 0) THEN
                TMP = IMG(COL-1,ROW)+NEXTINT
              ELSE
                TMP = NEXTINT
              END IF
              IMG(COL,ROW) = TMP
              PIXEL = PIXEL+1
            END IF
          END DO
        END IF      
      END DO
      DO ROW=0,MM1
        DO COL=0,MM1
            IF ( IMG(COL,ROW).LT.0 ) IMG(COL,ROW) = IMG(COL,ROW)+65536
        END DO
      END DO
      
      RETURN
      END

      
