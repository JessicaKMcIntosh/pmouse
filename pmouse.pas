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
  MaxProgLen    = 2000;     { Maximum length of Mouse program }
  StackSize     = 1024;     { Maximum depth of calculation stack }
  EnvStackSize  = 1024;     { Maximum depth of environment stack }
  LocalVarSize  = 26;       { Size of local variable space }
  MaxAddress    = 1300;     { 50 local variable spaces }
  HalfWidth     = 39;       { A number < half screen width }
  MaxByte       = 255;      { Small positive integers }
  FileLength    = 255;      { Maximum length of a file name. }
  MouseExt      = '.mou';   { Mouse program extension. }

type
  byte      = 0 .. MaxByte;
  ProxIndex = 0 .. MaxProgLen;
  TagType   = (Macro, Parameter, Loop);
  FileName  = string[FileLength];

  Environment = record
    Tag     : TagType;
    CharPos : 1 .. MaxProgLen;
    Offset  : 0 .. MaxAddress
  end;  { Environment }

var
  ProgFile: Text;

  Prog      : array [1 .. MaxProgLen] of char;
  Stack     : array [1 .. StackSize] of integer;
  EnvStack  : array [1 .. EnvStackSize] of Environment;
  Data      : array [0 .. MaxAddress] of integer;
  MacroDefs : array ['A'..'Z'] of 0 .. MaxProgLen;

  CH            : char;             { Character currently being processed. }
  CharPos,                          { Current position in the program. }
  ProgLen       : 0 .. MaxProgLen;  { Length of the program. }
  StackPointer  : 0 .. StackSize;   { Stack pointer. }
  EStackPointer,                    { Environment stack pointer. }
  TStackPointer : 0 .. EnvStackSize;{ Temporary stack Pointer. }
  Offset        : integer;          { Memory offset for environments. }
  Tracing,                          { If true tracing is enabled. }
  DumpProg,                         { If true dump the program after reading. }
  Disaster      : boolean;          { If true a critical error has occurred. }

{ Utilities for detecting a character type. }
function isdigit(check: char): boolean;
begin
  isdigit := check in ['0'..'9'];
end;
function islower(check: char): boolean;
begin
  islower := check in ['a'..'z'];
end;
function isupper(check: char): boolean;
begin
  isupper := check in ['A'..'Z'];
end;

{ Display an environment; used for reporting errors and tracing. }
procedure display(CharPos: ProxIndex);
var
  pos: integer;
begin
  for pos := CharPos - HalfWidth to CharPos + HalfWidth do
    { ASCII graphic character }
    if (pos >= 1) and (pos <= ProgLen) and (Prog[pos] >= ' ') then
      write(Prog[pos])
    else
      write(' ');
  writeln;
  write(' ': HalfWidth, '^ SP: ', StackPointer, ' Stack: ');
  if StackPointer = 0 then
    write('NULL')
  else
  begin
    write(Stack[StackPointer]);
    if StackPointer > 1 then
    begin
      pos := 1;
      repeat
        write(', ', Stack[StackPointer - pos]);
        pos := succ(pos);
      until ((StackPointer - pos) < 1) or (pos = 5);
    end;
  end;
  writeln;
end;   { display }

{ Report an error and set 'Disaster' flag to stop the interpreter. }
procedure error(code: byte);
var
  TStackPointer: byte;
begin
  writeln;
  for TStackPointer := 1 to EStackPointer do
    display(EnvStack[TStackPointer].CharPos);
  display(CharPos);
  write('Stack:');
  for TStackPointer := 1 to StackPointer do
    write(' ', Stack[TStackPointer]: 1);
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
  Disaster := true;
end;   { error }

{ Get next character from program buffer and check for end of program. }
procedure getchar;
begin
  if CharPos < ProgLen then
  begin
    CharPos := CharPos + 1;
    CH := Prog[CharPos];
  end
  else
    error(1);
end;   { getchar }

{ Backspace the character pointer. }
procedure backspace;
begin
  CharPos := CharPos - 1;
end;   { backspace }

{ Push an item onto the calculation stack and check for stack overflow. }
procedure push(datum: integer);
begin
  if StackPointer < StackSize then
  begin
    StackPointer := StackPointer + 1;
    Stack[StackPointer] := datum;
  end
  else
    error(2);
end;   { push }

{ Pop an item from the calculation stack; check for underflow. }
function pop: integer;
begin
  if StackPointer > 0 then
  begin
    pop := Stack[StackPointer];
    StackPointer := StackPointer - 1;
  end
  else
    error(3);
end;   { pop }

{ Skip over a string; " has been scanned on entry. }
procedure skipstring;
begin
  repeat
    getchar
  until CH = '"';
end;   { skipstring }

{ Skip bracketed sequences; lch has been scanned on entry. }
procedure skip(lch, rch: char);
var
  Count: byte;
begin
  Count := 1;
  repeat
    getchar;
    if CH = '"' then
      skipstring
    else if CH = lch then
      Count := Count + 1
    else if CH = rch then
      Count := Count - 1
  until Count = 0;
end;   { skip }

{ Skip bracketed sequences; lch has been scanned on entry. }
procedure skip2(lch, rch1, rch2: char);
var
  Count: byte;
begin
  Count := 1;
  repeat
    getchar;
    if CH = '"' then
      skipstring
    else if CH = lch then
      Count := Count + 1
    else if (CH = rch1) or (CH = rch2) then
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
  if islower(CH) then
    CH := chr(Ord(CH) - Ord('a') + Ord('A'));
end;   { uppercase }

{ Push an environment; check for environment stack overflow. }
procedure pushenv(Tag: TagType);
begin
  if EStackPointer < EnvStackSize then
  begin
    EStackPointer := EStackPointer + 1;
    EnvStack[EStackPointer].Tag := Tag;
    EnvStack[EStackPointer].CharPos := CharPos;
    EnvStack[EStackPointer].Offset := Offset;
  end
  else
    error(8);
end;   { pushenv }

{ Pop an environment; check for environment stack underflow. }
procedure popenv;
begin
  if EStackPointer > 0 then
  begin
    CharPos := EnvStack[EStackPointer].CharPos;
    Offset := EnvStack[EStackPointer].Offset;
    EStackPointer := EStackPointer - 1;
  end
  else
    error(9);
end;   { popenv }

{ The Loader. }
procedure load;
var
  Prev      : char;
  InString  : boolean;
begin
  { Fill the program memory with blanks. }
  fillchar(Prog, MaxProgLen, ' ');

  { Initialize the variables.}
  CH := '~';
  InString := false;
  Disaster := false;
  CharPos := 0;

  { Read the program file. }
  while not (EOF(ProgFile) or Disaster) do
  begin
    Prev := CH;
    read(ProgFile, CH);
    if CH = '~' then
      readln(ProgFile)
    else if CharPos < MaxProgLen then
    begin
      CharPos := CharPos + 1;
      { Keep track of when inside a string for optimizations. }
      if CH = '"' then
        InString := not InString;
      { Change any control characters to space. }
      if CH < ' ' then
        CH := ' ';
      { Save the cahracter to the program. }
      Prog[CharPos] := CH;

      { Perform some optimization to remove extra blanks. }
      if not InString then
      begin
        if (CH = ' ') and not isdigit(Prev) and (Prev <> '''') and (Prev <> '$')  then
          begin
            CharPos := pred(CharPos);
            CH := Prog[CharPos];
          end
        else
        if  (prev = ' ') and
            not isdigit(CH) and
            (CH <> '"') and
            (Prog[CharPos - 2] <> '''') and
            (Prog[CharPos - 2] <> '$')
          then
          begin
            CharPos := pred(CharPos);
            Prog[CharPos] := CH;
          end;
      end;
    end
    else
    begin
      writeln('Program is too long');
      Disaster := true;
    end;
  end;   { while not (EOF(ProgFile) or Disaster) }
  ProgLen := CharPos + 1;
  if DumpProg then
    begin
      writeln('Program after loading:');
      for CharPos := 0 to ProgLen do
        write(Prog[CharPos]);
      writeln('');
      writeln('');
    end;
end;   { load }

{ Construct macro definition table. }
procedure makedeftable;
begin
  for CH := 'A' to 'Z' do
    MacroDefs[CH] := 0;
  CharPos := 0;
  repeat
    getchar;
    if CH = '$' then
    begin
      getchar;
      uppercase;
      if isupper(CH) then
        MacroDefs[CH] := CharPos;
    end
  until CharPos = ProgLen;
end;   { makedeftable }

{ The Interpreter. }
procedure interpret;
var
  NextFree,               { Next free memory offset. }
  ParmBal,                { Used for matching parameters. }
  ParmNum,                { Parameter Number. }
  TempInt     : integer;  { Temporary value. }

begin
  CharPos := 0;
  StackPointer := 0;
  EStackPointer := 0;
  Offset := 0;
  NextFree := LocalVarSize;
  repeat
    getchar;
    if Tracing and (CH <> ' ') then
      display(CharPos);
    case CH of
      ' ': ;                    { No action }
      '$': ;                    { No action }
      '0'..'9':                 { Encode a decimal number }
      begin
        TempInt := 0;
        while isdigit(CH) do
        begin
          TempInt := 10 * TempInt + Value(CH);
          getchar;
        end;   { while isdigit(CH) }
        push(TempInt);
        backspace;
      end;
      '+': push(pop + pop);     { Add }
      '-':                      { Subtract }
      begin
        TempInt := pop;
        push(pop - TempInt);
      end;
      '*': push(pop * pop);     { Multiply }
      '/':                      { Divide with zero check }
      begin
        TempInt := pop;
        if TempInt <> 0 then
          push(pop div TempInt)
        else
          error(4);
      end;
      '\':                      { Remainder with zero check }
      begin
        TempInt := pop;
        if TempInt <> 0 then
          push(pop mod TempInt)
        else
          error(5);
      end;
      '?':                      { Read character or }
      begin                     { number from keyboard }
        getchar;
        if CH = '''' then
        begin
          read(CH);
          { This is a hack to make pmouse act like the C version.
            For whatever reason when the C version reaches a newline
            the newline is replaced with a single quote, ASCII 39.
            With this change the expr.mou example will work now.
          }
          if (CH = #13) or (CH = #10) then
            CH := '''';
          push(Ord(CH));
        end
        else
        begin
          read(TempInt);
          push(TempInt);
          backspace;
        end;
      end;
      '!':                      { Display character }
      begin                     { or number on screen }
        getchar;
        if CH = '''' then
          write(chr(pop))
        else
        begin
          write(pop: 1);
          backspace;
        end;
      end;
      '"': repeat
          getchar;
          if CH = '!' then
            writeln
          else if CH <> '"' then
            write(CH)
        until CH = '"';
      'A'..'Z': push(Ord(CH) - Ord('A'));
      'a'..'z': push(Ord(CH) - Ord('a') + Offset);
      ':':                      { Assignment }
      begin
        TempInt := pop;
        Data[TempInt] := pop;
      end;
      '.': push(Data[pop]);     { Dereference }
      '<':
      begin
        TempInt := pop;
        push(Ord(pop < TempInt));
      end;
      '=': push(Ord(pop = pop));
      '>':
      begin
        TempInt := pop;
        push(Ord(pop > TempInt));
      end;
      '[': if pop <= 0 then     { Conditional statement }
          skip2('[', '|', ']');
      ']': ;                    { No action }
      '|': skip('[', ']');      { Else }
      '(': pushenv(Loop);       { Begin loop }
      ')': CharPos := EnvStack[EStackPointer].CharPos; { End loop }
      '^': if pop <= 0 then     { Exit loop }
        begin
          popenv;
          skip('(', ')');
        end;
      '#':                      { Macro call }
      begin
        getchar;
        uppercase;
        if isupper(CH) then
          if MacroDefs[CH] > 0 then
          begin
            pushenv(Macro);
            CharPos := MacroDefs[CH];
            if NextFree + LocalVarSize <= MaxAddress then
            begin
              Offset := NextFree;
              NextFree := NextFree + LocalVarSize;
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
        NextFree := NextFree - LocalVarSize;
      end;
      '%':                      { Replace formal by actual }
      begin
        pushenv(Parameter);
        ParmBal := 1;
        TStackPointer := EStackPointer;
        repeat                  { Search in stack... }
          TStackPointer := TStackPointer - 1;

          case EnvStack[TStackPointer].Tag of
            Macro: ParmBal := ParmBal - 1;
            Parameter: ParmBal := ParmBal + 1;
            Loop: end   { case EnvStack[TStackPointer].Tag }
        until ParmBal = 0;      { ...for call environment }
        CharPos := EnvStack[TStackPointer].CharPos;
        Offset := EnvStack[TStackPointer].Offset;
        ParmNum := pop;         { Get parameter number }
        repeat
          getchar;
          if CH = '"' then
            skipstring
          else if CH = '#' then
            skip('#', ';')
          else if CH = ',' then
            ParmNum := ParmNum - 1
          else if CH = ';' then
          begin
            ParmNum := 0;
            popenv;             { Null parameter }
          end
        until ParmNum = 0;
      end;
      ',',                      { End of actual parameter }
      ';': popenv;              { End of macro call }
      '''':                     { Stack next character }
      begin
        getchar;
        push(Ord(CH));
      end;
      '{': Tracing := true;
      '}': Tracing := false;
      '`',                      { Unused characters }
      '&',
      '_': error(11);
      else error(11)
    end;   { CASE }
  until (CH = '$') or Disaster;
end;   { interpret }

{ Open the program file. }
{ If the file is not found retries with the mouse file extension. }
function openfile(mousefile: FileName): boolean;
begin
  assign(ProgFile, mousefile);
  {$I-}
  reset(ProgFile);
  {$I+}
  if IOResult <> 0 then
  begin
    mousefile := mousefile + MouseExt;
    assign(ProgFile, mousefile);
    {$I-}
    reset(ProgFile);
    {$I+}
  end;
  openfile := IOResult = 0;
end;

{ Process command line parameters. }
procedure processparameters;
var
  paramnum  : Integer;
  Parameter : FileName;
  stop      : boolean;
begin
  paramnum  := 1;
  stop      := false;

  { Process command line parameters. }
  repeat
    Parameter := paramstr(paramnum);
    if Parameter[1] = '-' then
      begin
        case Parameter[2] of
          '-': stop := true;
          'd': DumpProg := true;
          't': Tracing := true;
        end;
        paramnum := succ(paramnum);
      end else
        stop := true;
  until (stop or (paramnum <= paramcount));

  { Check if there are more parameters for a file. }
  if paramnum > paramcount then begin
    writeln('The file name must be provided.');
    halt(1);
  end;

  { Attempt to open the file. }
  Parameter := paramstr(paramnum);
  if not openfile(Parameter) then
  begin
    writeln('Unable to open the program: ', Parameter);
    halt(1)
  end;
end;

{ Main program }
begin
  { Default to tracing off. }
  Tracing := False;

  { Process the command line parameters. }
  processparameters;

  { Load the program file. }
  load;

  { If the program file loaded successfully then start interpreting. }
  if not Disaster then
  begin
    makedeftable;
    interpret;
  end;
end.   { MouseInterpreter }
