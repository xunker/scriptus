unit pcx;

interface
 uses fpp13h,spx_dos;

Var Pcxfile:    word;

function LoadPCX(FileName:  openstring; pal: palette):pointer;

implementation


function DecodePcxline(LineBuffer: byteptr;TotalBytes: word):word;
Var
 Position:      word;
 Count:         int;
 Color:         byte;
 RawData:       byte;
 i:             int;
 sg,off:        word;
 error:         byte;
 dumb:          word;

Begin

Position := 0;

dumb := 1;
sg:=    seg(linebuffer);
off:=   ofs(linebuffer);

    while (Position < TotalBytes) do
      begin

	   readdos(pcxfile,@rawdata,dumb,error);

           if ((RawData and $C0) = $C0) then
            begin
		Count := RawData and $3F;

	        readdos(pcxfile,@rawdata,dumb,error);

		Color := RawData;
	    end

	   else begin
		Count := 1;
		Color := RawData;
	   end;
      asm
       mov      ax, [sg]
       mov      es, ax
       mov      ax, [off]
       mov      di, ax
       mov      cx, [count]
       mov      al, [color]
       rep      stosb

       mov      ax,es
       mov      [sg],ax
       mov      ax,di
       mov      [off],ax

      end;

      end;

    decodepcxline := 0;
End;


function LoadPCX(FileName:  openstring; pal: palette):pointer;
var
    LineBuffer:           byteptr;
    LinearDataPointer:    byteptr;
    sg,off:               word;
    sg2,off2:             word;
    LineCounter:          word;
    WidthCounter:         word;
    Result:               int;
    TotalBytes:           word;
    ColorIndex:           int;
    Xsize,Xmax,Xmin:      int;
    Ysize,Ymax,Ymin:      int;
    Nplanes:              byte;
    Bytesperline:         word;
    dumber:               word;
    error:                byte;

begin
    pcxfile := opendos(filename);
    dumber:= 2;

    {read in all the values}
    seekdos(pcxfile,4);
    readdos(pcxfile,@xmin,dumber,error);
    readdos(pcxfile,@ymin,dumber,error);
    readdos(pcxfile,@xmax,dumber,error);
    readdos(pcxfile,@ymax,dumber,error);

    seekdos(pcxfile,65);
    dumber:=1;
    readdos(pcxfile,@Nplanes,dumber,error);
    dumber:=2;
    readdos(pcxfile,@Bytesperline,dumber,error);

    XSize := XMax - XMin + 1;
    YSize := YMax - YMin + 1;

    TotalBytes := NPlanes * BytesPerLine;

    getmem(LineBuffer,TotalBytes);
    getmem(lineardatapointer,Xsize * Ysize + 2);

    sg := seg(lineardatapointer);
    off:= ofs(lineardatapointer);

    asm
    push es
     mov        ax, [sg]
     mov        es, ax
     mov        ax, [off]
     mov        di, ax
     mov        ax, [xsize]
     mov        es:[di],ax
     inc        di
     mov        ax, [ysize]
     mov        es:[di],ax
     mov        ax, di
     mov        [off], ax
    pop es
    end;

    sg2 := seg(linebuffer);
    off2:= ofs(linebuffer);

    for LineCounter := 0 to YSize -1 do
     begin
	Result := DecodePCXLine(LineBuffer, TotalBytes);
	   if (Result <> 0) then begin
		  freemem(LineBuffer,totalbytes);
		  loadpcx := nil;
	   end;

          for WidthCounter := 0 to XSize -1 do
             asm
              push es
              push ds

              mov  ax, [sg2]
              mov  ds, ax
              mov  ax, [off2]
              mov  si, ax
              mov  ax, [sg]
              mov  es, ax
              mov  ax, [off]
              mov  di, ax
              stosb

              pop  ds
              pop  es

	     end;
         inc(sg2,xsize);
         inc(sg,xsize);

    end;


    freemem(LineBuffer,Totalbytes);

{	   blockread(pcxFile,result,1);
	   if (Result <> 12) then
	    begin
             pal:= black;
             exit;
            end;


		blockread(pcxfile,Pal,1);
		for ColorIndex := 0 to 256 do
                  begin
		   Pal[ColorIndex].r:= Pal[ColorIndex].r shr 2;
		   Pal[ColorIndex].g:= Pal[ColorIndex].g shr 2;
		   Pal[ColorIndex].b:= Pal[ColorIndex].g shr 2;
	 	  end;}

    closedos(pcxfile);

    loadpcx := Lineardatapointer;
end;

end. 