unit Transform; // Transform English string v. 1.0 

interface

uses
  Classes, Windows, SysUtils, Dialogs;

  const MESSAGE_FORBIDDEN_CHAR = 'Forbiden character in word: ';
  const ENCODE_BYTE_RANGE = 34; // using 34 chars total
  const BYTE_SHIFT_DOWN = 96;

  type TBytes = array of byte;

  var s: string;

  procedure encodeReplace(var s: string; var w: TBytes );
  function decodeReplace1(b: byte): char;
  function decodeReplace2(b: byte): string;

  { copyByte2 - it's intended purpose is to be used
                in the 2 chars block, where lookahead
                assertion is performed.
    copyByte2 copies 1 byte to wo array, but it
    1. can extend the array +1 byte
    2. sets step := 2
    If you want to use elsewhere than in lookahead
    assertion block, you must correct the step := 1;
    after it were called! }
  procedure copyByte2(var c:Byte;var wo :TBytes; var i:Integer; var lw: Byte; var wPointer: byte; var step: byte);
  procedure so(var s: string; c: char);
  function encode(var s:string; var wo: TBytes): byte;
  procedure decode(var wi: TBytes; var s:string);

implementation

{ wo je výstupní pole bytù
  lw ukazuje délku výstupního pole wo
  wPointer ukazuje aktuální pozici
  w je totožný se stringem s
}
procedure copyByte2(var c:Byte;var wo :TBytes; var i:Integer; var lw: Byte; var wPointer: byte; var step: byte);
begin
  if wPointer > length(wo)-1 then
    begin
    lw := lw + 1;
    setLength(wo,lw);
    end;
  // Adds encoded character to output:
  wo[wPointer] := c; // copy 1 byte character to output array w
  wPointer := wPointer + 1;
  step := 2;
end;

procedure so(var s: string; c: char);
begin
 s := s + c;
end;

// , and ; are forbidden characters. Also digits.
procedure encodeReplace(var s: string; var w: TBytes );
var i,l: byte;
begin
  if s = '' then exit;

  l := length(s);
  i:= 1;
  while i <= l do
    begin
      if s[i] = '-' then // 45 '-'
        s[i] := '{' else // 123 '{'
      if s[i] = '.' then // 46 '.'
        s[i] := '|' else // 124 '|'
      if s[i] = '/' then // 47 '/'
        s[i] := '}' else // 125 '}'
      if s[i] = ' ' then // ' '
        s[i] := '~' else // '~'
      if i+1 <= length(s) then // check next char if equal 'h'
        if s[i+1] = 'h' then // h
          begin
            if s[i] = 'c' then  // 99 c ... ch
              begin
                s[i] := chr(127);
                s := stringreplace(s,s[i]+'h',s[i],[]);
              end
              else
            if s[i] = 'p' then  // 112 p ... ph
              begin
                s[i] := '€';  // 128 €
                s := stringreplace(s,s[i]+'h',s[i],[]);
              end
              else
            if s[i] = 's' then  // 115 s ... sh
              begin
                s[i] := chr(129);
                s := stringreplace(s,s[i]+'h',s[i],[]);
              end
              else
            if s[i] = 't' then  // 116 t .. th
              begin
                s[i] := '‚';     // 130 ‚ (toto je jiná èárka než 44!)
                s := stringreplace(s,s[i]+'h',s[i],[]);
              end
            else
              begin // no change on this char
                i := i + 1;
                continue;
              end;
            l := length(s);
          end;

      i := i + 1;
    end;

    setlength(w,length(s));
    move(s[1],w[0],length(s));
end;

function decodeReplace1(b: byte): char;
begin
  if b > 122 then
    begin
      if b = 123 then
        Result := '-' else // '{'
      if b = 124 then      // '|'
        Result := '.' else
      if b = 125 then // '}'
        Result := '/' else
      if b = 126 then // '~'
        Result := ' '
    end
  else
    Result := chr(b);
end;

function decodeReplace2(b: byte): string;
begin
  if (b = 127) then
    Result := 'ch'
  else if (b = 128) then
    Result := 'ph'
  else if (b = 129) then
    Result := 'sh'
  else if (b = 130) then
    Result := 'th'
  else Result := '';
end;

{
 Will create new byte array representing shorten version
 of the string.
 Condition: string is lowercase English chars, no digits
`l - length of string
 c - current byte
 p - previous byte
 n - next byte
 Result: length of the output array wo

}
function encode(var s:string; var wo: TBytes): byte;
var i: Integer;
    w: TBytes; // kopie stringu s
    l, c, n, step, wPointer: byte;
    lw: byte; // velikost nového pole
begin
//  s := 'thanks-shelly pharhaps we have good chance/luck to win.';
  { On the begin l is lenght of original string, but
    later it's meanning is changed. }
  l := length( s );
  wPointer := 0;
  step := 1;
  if l>1 then
    begin
      { Replace some chars in string and convert it
        to w array, which is the original word changed
        with replace.
      }
      encodeReplace(s,w);
      { Now, l length of the w array, which is shorten
        version of the string.}
      l := length( w );

      lw := l div 2;
      setlength(wo,lw);

      i := -1;
      { Projíždí pole w, které odpovídá pùvodnímu stringu
        zmìnìnému o nìkteré znaky a mùže tedy být kratší.
        Obèas pøeskoèí jedno písmeno, když se povedla
        komprimace dvou písmen. Vzhledem k aktuální délce l
        je tøeba skoèit o jeden krok navíc, navýšený
        funkcí copyByte2() +1. }
      while i <= l-step do
        begin
          i := i + step;
          { Jakmile navýším krok o dva, musím ho zase
            zmìnit na 1. Jinak se nenastaví n na pozitivní
            hodnotu a neprobìhne zamìòování pøi pøedposlední
            pozici (lookahead assertion).
          }
          step := 1;
          if i>=l then
             break;
          c := w[i];
          {NÁSLEDUJÍCÍ BLOCK KONTROLUJE NÁSLEDUJÍCÍ PÍSMENO n:
          Podívám se do pùvodního slova w, s tím že jedno
          písmeno mùže být vynecháno (i := i + step);
          }
          if ( i < l-step ) then  //@BYLO: i+1 < l-step
            begin
            n := w[i+1];
            if ( n > ENCODE_BYTE_RANGE + BYTE_SHIFT_DOWN ) or ( n < 44 ) then
              showMessage(MESSAGE_FORBIDDEN_CHAR + s + ':' + inttostr(n))
            else
              if ( n > 47 ) and ( n < ENCODE_BYTE_RANGE+1 ) then
                showMessage(MESSAGE_FORBIDDEN_CHAR + s + ':' + inttostr(n) );
            end
          else
            n := 0;  // JE NA KONCI ØETÌZCE (no next char on end of string)
          if ( c > ENCODE_BYTE_RANGE + BYTE_SHIFT_DOWN ) or ( c < 44 ) then
            showMessage(MESSAGE_FORBIDDEN_CHAR + s + inttostr(c))
          else
            if ( c > 47 ) and ( c < ENCODE_BYTE_RANGE+1 ) then
              showMessage(MESSAGE_FORBIDDEN_CHAR + s + inttostr(c));

          c := c - BYTE_SHIFT_DOWN;

          if n > 0 then
            begin
              n := n - BYTE_SHIFT_DOWN;
              if n = c then // znak se opakuje
                begin
                  c := c + 6*ENCODE_BYTE_RANGE;
                  copyByte2(c,wo,i,lw,wPointer, step);
                end
              else if n = 1 then // a
                begin
                  c := c + 1*ENCODE_BYTE_RANGE; // 13
                  copyByte2(c,wo,i,lw,wPointer, step);
                end
              else if n = 5 then // e
                begin
                  c := c + 2*ENCODE_BYTE_RANGE; // 53
                  copyByte2(c,wo,i,lw,wPointer, step);
                end
              else if n = 9 then // i
                begin
                  c := c + 3*ENCODE_BYTE_RANGE; // 60
                  copyByte2(c,wo,i,lw,wPointer, step);
                end
              else if n = 15 then // o
                begin
                  c := c + 4*ENCODE_BYTE_RANGE;; // 66
                  copyByte2(c,wo,i,lw,wPointer, step);
                end
              else if n = 21 then // u
                begin
                  c := c + 5*ENCODE_BYTE_RANGE;
                  copyByte2(c,wo,i,lw,wPointer, step);
                end
              else
                begin
                  copyByte2(c,wo,i,lw,wPointer, step);
                  step := 1;
                end;

            end
            else // n = 0
              begin
              // V pøípadì že se hodnota nemìní:
               copyByte2(c,wo,i,lw,wPointer, step);
               step := 1;
               { A) Byl pøeskoèen jeden znak (zkrácení øezìzce)
                 B) Není žádný další znak (tj. konec øetìzce)
                 C) Neprovádím lookahead assertion, proto
                    step := 1;
               }
              end;

        end; // konec slova

        // VLOŽENÍ ODDÌLOVAÈE
        c := 0;
        copyByte2(c,wo,i,lw,wPointer, step);

        Result := lw;
    end
  else
    begin // s length = 1
      setLength(wo,2);
      move(s[1],wo[0],1);
      wo[1] := 0;
      Result := 2;
    end;
end;

procedure decode(var wi: TBytes; var s:string);
var i: Integer;
    l,lastPositionS: byte;
    addedTwoCharsSignal: boolean;
    ps: string;
begin
  l := length(wi);
  if l=0 then exit;
  { PROCHÁZET VSTUPNÍ/PÙVODNÍ POLE }
  for i:= 0 to l-1 do
    begin
      addedTwoCharsSignal := false;
      if wi[i] = 0 then
         exit;
      // Perform replace of two bytes to one byte
      if wi[i] > ENCODE_BYTE_RANGE then
        begin // PÍSMENA NÁSLEDOVANÁ SAMOHLÁSKOU

        { addedTwoCharsSignal must be true in the case
          that I am adding one more character to
          chr(wi[i]) ... like this:
          s := s + chr(wi[i]) + 'u';
          in the case I am adding only one like this:
          s := s + chr(wi[i]);
          addedTwoCharsSignal is false
         }
          addedTwoCharsSignal := true;
          { Sice pøidám samohlásku, ale potøebuju znát
            pozici, na které budu mìnit znak a ta je pøed
            samohláskou!
            addedTwoCharsSignal must be true when using
            lastPositionS ... current postion information
          }
          lastPositionS := length(s);
          if (wi[i]-1) div ENCODE_BYTE_RANGE = 5 then // 21 - u
            begin
              wi[i] := wi[i]-ENCODE_BYTE_RANGE*5 + BYTE_SHIFT_DOWN;
              s := s + chr(wi[i]) + 'u';
            end
          else if (wi[i]-1) div ENCODE_BYTE_RANGE = 4  then // 15 - o
            begin
              wi[i] := wi[i]-ENCODE_BYTE_RANGE*4 + BYTE_SHIFT_DOWN;
              s := s + chr(wi[i]) + 'o';
            end
          else if (wi[i]-1) div ENCODE_BYTE_RANGE = 3  then // 9 - i
            begin
              wi[i] := wi[i]-ENCODE_BYTE_RANGE*3 + BYTE_SHIFT_DOWN;
              s := s + chr(wi[i]) + 'i';;
            end
          else if (wi[i]-1) div ENCODE_BYTE_RANGE = 2  then // 5 - e
            begin
              wi[i] := wi[i]-ENCODE_BYTE_RANGE*2 + BYTE_SHIFT_DOWN;
              s := s + chr(wi[i]) + 'e';
            end
          else if (wi[i]-1) div ENCODE_BYTE_RANGE = 1  then // 1 - a
            begin
              wi[i] := wi[i]-ENCODE_BYTE_RANGE + BYTE_SHIFT_DOWN;
              s := s + chr(wi[i]) + 'a';
            end
          else if (wi[i]-1) div ENCODE_BYTE_RANGE = 6  then // opakuje se
            begin
              wi[i] := wi[i]-ENCODE_BYTE_RANGE*6 + BYTE_SHIFT_DOWN;
              // NEVÍM JESLTI JE TO SPRÁVNÌ! @TODO
              s := s + chr(wi[i]) + chr(wi[i]);
              addedTwoCharsSignal := false;
            end
          else
            addedTwoCharsSignal := false;


          if addedTwoCharsSignal then
            begin
              ps := decodeReplace2(wi[i]);
              if length(ps)=2 then
                begin
                  s := copy(s,1,lastPositionS) + ps + copy(s,lastPositionS+2,1);
                end
              else
                s := s + ps;
            end
          else // Písmeno není v seznamu
            s[length(s)] := decodeReplace1(wi[i]);
        end
      else // Písmena, která nebyly následovány samohláskou
        if wi[i] < ENCODE_BYTE_RANGE+1 then
        begin
          ps := ' ';
          ps[1] := decodeReplace1(wi[i]+BYTE_SHIFT_DOWN);
          if ps[1]=#0 then
            s := s + decodeReplace2(wi[i]+BYTE_SHIFT_DOWN)
          else
            s := s + ps[1];
        end;

    end; // end for

end;

end.
