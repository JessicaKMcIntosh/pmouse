(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Program:      PMOUSE - Pascal Mouse                                      */
/*                                                                           */
/*  Originally by:                                                           */
/*  Programmer:   Dr Peter Grogono                                           */
/*                MOUSE: A Language for Microcomputers                       */
/*                Petrocelli Books, 1983                                     */
/*                                                                           */
/*  Translated from the book and corrections by:                             */
/*  Programmer:   David G. Simpson                                           */
/*                Laurel, Maryland                                           */
/*                February 3, 2002                                           */
/*                http://mouse.davidgsimpson.com/                            */
/*                                                                           */
/*  Further updates by:                                                      */
/*  Programmer:   Jessica K McIntosh                                         */
/*                https://github.com/JessicaKMcIntosh/pmouse                 */
/*                                                                           */
/*  Language:     Pascal                                                     */
/*                                                                           */
/*  Description:  This is an interpreter for the Mouse-83 programming        */
/*                language.                                                  */
/*                                                                           */
/*  Notes:        This interpreter is based on the original Pascal           */
/*                implementation in "Mouse: A Language for Microcomputers"   */
/*                by Peter Grogono.                                          */
/*                                                                           */
/*                Syntax:   MOUSE  <filename>                                */
/*                                                                           */
/*                If no file extension is given, an extension of ".mou" is   */
/*                assumed.                                                   */
/*                                                                           */
******************************************************************************)
program PMOUSE;

const
  maxproglen    = 2000;     { Maximum length of Mouse program }
  stacksize     = 1024;     { Maximum depth of calculation stack }
  envstacksize  = 1024;     { Maximum depth of environment stack }
  locsize       = 26;       { Size of local variable space }
  maxaddr       = 1300;     { 50 local variable spaces }
  halfwidth     = 39;       { A number < half screen width }
  maxbyte       = 255;      { Small positive integers }
  filelength    = 255;      { Maximum length of a file name. }
  mouseext      = '.mou';   { Mouse program extension. }

type
  byte      = 0 .. maxbyte;
  progindex = 0 .. maxproglen;
  tagtype   = (macro, parameter, loop);
  filename  = string[filelength];

  environment = record
    tag     : tagtype;
    charpos : 1 .. maxproglen;
    offset  : 0 .. maxaddr
  end;  { environment }

var
  progfile: Text;

  prog      : array [1 .. maxproglen] of char;
  stack     : array [1 .. stacksize] of integer;
  envstack  : array [1 .. envstacksize] of environment;
  Data      : array [0 .. maxaddr] of integer;
  macdefs   : array ['A'..'Z'] of 0 .. maxproglen;

  ch          : char;             { Character currently being processed. }
  charpos,                        { Current position in the program. }
  proglen     : 0 .. maxproglen;  { Length of the program. }
  sp          : 0 .. stacksize;   { Stack pointer. }
  esp,                            { Environment stack pointer. }
  tsp         : 0 .. envstacksize;
  offset,
  nextfree,
  temp,                           { Temporary value during interpretation. }
  parbal,
  parnum      : integer;
  tracing,                        { If true tracing is enabled. }
  disaster    : boolean;          { If true a critical error has occurred. }

{ Display an environment; used for reporting errors and tracing. }
procedure display(charpos: progindex);
var
  pos: integer;
begin
  for pos := charpos - halfwidth to charpos + halfwidth do
    { ASCII graphic character }
    if (pos >= 1) and (pos <= proglen) and (prog[pos] >= ' ') then
      write(prog[pos])
    else
      write(' ');
  writeln;
  writeln(' ': halfwidth, '^');
end;   { display }

{ Report an error and set 'disaster' flag to stop the interpreter. }
procedure error(code: byte);
var
  tsp: byte;
begin
  writeln;
  for tsp := 1 to esp do
    display(envstack[tsp].charpos);
  display(charpos);
  write('Stack:');
  for tsp := 1 to sp do
    write(' ', stack[tsp]: 1);
  writeln;
  write('***** Error: ');
  case code of
    1: write('Ran off end of program');
    2: write('Calculation stack overflowed');
    3: write('Calculation stack underflowed');
    4: write('Attempted to divide by zero');
    5: write('Attempted to find modulus by zero');
    6: write('Undefined macro');
    7: write('Illegal character follows "#"');
    8: write('Environment stack overflowed');
    9: write('Environment stack underflowed');
    10: write('Data space exhausted');
    11: write('Illegal character');
  end; { CASE }
  writeln;
  disaster := true;
end;   { error }

{ Get next character from program buffer and check for end of program. }
procedure getchar;
begin
  if charpos < proglen then
  begin
    charpos := charpos + 1;
    ch := prog[charpos];
  end
  else
    error(1);
end;   { getchar }

{ Backspace the character pointer. }
procedure backspace;
begin
  charpos := charpos - 1;
end;   { backspace }

{ Push an item onto the calculation stack and check for stack overflow. }
procedure push(datum: integer);
begin
  if sp < stacksize then
  begin
    sp := sp + 1;
    stack[sp] := datum;
  end
  else
    error(2);
end;   { push }

{ Pop an item from the calculation stack; check for underflow. }
function pop: integer;
begin
  if sp > 0 then
  begin
    pop := stack[sp];
    sp := sp - 1;
  end
  else
    error(3);
end;   { pop }

{ Skip over a string; " has been scanned on entry. }
procedure skipstring;
begin
  repeat
    getchar
  until ch = '"';
end;   { skipstring }

{ Skip bracketed sequences; lch has been scanned on entry. }
procedure skip(lch, rch: char);
var
  Count: byte;
begin
  Count := 1;
  repeat
    getchar;
    if ch = '"' then
      skipstring
    else if ch = lch then
      Count := Count + 1
    else if ch = rch then
      Count := Count - 1
  until Count = 0;
end;   { skip }

{ Return the binary value of an ASCII digit. }
function Value(digit: char): byte;
begin
  Value := Ord(digit) - Ord('0');
end;   { value }

{ Convert a lower case letter to upper case. }
procedure uppercase;
begin
  if ch in ['a'..'z'] then
    ch := chr(Ord(ch) - Ord('a') + Ord('A'));
end;   { uppercase }

{ Push an environment; check for environment stack overflow. }
procedure pushenv(tag: tagtype);
begin
  if esp < envstacksize then
  begin
    esp := esp + 1;
    envstack[esp].tag := tag;
    envstack[esp].charpos := charpos;
    envstack[esp].offset := offset;
  end
  else
    error(8);
end;   { pushenv }

{ Pop an environment; check for environment stack underflow. }
procedure popenv;
begin
  if esp > 0 then
  begin
    charpos := envstack[esp].charpos;
    offset := envstack[esp].offset;
    esp := esp - 1;
  end
  else
    error(9);
end;   { popenv }

{ The Loader. }
procedure load;
begin
  for charpos := 1 to maxproglen do
    prog[charpos] := ' ';
  charpos := 0;
  disaster := false;
  while not (EOF(progfile) or disaster) do
  begin
    read(progfile, ch);
    if ch < ' ' then
      ch := ' ';
    if ch = '~' then
      readln(progfile)
    else if charpos < maxproglen then
    begin
      charpos := charpos + 1;
      prog[charpos] := ch;
    end
    else
    begin
      writeln('Program is too long');
      disaster := true;
    end;
  end;   { WHILE }
  proglen := charpos;
end;   { load }

{ Construct macro definition table. }
procedure makedeftable;
begin
  for ch := 'A' to 'Z' do
    macdefs[ch] := 0;
  charpos := 0;
  repeat
    getchar;
    if ch = '$' then
    begin
      getchar;
      uppercase;
      if ch in ['A'..'Z'] then
        macdefs[ch] := charpos;
    end
  until charpos = proglen;
end;   { makedeftable }

{ The Interpreter. }
procedure interpret;
begin
  charpos := 0;
  sp := 0;
  esp := 0;
  offset := 0;
  nextfree := locsize;
  repeat
    getchar;
    if tracing and (ch <> ' ') then
      display(charpos);
    case ch of
      ' ': ;                    { No action }
      '$': ;                    { No action }
      '0'..'9':                 { Encode a decimal number }
      begin
        temp := 0;
        while ch in ['0'..'9'] do
        begin
          temp := 10 * temp + Value(ch);
          getchar;
        end;   { WHILE }
        push(temp);
        backspace;
      end;
      '+': push(pop + pop);     { Add }
      '-':                      { Subtract }
      begin
        temp := pop;
        push(pop - temp);
      end;
      '*': push(pop * pop);     { Multiply }
      '/':                      { Divide with zero check }
      begin
        temp := pop;
        if temp <> 0 then
          push(pop div temp)
        else
          error(4);
      end;
      '\':                      { Remainder with zero check }
      begin
        temp := pop;
        if temp <> 0 then
          push(pop mod temp)
        else
          error(5);
      end;
      '?':                      { Read character or }
      begin                     { number from keyboard }
        getchar;
        if ch = '''' then
        begin
          read(ch);
          push(Ord(ch));
        end
        else
        begin
          read(temp);
          push(temp);
          backspace;
        end;
      end;
      '!':                      { Display character }
      begin                     { or number on screen }
        getchar;
        if ch = '''' then
          write(chr(pop))
        else
        begin
          write(pop: 1);
          backspace;
        end;
      end;
      '"': repeat
          getchar;
          if ch = '!' then
            writeln
          else if ch <> '"' then
            write(ch)
        until ch = '"';
      'A'..'Z': push(Ord(ch) - Ord('A') + offset);
      'a'..'z': push(Ord(ch) - Ord('a') + offset);
      ':':                      { Assignment }
      begin
        temp := pop;
        Data[temp] := pop;
      end;
      '.': push(Data[pop]);     { Dereference }
      '<':
      begin
        temp := pop;
        push(Ord(pop < temp));
      end;
      '=': push(Ord(pop = pop));
      '>':
      begin
        temp := pop;
        push(Ord(pop > temp));
      end;
      '[': if pop <= 0 then     { Conditional statement }
          skip('[', ']');
      ']': ;                    { No action }
      '(': pushenv(loop);       { Begin loop }
      ')': charpos := envstack[esp].charpos; { End loop }
      '^': if pop <= 0 then     { Exit loop }
        begin
          popenv;
          skip('(', ')');
        end;
      '#':                      { Macro call }
      begin
        getchar;
        uppercase;
        if ch in ['A'..'Z'] then
          if macdefs[ch] > 0 then
          begin
            pushenv(macro);
            charpos := macdefs[ch];
            if nextfree + locsize <= maxaddr then
            begin
              offset := nextfree;
              nextfree := nextfree + locsize;
            end
            else
              error(10);
          end
          else
            error(6)
        else
          error(7);
      end;
      '@':                      { Return from macro }
      begin
        popenv;
        skip('#', ';');
        nextfree := nextfree - locsize;
      end;
      '%':                      { Replace formal by actual }
      begin
        pushenv(parameter);
        parbal := 1;
        tsp := esp;
        repeat
          tsp := tsp - 1;       { Search in stack... }

          case envstack[tsp].tag of
            macro: parbal := parbal - 1;
            parameter: parbal := parbal + 1;
            loop: end   { CASE }
        until parbal = 0;       { ...for call environment }
        charpos := envstack[tsp].charpos;
        offset := envstack[tsp].offset;
        parnum := pop;          { Get parameter number }
        repeat
          getchar;
          if ch = '"' then
            skipstring
          else if ch = '#' then
            skip('#', ';')
          else if ch = ',' then
            parnum := parnum - 1
          else if ch = ';' then
          begin
            parnum := 0;
            popenv;   { Null parameter }
          end
        until parnum = 0;
      end;
      ',',                      { End of actual parameter }
      ';': popenv;              { End of macro call }
      '''':                     { Stack next character }
      begin
        getchar;
        push(Ord(ch));
      end;
      '{': tracing := true;
      '}': tracing := false;
      '`',                      { Unused characters }
      '&',
      '|',
      '_': error(11);
      else error(11)
    end;   { CASE }
  until (ch = '$') or disaster;
end;   { interpret }

{ Open the program file. }
{ If the file is not found retries with the mouse file extension. }
function openfile(mousefile: filename): boolean;
begin
  assign(progfile, mousefile);
  {$I-}
  reset(progfile);
  {$I+}
  if IOResult <> 0 then
  begin
    mousefile := mousefile + mouseext;
    assign(progfile, mousefile);
    {$I-}
    reset(progfile);
    {$I+}
  end;
  openfile := IOResult = 0;
end;

{ Main program }
begin
  { Open the file passed on the command line. }
  if paramcount = 0 then begin
    writeln('The file name must be provided.');
    halt(1);
  end;
  if not openfile(paramstr(1)) then
  begin
    writeln('Unable to open the program: ', paramstr(1));
    halt(1)
  end;

  load;
  if not disaster then
  begin
    makedeftable;
    interpret;
  end;
end.   { MouseInterpreter }
