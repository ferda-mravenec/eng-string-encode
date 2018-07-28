unit Test;

interface

uses Classes, SysUtils, Transform;

var SourceList, AddList: TStringList;
  sArr, allBytes, content: TBytes;
  sss: String;
  len : byte;
  sumLen: word;
  buffer: string;
  o1, o2: longword; // offsety

begin

  AddList := TStringList.create;
  SourceList := TStringList.create;
  SourceList.LoadFromFile('a:\source_eng.txt');

  sumLen := 0;
  for i:=0 to SourceList.count-1 do
    begin
      sss := SourceList[i];
      len := encode(sss, sArr);
      setLength(allBytes,sumLen+len );
      move(sArr[0], allBytes[sumLen], len);
      sumLen := sumLen + len;
    end;
  // WRITE
  with
    TFileStream.Create('A:\test.bin', fmCreate)
    do
      try
        seek(0, soBeginning);
        Write(allBytes[0], sumLen ) // zapsat výstupní pole
      finally
        free;
      end;

  with
    TFileStream.Create('A:\test.bin', fmOpenRead)
    do
      try
        setLength(content, size);
        seek(0, soBeginning);
        readbuffer(content[0], size ); // zapsat výstupní pole
        o1 := 0;
        for i := 0 to size-1 do
          begin
          // o2 := o2 + 1;
          o2 := o2;
          if content[i]=0 then
            begin
              sss := '';
              o2 := i;
              if (o2-o1) > 0 then
                begin
                  setLength(sArr, o2-o1);
                  move(content[o1],sArr[0], o2-o1 );
                  decode(sArr, sss);
                  AddList.add(sss);
                end;
              {
              else
                begin
                  sss := sss + chr( content[o1] );
                end;
              }
              o1 := i + 1 ; // next begin is after zero
            end;
          end;

      finally
        free;
      end;

  AddList.saveToFile('B:\output.txt');

end.
