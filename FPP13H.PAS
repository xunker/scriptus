unit Fpp13h;

interface
 uses crt;

const
  ColorRead=  $3c7;
  ColorWrite= $3c8;
  ColorData=  $3c9;
  FontSeg=    $F000;
  FontOfs=    $FA6E;

  VGA =       $A000;

type
  int=       integer;
  byteptr=   ^byte;
  color = record
    r,g,b: byte;
  end;

  palette = array[0..255] of color;

var
    Virscr :     pointer;                   { Our first Virtual screen }
    VirScr2:     pointer;                   { Our second Virtual screen }
    VirScr3:     pointer;
    Vaddr  :     Word;                      { The segment of our virtual screen}
    Vaddr2 :     Word;                      { The segment of our 2nd virt. screen}
    Vaddr3 :     Word;
    Activescr:   Word;
    Pages  :     byte;
    black:       palette;
    backcolor:   byte;
    transparent: boolean;


procedure Mode13h(screens: byte);
procedure M13h;
function  pt(x,y,where: word):pointer;
procedure shutdown;
procedure SetActive(screen: word);
procedure SetText;
procedure plot(x,y: word; col: byte);
function  get(x,y: word):byte;

function  getbitmap(x,y,width,height: word):pointer;
procedure putbitmap(x,y: word;bitmap: pointer);
procedure copyrect(src,dest,x1,y1,x2,y2: word);

procedure hline(x1,x2,y: word; col: byte);
procedure vline(y1,y2,x: int; col: byte);
procedure line(x1,y1,x2,y2: int; col: byte);
procedure circle(ox,oy,rad: int; col: byte);
procedure circlepoints(CX,CY,x,y: int; col: byte);
procedure rect(x1,y1,x2,y2: int; col: byte);
procedure fillrect(x1,y1,x2,y2: word;col:byte);
procedure cls(col: byte);
procedure waitretrace;
procedure flip(source,dest: word);

procedure TransOff(col: byte);
procedure TransOn;
procedure PrintString(x,y: word; color: byte;s: string);
procedure PrintStringShade(x,y,xa,ya:integer;front,back: byte; s: string);

Procedure Setrgb(Col, R, G, B : Byte);
Procedure Getrgb(Col : Byte; Var R, G, B : Byte);
Procedure Setcolor(Col: byte; newcol: color);
Procedure Getcolor(Col : Byte; var newcol: color);

procedure setclrblk(src:  palette; start,finish: byte);
procedure getclrblk(dest: palette; start,finish: byte);
procedure copypalblk(src,dest: palette; start,finish: byte);
procedure usepalette(source: palette);
procedure getpalette(var dest: palette);
procedure LoadPal (FileName : string;var p: palette);
procedure SavePal(Filename : string; p: palette);
Procedure Fadeto(pall: palette;start,finish: int);
procedure RotatePalForward(var pl: palette;start,finish: byte);
procedure RotatePalBackward(var pl: palette;start,finish: byte);
procedure fadetextout;

function  Exists(FileName: string): Boolean;

function  initmouse:boolean;
procedure showmouse;
procedure hidemouse;
procedure Mousexy(var x,y,b: word);

implementation


procedure Mode13h(screens: byte);

begin
 asm
    mov ax,13h;
    int 10h;
 end;

 if screens >= 1 then
  begin
   Getmem(VirScr,65535);
   vaddr := seg(virscr^);
   SetActive(Vaddr);
   cls(0);
  end;

 if screens >= 2 then
  begin
    Getmem(VirScr2,65535);
    vaddr2 := seg(virscr2^);
    SetActive(Vaddr2);
    cls(0);
  end;

 if screens >= 3 then
  begin
   Getmem(VirScr3,65535);
   vaddr3 := seg(virscr3^);
   SetActive(Vaddr3);
   cls(0);
  end;

 pages := screens;
 activescr := vga;

end;

procedure shutdown;
 begin
  case (pages) of
   1: exit;
   2: Freemem(VirScr,65535);
   3: begin
       Freemem(VirScr,65535);
       Freemem(VirScr2,65535);
      end;
   4: begin
       Freemem(VirScr, 65535);
       Freemem(VirScr2,65535);
       Freemem(Virscr3,65535);
      end;
 end;
end; {proc}

procedure M13h; assembler;
 Asm
  mov ax,13h;
  int 10h;
 End;

function pt(x,y,where: word):pointer;
 Var off: word;
 Begin
  Asm

   mov  bx,y
   mov  cx,bx

   shl  bx,8
   shl  cx,6
   add  bx,cx
   add  bx,[x]
   mov  [off],bx

  End;

  pt := ptr(where,off);

 End;


procedure SetActive(screen: word);
  begin
   ActiveScr := screen;
  end;


Procedure SetText;  assembler;
  asm
     mov        ax,0003h
     int        10h
  end;

Procedure plot(X,Y : word; Col : Byte); assembler;
 { This puts a pixel on the screen by writing directly to memory. }
  Asm
    mov     dx, es  { push es, but faster }

    mov     cx, Y
    mov     bx, cx
    shl     cx, 8
    shl     bx, 6
    add     cx, bx
    add     cx, X
    mov     di, cx

    mov     ax,[ActiveScr]
    mov     es,ax
    mov     ah, [Col]
    mov     es:[di],ah

    mov     es, dx { pop es, but faster.  Look up.}
  End;

function  get(x,y: word):byte; assembler;
  Asm
    mov     dx, es  { push es, but faster }

    mov     cx, Y
    mov     bx, cx
    shl     cx, 8
    shl     bx, 6
    add     cx, bx
    add     cx, X
    mov     di, cx

    mov     ax,[ActiveScr]
    mov     es,ax
    mov     al,es:[di]

    mov     es, dx { pop es, but faster.  Look up.}
  End;


function getbitmap(x,y,width,height: word):pointer;
  Var
  wl,hl:          byte;
  scrof:          word;
  adv:            word;
  val:            byte;
  bitseg:         word;
  bitof:          word;
  s1,s2:          word;
  bitmap:         pointer;

 Begin
  s1 := y;
  s2 := y;

  s1 := s1 shl 8;
  s2 := s2 shl 6;
  scrof := s1 + s2 + x;

  Getmem(bitmap,width*height+2);

  bitseg := seg(bitmap^);
  bitof  := ofs(bitmap^);

  mem[bitseg:bitof] := width;
  mem[bitseg:bitof+1] := height;
  adv := 320 - width;
  inc(bitof,2);

  for hl := 1 to height do
   begin

    for wl := 1 to width do
     begin

      mem[bitseg:bitof] := mem[activescr:scrof];

      inc(scrof);
      inc(bitof);

     end;{for}

    inc(scrof,adv);

   end; {for}

  getbitmap:= bitmap;

 end; {proc}




procedure putbitmap(x,y: word;bitmap: pointer);
 label yl,xl,skip;
 Var
  wl,hl:          byte;
  width,height:   byte;
  scrseg:         word;
  scrof:          word;
  adv:            word;
  bitseg:         word;
  bitof:          word;
  s1,s2:          word;

 Begin

  bitseg := seg(bitmap^);
  bitof  := ofs(bitmap^);

 Asm
  push  es
  push  ds

  mov   ax,[activescr]
  mov   es,ax

  mov   ax,[y]
  mov   bx,ax
  shl   ax,8
  shl   bx,6
  add   ax,bx
  add   ax,[x]
  mov   di,ax

  mov   ax,[bitseg]
  mov   ds,ax
  mov   ax,[bitof]
  mov   si,ax

  mov   bl,ds:[si]     {bl is width}
  mov   ch,bl
  mov   ax,320
  xor   bh,bh
  sub   ax,bx          {ax is advance}

  mov   bh,ds:[si+1]   {bh is height}
  add   si,2

  Yl:

   mov  bl,ch

    Xl:
      mov  cl,ds:[si]    {cl is temp color}
      cmp cl,0
      je skip
      mov es:[di],cl
      skip:
      inc  si
      inc  di
      dec  bl
      cmp  bl,1
    jae xl

  add di,ax
  dec bh

  cmp bh,1

 jae yl

 pop ds
 pop es

 end;{asm}

End; {proc}

procedure copyrect(src,dest,x1,y1,x2,y2: word); assembler;
  label Yl,continue1,continue2,quit;
 Var
  width,depth: word;

  Asm
    push    ds
    push    es

    mov     ax, [Dest]
    mov     es, ax
    mov     ax, [Src]
    mov     ds, ax

    mov     ax,[y2]
    mov     bx,[y1]

    cmp     bx,ax
    jbe     continue1

    mov     cx,ax
    mov     ax,bx
    mov     bx,cx

    mov     [y1],bx

continue1:

    sub     ax,bx
    add     ax,1
    mov     [depth],ax

    mov     bx,[x1]
    mov     ax,[x2]

    cmp     bx, ax
    jbe     continue2   {don't swap}

    mov     cx, ax
    mov     ax, bx
    mov     bx, cx

    mov     [x1],bx

continue2:

    sub     ax,bx
    add     ax,1
    mov     [width],ax

    mov     bx,[x1]
    mov     dx,[y1]
    mov     cx,dx

    shl     dx,8  {y1 * 256}
    shl     cx,6  {y1 * 64}
    add     dx,cx {y1 * 256 + y1 * 64 = y1 * 320}
    add     dx,bx
    mov     si,dx
    mov     di,dx
    mov     bx,[depth]
    mov     dx, 320
    mov     ax,[width]
    sub     dx,ax


Yl:
    mov     cx, ax
    rep     movsb
    add     si,dx
    add     di,dx
    dec     bx
    cmp     bx,0
    jne     Yl

quit:
    pop     es
    pop     ds
  End;

procedure fillrect(x1,y1,x2,y2: word;col:byte); assembler;
  label Yl,continue1,continue2,quit;
 Var
  width,depth: word;

  Asm
    push    ds
    push    es

    mov     ax, [ActiveScr]
    mov     es, ax

    mov     ax,[y2]
    mov     bx,[y1]
    cmp     ax,199
    ja      quit
    cmp     bx,199
    ja      quit

    cmp     bx,ax
    jbe     continue1

    mov     cx,ax
    mov     ax,bx
    mov     bx,cx

    mov     [y1],bx

continue1:

    sub     ax,bx
    add     ax,1
    mov     [depth],ax

    mov     bx,[x1]
    mov     ax,[x2]

    cmp     bx,319
    ja      quit
    cmp     ax,319
    ja      quit

    cmp     bx, ax
    jbe     continue2   {don't swap}

    mov     cx, ax
    mov     ax, bx
    mov     bx, cx

    mov     [x1],bx

continue2:

    sub     ax,bx
    add     ax,1
    mov     [width],ax

    mov     bx,[x1]
    mov     dx,[y1]
    mov     cx,dx

    shl     dx,8  {y1 * 256}
    shl     cx,6  {y1 * 64}
    add     dx,cx {y1 * 256 + y1 * 64 = y1 * 320}
    add     dx,bx
    mov     di,dx
    mov     bx,[depth]
    mov     al,[col]

Yl:
    mov     cx, [width]
    rep     stosb
    add     dx,320
    mov     di,dx
    dec     bx
    cmp     bx,0
    jne     Yl

quit:

    pop     es
    pop     ds
  End;




Procedure hline(x1,x2,y: word; col: byte); assembler;
label continue,l;
Asm
     push    ds
     push    es

     mov     ax,x1
     mov     bx,x2
     cmp     ax,bx
     jle     continue

     mov     bx,ax
     mov     ax,x2

continue:

     mov     cx, bx
     sub     cx, ax
     add     cx, 1

     mov     dx,y
     mov     bx,dx

     shl     dx, 8
     shl     bx, 6
     add     dx, bx
     add     dx, ax

     mov     ax,[ActiveScr]
     mov     es,ax
     mov     di,dx


     mov     al, [Col]
     cld
     rep     stosb

     pop es
     pop ds

End;


Procedure vline(y1,y2,x: int; col: byte); assembler;
  label l,continue;
  Asm
     push    ds                      {; Make sure these two go out the }
     push    es                      {; same they went in }


     mov     cx,y2
     cmp     y1,cx
     jbe     continue   {don't swap}

     mov     bx,y1
     mov     y1,cx
     mov     y2,bx


continue:
     mov     ax,[ActiveScr]
     mov     es,ax                   {; Point to segment of screen }
     mov     bx,[X]
     mov     dx,[Y1]
     push    bx                      {; and this again for later}
     mov     bx, dx                  {; bx = dx}
     mov     dh, dl                  {; dx = dx * 256}
     xor     dl, dl
     shl     bx, 6                   {; bx = bx * 64}
     add     dx, bx                  {; dx = dx + bx (ie y*320)}
     pop     bx                      {; get back our x}
     add     bx, dx                  {; finalise location}
     mov     di, bx                 {; di = offset }
                                     {; es:di = where to go}
     xor     al,al
     mov     ah, [Col]
     mov     cx, y2
     sub     cx, y1
     add     cx, 1

l:   mov     es:[di],ah              {; move the value in ah to screen}
     add     di, 320
     loop l


     pop     es
     pop     ds


  end;

procedure Line(x1, y1, x2, y2 : integer; col : byte);
  var i, deltax, deltay, numpixels,
    d, dinc1, dinc2,
    x, xinc1, xinc2,
    y, yinc1, yinc2 : integer;
begin

  { Calculate deltax and deltay for initialisation }
  deltax := abs(x2 - x1);
  deltay := abs(y2 - y1);

  { Initialize all vars based on which is the independent variable }
  if deltax >= deltay then
    begin

      { x is independent variable }
      numpixels := deltax + 1;
      d := (2 * deltay) - deltax;
      dinc1 := deltay Shl 1;
      dinc2 := (deltay - deltax) shl 1;
      xinc1 := 1;
      xinc2 := 1;
      yinc1 := 0;
      yinc2 := 1;
    end
  else
    begin

    { y is independent variable }
      numpixels := deltay + 1;
      d := (2 * deltax) - deltay;
      dinc1 := deltax Shl 1;
      dinc2 := (deltax - deltay) shl 1;
      xinc1 := 0;
      xinc2 := 1;
      yinc1 := 1;
      yinc2 := 1;
    end;

  { Make sure x and y move in the right directions }
  if x1 > x2 then
    begin
      xinc1 := - xinc1;
      xinc2 := - xinc2;
    end;
  if y1 > y2 then
    begin
      yinc1 := - yinc1;
      yinc2 := - yinc2;
    end;

  { Start drawing at <x1, y1> }
  x := x1;
  y := y1;

  { Draw the pixels }
  for i := 1 to numpixels do
    begin
	 plot(x, y, col);
      if d < 0 then
        begin
		d := d + dinc1;
          x := x + xinc1;
		y := y + yinc1;
        end
      else
        begin
          d := d + dinc2;
          x := x + xinc2;
          y := y + yinc2;
        end;
    end;
end;

Procedure Circle(oX,oY,rad:integer;Col:Byte);
  VAR
    D,X,Y:integer;
  BEGIN

  x := 0;
  y:= rad;
  d:= 1 - rad;
  Circlepoints(oX,oY,x,y,col);

  while y > x do
    begin
     if d < 0 then
      begin
       d:= d + 2 * x + 3;
       x:= x + 1;
      end
	else
      begin
       d:= d + 2 * (x - y) + 5;
	  x:= x + 1;
       y:= y - 1;
      end;
     circlepoints(oX,oY,x,y,col);
  end; {while}

  END;



Procedure circlepoints(CX,CY,x,y: int; col: byte);
Begin

 plot(CX + X, CY + Y,col);
 plot(CX + X, CY - Y,col);
 plot(CX - X, CY + Y,col);
 plot(CX - X, CY - Y,col);
 plot(CX + Y, CY + X,col);
 plot(CX + Y, CY - X,col);
 plot(CX - Y, CY + X,col);
 plot(CX - Y, CY - X,col);

End;




Procedure rect(x1,y1,x2,y2: int; col: byte);
  Begin

    hline(x1,x2,y1,col);
    hline(x1,x2,y2,col);
    vline(y1,y2,x1,col);
    vline(y1,y2,x2,col);

  End;

Procedure Cls (Col : Byte); assembler;
     asm
        push    es
        mov     cx, 32000;
        mov     es,[ActiveScr]
        xor     di,di
        mov     al,[col]
        mov     ah,al
        rep     stosw
        pop     es
     End;

procedure WaitRetrace; assembler;

 label
   l1, l2;
asm
    mov dx,3DAh
l1:
    in al,dx
    and al,08h
    jnz l1
l2:
    in al,dx
    and al,08h
    jz  l2
end;


procedure flip(source,dest:Word); assembler;
  asm
    push    ds
    push    es

    mov     ax, [Dest]
    mov     es, ax
    mov     ax, [Source]
    mov     ds, ax
    xor     si, si
    xor     di, di
    mov     cx, 32000
    rep     movsw

    pop     es
    pop     ds
  end;

procedure TransOff(col: byte);
 begin
  transparent := false;
  backcolor := col;
 end;

procedure TransOn;
 begin
  transparent := true;
 end;

procedure PrintChar(x,y: word; color: byte; c: char);
 Var
  offset,xl,yl:  word;
  drawofs:       word;
  bitmask:       byte;

 begin

  offset := FontOfs + ord(c) * 8;
  drawofs:= (y shl 8) + (y shl 6) + x;

  for yl := 0 to 7 do
   begin

     bitmask := $80;

     for xl := 0 to 7 do
      begin

       if ( mem[FontSeg:offset] AND bitmask ) > 0
        then mem[ActiveScr:drawofs] := color;

       bitmask := bitmask shr 1;
       inc(drawofs);

      end;

    inc(drawofs,312);
    inc(offset);

   end;
 end;



procedure PrintString(x,y: word; color: byte;s: string);
 Var
  sl:  word;

begin

  if not transparent then fillrect(x,y,x + length(s) shl 3,y+7,backcolor);

  for sl := 1 to length(s) do
   PrintChar(x + ((sl - 1) shl 3),y,color,s[sl]);  {sl shl 3 is the same as sl * 8 }
                                             {but faster }
end;


procedure PrintStringShade(x,y,xa,ya:integer;front,back: byte; s: string);
Var
 temp:  boolean;


 begin

  temp := transparent;

  TransOn;
  PrintString(x+xa,y+ya,back,s);
  PrintString(x,y,front,s);

  transparent := temp;

 end;

Procedure Setrgb(Col, R, G, B : Byte);
 Begin
   Asm
      mov   dx, 3c8h
      mov   al, [Col]
      out   dx, al
      inc   dx
      mov   al, [R]
      out   dx, al
      mov   al, [G]
      out   dx, al
      mov   al, [B]
      out   dx, al
   End;
 End;

Procedure Getrgb(Col : Byte; Var R, G, B : Byte);
Var
   Rt,Gt,Bt : Byte;
Begin
   Asm
      mov   dx, 3c7h
      mov   al, [Col]
      out   dx, al
      inc   dx
      inc   dx
      in    al, dx
      mov   [Rt],al
      in    al, dx
      mov   [Gt],al
      in    al, dx
      mov   [Bt],al
   End;
   R := Rt;
   G := Gt;
   B := Bt;
End;

Procedure Setcolor(Col: byte; newcol: color);
Begin
   Asm
      mov   dx, 3c8h
      mov   al, [Col]
      out   dx, al
      inc   dx
      mov   al, [newcol.R]
      out   dx, al
      mov   al, [newcol.G]
      out   dx, al
      mov   al, [newcol.B]
      out   dx, al
   End;
End;

Procedure Getcolor(Col : Byte; var newcol: color);
Var
   Rt,Gt,Bt : Byte;
Begin
   Asm
      mov   dx, 3c7h
      mov   al, [Col]
      out   dx, al
      inc   dx
      inc   dx
      in    al, dx
      mov   [Rt],al
      in    al, dx
      mov   [Gt],al
      in    al, dx
      mov   [Bt],al
   End;
   newcol.R := Rt;
   newcol.G := Gt;
   newcol.B := Bt;
End;


procedure setclrblk(src: palette; start,finish: byte);
 var ll: byte;
  begin
    for ll := start to finish do
     setcolor(ll,src[ll]);
  end;

procedure getclrblk(dest: palette; start,finish: byte);
  var ll: byte;
   begin
    for ll := start to finish do
     getcolor(ll,dest[ll]);
   end;

procedure copypalblk(src,dest: palette; start,finish: byte);
  var ll: byte;
   begin
    for ll:= start to finish do
      dest[ll] := src[ll];
   end;


procedure usepalette(source: palette);
 var
  ll: byte;
  count: byte;

  begin
  count := 0;
  port[ColorWrite] := 0;
   for ll := 0 to 255 do
    begin

      port[colordata] := source[ll].r;
      port[colordata] := source[ll].g;
      port[colordata] := source[ll].b;

    end;
  end;

procedure getpalette(var dest: palette);
  var
   ll:      byte;
   count:   byte;

   begin
   count := 0;

   waitretrace;
   port[ColorRead] := 0;
   for ll := 0 to 255 do
    begin
     inc(count);
     if count > 40 then
      begin
       count := 0;
       waitretrace;
      end;

     dest[ll].r :=  port[colordata];
     dest[ll].g :=  port[colordata];
     dest[ll].b :=  port[colordata];
    end;


   end;

procedure LoadPal (FileName : string;var p: palette);
   { This loads the Pallette file and puts it on screen }

var Fil : file of palette;
    I : integer;
BEGIN
  assign(Fil, FileName);
  reset(Fil);
  read(Fil, p);
  close(Fil);
end;

procedure SavePal(Filename : string; p: palette);

var Fil : file of palette;
    I : integer;
BEGIN
  assign(Fil, FileName);
  rewrite(Fil);
  write(Fil, p);
  close(Fil);
end;

Procedure Fadeto(pall: palette;start,finish: int);
 VAR loop1,loop2:integer;
    Tmp : palette;
    count: byte;
    cmax:  byte;
BEGIN

  getpalette(tmp);
  cmax := 127;

  For loop1:=1 to 64 do BEGIN
    waitretrace;
    port[ColorWrite] := start;

       For loop2:= start to finish do
        Begin

         inc(count);
         If Tmp[loop2].r < Pall[loop2].r then inc(Tmp[loop2].r);
         If Tmp[loop2].g < Pall[loop2].g then inc(Tmp[loop2].g);
         If Tmp[loop2].b < Pall[loop2].b then inc(Tmp[loop2].b);

         If Tmp[loop2].r > Pall[loop2].r then dec(Tmp[loop2].r);
         If Tmp[loop2].g > Pall[loop2].g then dec(Tmp[loop2].g);
         If Tmp[loop2].b > Pall[loop2].b then dec(Tmp[loop2].b);

         if(count > cmax) then
          begin
           count := 0;
           waitretrace;
          end;

         port[colordata]  := tmp[loop2].r;
         port[colordata]  := tmp[loop2].g;
         port[colordata]  := tmp[loop2].b;

       End;

   End;
 copypalblk(pall,tmp,start,finish);
END;

procedure RotatePalForward(var pl: palette;start,finish: byte);
 Var
  temp: color;
  lp:   int;

  Begin
    temp := pl[finish];

    for lp := finish-1 downto start do
     pl[lp + 1] := pl[lp];

    pl[start] := temp;
  End;

procedure RotatePalBackward(var pl: palette;start,finish: byte);
 Var
  temp: color;
  lp:   int;

  Begin
    temp := pl[start];

    for lp := start + 1 to finish do
     pl[lp - 1] := pl[lp];

    pl[finish] := temp;
  End;


Procedure Fadetextout;
Var
   Loop : Byte;
   R, G, B : Byte;

Begin

   Getrgb(7, R, G, B);
   For Loop := 0 to 63 do
   Begin
      WaitRetrace;
      WaitRetrace;
      setrgb(7, R, G, B);
      If R > 0 Then Dec(R);
      If G > 0 Then Dec(G);
      If B > 0 Then Dec(B);
   End;
End;

function Exists(FileName: string): Boolean;
    { Checks to see if filename exits or not }
var f: file;
begin
  {$I-}
  Assign(f, FileName);
  Reset(f);
  Close(f);
  {$I+}
  Exists := (IOResult = 0) and
   (FileName <> '');
end;

function initmouse:boolean;
 var
  l: int;
 Begin
   Asm
    mov ax, 0h
    int 33h
    mov [l],ax
   end;
  if l = $0 then
  initmouse := false
   else
  initmouse := true;

 End;

procedure showmouse; assembler;
 Asm
  mov ax, 1
  int 33h
 End;

procedure hidemouse; assembler;
 Asm
  mov ax,2
  int 33h
 End;

procedure MouseXY(var x,y,b: word);
 var
  tx,ty,tb: word;
  Begin
  Asm
   mov ax,3
   int 33h
   mov [tx],cx
   mov [ty],dx
   mov [tb],bx
  end;
 x := tx shr 1;
 y := ty;
 b := tb;
 End;


begin
 ActiveScr    := VGA;
 transparent  := true;
 backcolor    := 0;
end.