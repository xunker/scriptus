UNIT Readit;

INTERFACE

PROCEDURE ReadText;



   (* ========================================= *)

IMPLEMENTATION

USES
   DOS,
   Gfx, Output, HexConversions;


PROCEDURE WriteLine(y : INTEGER; s : STRING);
VAR
   i   : INTEGER;
   col : BYTE;
BEGIN
   col := 0;
   FOR i := 1 TO Length(s) DO BEGIN
       IF (col = 0) AND (s[i] <> ' ') THEN
          IF (i = 2) THEN
             col := 8
          ELSE IF (s[i] = '-') THEN
             col := 10
          ELSE IF i = 10 THEN
             col := 14
          ELSE IF i = 17 THEN
             col := 15
          ELSE
             col := 3;
       Scr[y, i, 0] := BYTE(s[i]);
       Scr[y, i, 1] := col;
       IF (col = 14) AND ((s[i] = '-') OR (s[i] = ':')) THEN
          col := 3;
   END;
   IF Length(s) < 80 THEN
      FOR i := Length(s)+1 TO 80 DO BEGIN
         Scr[y, i, 0] := 32;
         Scr[y, i, 1] := col
      END;
END;


VAR
   NLines : INTEGER;
   nfo    : ARRAY [1..200] OF STRING[80];
   Pos    : WORD;
CONST
   key    : BYTE = 0;

PROCEDURE KbHandler; INTERRUPT;
BEGIN
   ASM
        IN      AL,60h
        TEST    AL,80h
        JZ      @@ok
         XOR    AL,AL
     @@ok:
        MOV     [key],AL

        IN      AL,61h
        MOV     AH,AL
        OR      AL,80h
        OUT     61h,AL
        MOV     AL,AH
        OUT     61h,AL
        MOV     AL,20h         { Signal EOI. }
        OUT     20h,AL
   END
END;


PROCEDURE ReadText;
VAR
   i   : INTEGER;
   vel : INTEGER;
   k   : BYTE;
   time: INTEGER;
   oldh : POINTER;
BEGIN
   SetKeyRate(0, 0);
   GetIntVec(9, oldh);
   SetIntVec(9, @KbHandler);
   ClearScreen(scr[26]);
   FOR i := 1 TO NLines DO
      WriteLine(i+25*2, nfo[i]);
   vel := 0;
   i   := 0;
   REPEAT
      SetScanStart(i);
      INC (vel);
      i := i + vel DIV 7;
   UNTIL i >= 25*16*1;
   REPEAT
      SetScanStart(i);
      i := i + vel DIV 7;
   UNTIL i >= Pos-25*16;
   REPEAT
      SetScanStart(i);
      DEC (vel);
      i := i + vel DIV 7;
   UNTIL (i >= Pos) OR (vel = 0);
   SetScanStart(Pos);

   vel  := 0;
   time := 0;
   REPEAT
{            WriteLine(Pos DIV 16 + 3, HexByte(key));}
      IF (Time > 0) OR (key <> 0) THEN BEGIN
         IF key <> 0 THEN BEGIN
            k := Key;
            Key  := 0;
            time := 3;
         END;
         CASE k OF
            72 : IF (vel > -8*6) THEN DEC(vel,1);
            80 : IF (vel <  8*6) THEN INC(vel,1);
            81 : INC(vel, 3);
            73 : DEC(vel, 3);
         END;
         DEC(time);
      END ELSE
         IF (vel > 0) THEN
            DEC(vel,5)
         ELSE IF (vel < 0) THEN
            INC(vel,5);

      INC(Pos, vel DIV 8);

      IF (Pos < 25*16*2) THEN
         Pos := 25*16*2
      ELSE IF (Pos > (24+NLines)*16) THEN
         Pos := (24+NLines)*16;

      SetScanStart(Pos)
   UNTIL (k = 28) OR (k = 1);

   vel := 0;
   i   := Pos;
   REPEAT
      SetScanStart(i);
      DEC (vel);
      i := i + vel DIV 7;
   UNTIL i <= Pos-25*16;
   REPEAT
      SetScanStart(i);
      i := i + vel DIV 7;
   UNTIL i <= 25*16*1;
   REPEAT
      SetScanStart(i);
      INC (vel);
      i := i + vel DIV 7;
   UNTIL (i <= 0) OR (vel = 0);
   SetScanStart(0);
   SetIntVec(9, oldh);
   SetKeyRate(1, 12);
END;


VAR
   f   : TEXT;

BEGIN
   Assign(f, 'scriptus.nfo');
   Reset(f);
   nfo[1] := ' Use the up/down/PgUp/PgPn/Esc keys to read.  You know the drill.';
   nfo[2] := ' Thanks go to Iguana/Vagelisteam for this reader... Thanks Guys.. ';
   NLines := 2;
   REPEAT
      INC (NLines);
      ReadLn(f, nfo[NLines])
   UNTIL Eof(f);
   Close(f);
   IF IOResult <> 0 THEN BEGIN
      WriteLn('Hey bud, the required file ain''t here, aborting...');
      WriteLn('Find it!');
      HALT(1)
   END;
   Pos := 25*16*2
END.
