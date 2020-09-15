Program Scriptus_13h_The_First_Loop;

{$M $4000,0,65535} 			{16k stack, no heap - adjust as needed }
{$L scriptus.n02} 	        { Link in Object file }
{$F+} 				{ force calls to be 'far'}

{
Scriptus.mod = scriptus.n01
Scriptus.obj = scriptus.n02
Scriptus.pal = scriptus.n03
}


uses crt,dos,fpp13h,readit;

var
    outpixel,i,j,l,k,xl,randnum:integer;
    scrub_1:boolean;

    dev,mix,stat,pro,loop : integer;
    md : string;
    ch: char;

    x1,x2,y1,y2:integer;
    volume,delaybit,line1,line2,linepos,upcolor,wp,wpo,opwp,opwpo:integer;

    machine:char;

    showline,soundon,litewrite,lineup,uselines:boolean;

    scriptus: palette;

const
 palette = 'scriptus.n03';


procedure modvolume(v1,v2,v3,v4:integer); external ; {Can do while playing}
procedure moddevice(var device:integer); external ;
procedure modsetup(var status:integer;device,mixspeed,pro,loop:integer;var str:string); external ;
procedure modstop; external ;
procedure modinit; external;
{$F+}

procedure workingpixel;
var move:integer;

begin;
wpo:=wp;
move:=2;
if (wp-opwp<50) then move:=3;
if (wp-opwp<25) then move:=5;
if (wp-opwp<10) then move:=8;

wp:=wp+move;
opwpo:=opwp;
opwp:=opwp-move;
if opwp<1 then opwp:=200;
if wp>200 then wp:=1;
plot(0,wp,100);
plot(0,wpo,0);
plot(0,opwp,50);
plot(0,opwpo,0);
end;


procedure down(cycles:integer);

begin;

if delaybit=cycles then showline:=true;

   if showline=true then begin;
     line(1,line1,319,line1,0);
     line1:=line1+1;

     if line1=199 then begin;
        showline:=false;
        line1:=190;
        end;

end;

end;


procedure bar(y: word;c: byte); assembler;
 asm

  mov dx, es


  mov ax, [ActiveScr]
  mov es, ax

  mov ax, y
  mov bx, ax
  shl ax, 8
  shl bx, 6
  add ax, bx
  inc ax
  mov di, ax
  mov al, c
  mov ah, c

  mov cx, 159

  rep stosw
  stosb

  mov es, dx
 end;



procedure linemonger;

begin;
     if lineup=false then
        begin;
          bar(linepos,linepos); {hline(1,319,linepos,linepos);}
          linepos:=linepos+1;
          if linepos>=40
	   then lineup:=true;
        end;

     if lineup=true then
       begin;
        bar(linepos,upcolor); {hline(1,319,linepos,upcolor); }
        upcolor:=upcolor+1;
        if upcolor>40 then upcolor:=1;

        linepos:=linepos-1;
        if linepos<=1 then lineup:=false;
      end;
end;




procedure writeit(wordz:string; cyclez:integer);
begin;

if delaybit=cyclez then
   if litewrite=true then begin;
      litewrite:=false;
      PrintStringShade(1,190,1,1,90,90,wordz); { 70 90 }
    end;

if delaybit=cyclez+1 then
   if litewrite=false then begin;
     litewrite:=true;
     PrintStringShade(1,190,1,1,60,30,wordz); {textit(1,190,wordz,7,7,30,60,0,true);}
   end;
end;


procedure cred(wordz:string; bit,ypos:integer);

begin;
if delaybit=bit then begin;
     if litewrite=true then begin;
      litewrite:=false;
      PrintStringShade(1,ypos,1,1,90,90,wordz); { 70 90 }
    end;
     delay(50);
     if litewrite=false then begin;
     litewrite:=true;
     PrintStringShade(1,ypos,1,1,60,30,wordz);
     end;
     end;
bit:=bit+10;
ypos:=ypos+10;

end;

procedure scrub;

Var
 offset:  word;
 adv:     word;

begin;

  offset := (y1 shl 8) + (y1 shl 6) + x1;
  adv := 320 - (x2 - x1 + 1);


  for i:=y1 to y2 do
   begin
      for j:=x1 to x2 do begin;

      outpixel:= mem[ActiveScr:offset  -1 ] + {get(i-1,j)   }
                +mem[ActiveScr:offset     ]   {get(i,j)     }
                +mem[ActiveScr:offset  +1 ]   {get(i+1,j)   }
                +mem[ActiveScr:offset +319]   {get(i-1,j+1) }
                +mem[ActiveScr:offset +320]   {get(i,j+1)   }
                +mem[ActiveScr:offset +321];  {get(i+1,j+1);}

      outpixel:=outpixel div 6 + random(randnum);

      if outpixel=0 then
       outpixel:=random(256);

      mem[ActiveScr:offset] := outpixel;
      inc(offset); {Next pixel over}

   end;

   inc(offset,adv);

 end;



end;

procedure scrub_2;

Var
 offset: word;
 adv: word;


begin;


  offset := (y1 shl 8) + (y1 shl 6) + x1;
  adv := 320 - (x2 - x1 + 1);


  for i:=y1 to y2 do
   begin
    for j:=x1 to x2 do begin;

      outpixel := mem[activescr: offset - 1]+    { get(i-1,j) }
                  mem[activescr: offset    ]+    {+get(i,j)   }
                  mem[activescr: offset + 1];    {+get(i+1,j);}

      outpixel:=outpixel div 3 + random(randnum);
      if outpixel=0 then outpixel:=random(256);

      mem[activescr: offset] := outpixel;

      inc(offset);
      end;
  inc(offset,adv);
 end;

end;

begin;
      writeln;
      writeln('Scriptus 13h : The First Loop Û\');
      writeln('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÛ |');
      writeln('\______________________________\|');
      writeln('Please select closest to your machine type :');
      writeln('0 - 286');
      writeln('1 - 386/16');
      writeln('2 - 386/25');
      writeln('3 - 386/40');
      writeln('4 - 486/33');
      writeln('5 - 486/66');
      writeln('6 - 486/100 or Pentium < 100');
      writeln('7 - Just Gimmie full screen mode');
      writeln('8 - exit');
      writeln;
      write('Well : ');
      Machine:=readkey;
      if Machine= '8' then halt;
      writeln;

      soundon:=true;
      Litewrite:=true;

      modinit;
	moddevice ( dev ); { Returns device number in DEV or 255 if 'no sound' }
        if (dev =255) then begin;
           soundon:=false;
           writeln;
           writeln('Although there is no sound going to be played, the demo');
           writeln('must still behave as if there is, so it might seem like');
           writeln('its slow or lagging, but its not.  You have been warned.');
           writeln;
           delay(5000);
           end;
        if (dev = 0 ) then
           begin
           writeln;
           writeln('Don''t you wish *you* could afford a Sound Blaster?');
           writeln;
           delay(2000);
           end;

        md:='scriptus.n01';
        mix := 10000;   {use 10000 normally }
        pro := 0; {Leave at 0}
        loop :=4; {4 means mod will play forever}
        modvolume (255,255,255,255);    { Full volume }
	{modsetup ( stat, dev, mix, pro, loop, md);}
       	case stat of
           1: writeln('Not a mod');
           2: writeln('Already playing');
           4: writeln('Out of memory');
       	else
           begin


{X And Y Values}
if machine = '0' then begin;
   x1:=155; x2:=165; y1:=95; y2:=105;
   end;
if machine = '1' then begin;
   x1:=150; x2:=170; y1:=90; y2:=110;
   end;
if machine = '2' then begin;
   x1:=145; x2:=175; y1:=85; y2:=115;
   end;
if machine = '3' then begin;
   x1:=140; x2:=180; y1:=80; y2:=120;
   end;
if machine = '4' then begin;
   x1:=130; x2:=190; y1:=70; y2:=130;
   end;
if machine = '5' then begin;
   x1:=110; x2:=210; y1:=50; y2:=150;
   end;
if machine = '6' then begin;
   x1:=95; x2:=225; y1:=35; y2:=165;
   end;
if machine = '7' then begin;
   x1:=2; x2:=319; y1:=2; y2:=199;
   end;

if machine<'6' then uselines:=true;
{end x y values}


  Mode13h(1);

  exitproc := @shutdown;


    for i:=x1 to x2 do
      for j:=y1 to y2 do
        plot(i,j,random(256));

  if soundon=true then modsetup ( stat, dev, mix, pro, loop, md);

  scrub_1:=true;
  for xl:=1 to 256 do setrgb(xl,xl div 2,xl div 2,xl div 1);


  loadpal(palette,scriptus);
  usepalette(scriptus);

  k:=0;
  randnum:=3;
  delaybit:=1;
  line1:=190;
  showline:=false;
  wp:=1;
  lineup:=true;

  repeat

  workingpixel;

  SetActive(Vaddr);

  if scrub_1=true then scrub;
  if scrub_1=false then scrub_2;

  copyrect(Vaddr,VGA,x1,y1,x2,y2);

  SetActive(VGA);


  k:=k+1;
  if k>200 then begin;
     if scrub_1=false then scrub_1:=true;
     randnum:=2;
     end;
  if k>400 then begin;
     randnum:=1;
     end;
  if k>600 then begin;
     randnum:=3;
     end;
  if k>800 then begin;
     if scrub_1=true then scrub_1:=false;
     randnum:=3;
     end;
  if k>1000 then begin;
     k:=0;
     end;

  if uselines=true then linemonger;

  if delaybit<1000 then delaybit:=delaybit+1;
  if delaybit=1000 then delaybit:=1;

  writeit('Scriptus 13h : The First Loop', 50);
  down(75);
  writeit('From Far Point Productions', 100);
  down(125);
  writeit('Boy, O boy!  Isn''t it kule?', 150);
  down(175);
  writeit('Yep, we know...  We made it in 1996!', 200);
  down(225);
  writeit('The ScrubFire Routine is completely', 250);
  down(275);
  writeit('original and made by us.  The source is', 300);
  down(325);
  writeit('nearly pure Turbo Pascal 7 with in-line', 350);
  down(375);
  writeit('assembler for flavor.  Its about 600', 400);
  down(425);
  writeit('lines long without the music included.', 450);
  down(475);
  writeit('The cred''s for this lil'' thang'' :', 500);
  down(525);
  writeit('Avtar - Pixel ''tines, font, fading...', 550);
  down(575);
  writeit('Legacy - ScrubFire, Gravapels, Adalines', 600);
  down(625);
  writeit('Mark J. Cox - The Mod playing schtuff', 650);
  down(675);
  writeit('Anonymous - The tunez (aint they kule?)', 700);
  down(725);
  writeit('Greets go out to all our friends, and :', 750);
  down(775);
  writeit('FC, S!P, EMF, EastSide, Nooon, Majic12,', 800);
  down(825);
  writeit('Iguana, Remal, Valhalla, Complex, PM,', 850);
  down(875);
  writeit('Ultraforce, Legend Design, Asphixia,', 900);
  down(925);
  writeit('Triton, and Nap''.  Great going, guys.', 950);
  down(975);
  writeit('Û   Û  Û ÛÜÛÜ STAY UNREAL ÜÛÜÛ Û  Û   Û', 998);
  down(25);

  until keypressed;

  begin;
  for volume:=255 downto 1 do modvolume(volume,volume,volume,volume);
  delay(10);
  end;


  {End Scroller}
  {delaybit:=1;
  PrintStringShade(1,1,1,1,60,30,'You have just seen an FPP Production');
  printstringshade(1,6,1,1,30,60,'------------------------------------');

  repeat

  cred('Cool, wasn''t it?',10,20);
  cred('Anyway, thanks for watching, and Thanqx:',20,30);
  cred('----------------------------------------',30,40);
  cred('Be sure to be at the next big gathering!',40,50);
  cred('NUDEP ''96, North Utah Demo Ect. Party!',50,60);
  cred('Organized by FPP and EastSide, sponsored',60,70);
  cred('by Packard Bell, Novell, and Access to',70,80);
  cred('name but a few...See you there if you',80,90);
  cred('can make it.',90,100);


  delaybit:=delaybit+1;

  until delaybit>100;

  readln;
  repeat
  workingpixel;


  until keypressed;

  setactive(vaddr);
  cls(0);
  setactive(vga);

  copyrect(vga,vaddr,1,1,320,200);

  for i:=30000 downto 0 do plot(random(320),random(200),random(256));
  for i:=30000 downto 0 do plot(random(320),random(200),random(256));
  for i:=30000 downto 0 do plot(random(320),random(200),random(256));
  }
  fadeto(black,0,255);



  if soundon=true then modstop;
   textmode(co80);
readln;
readtext;

           end;
        end;

textcolor(15);
Writeln('Hi there.  I hoped you liked the dentro..Its a first, ''eh?');
writeln('But seriously now, look for us at the demo compos in a few years...');
writeln('Yeah, we''ll be the ones holding the most points :>...');
writeln('Personal greets go out to : ');
writeln;
textcolor(13);
writeln(' From Legacy "Oh, so THATS what *this* does..." :');
writeln('------------------------------------------------');
textcolor(9);
writeln('     Necros/LD     All/FC     Denthor/Asphixia     All/EastSide');
writeln('    All/FPP ;)   King George       J0ker         All My Buds/VHS');
writeln;
writeln('Those wild and crazy Guys at Borland Int''l...');
writeln;
textcolor(13);
writeln('From Avatar "Insert quote here" :');
writeln('----------------------------');
textcolor(9);
writeln('Put some junk herer...');
textcolor(12);
writeln('-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-');
textcolor(15);
writeln('To find out about the latest and greatest FPP releases, or to give feedback,');
writeln('contact "www.ieighty.net/~legacy/fpp.html" or mail at "legacy@ieighty.net",');
writeln('Or just keep a bookmark on the IBM demos newgroup...');
writeln('                                         -FPP, April 1996-');


end.