(*****************************************************************************/
/*                                                                           */
/*                             M O U S E                                     */
/*                                                                           */
/*  Program:      MOUSE                                                      */
/*                                                                           */
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
/*  Language:     Pascal                                                     */
/*                                                                           */
/*  Description:  This is an interpreter for the Mouse-83 programming        */
/*                language.                                                  */
/*                                                                           */
/*                Syntax:   MOUSE                                            */
/*                                                                           */
/*                Reads the file "test.mou"                                  */
******************************************************************************)
PROGRAM MouseInterpreter;

   CONST
      maxproglen = 2000;     {Maximum length of Mouse program}
      stacksize = 20;        {Maximum depth of calculation stack}
      envstacksize = 20;     {Maximum depth of environment stack}
      locsize = 26;          {Size of local variable space}
      maxaddr = 260;         {10 local variable spaces}
      halfwidth = 39;        {A number < half screen width}
      maxbyte = 255;         {Small positive integers}

   TYPE

      byte = 0 .. maxbyte;
      progindex = 0 .. maxproglen;
      tagtype = (macro, parameter, loop);
      environment = RECORD
                       tag     : tagtype;
                       charpos : 1 .. maxproglen;
                       offset  : 0 .. maxaddr
                    END;  {environment}

   VAR
      progfile : text;

      prog     : ARRAY [1 .. maxproglen] OF char;
      stack    : ARRAY [1 .. stacksize] OF integer;
      envstack : ARRAY [1 .. envstacksize] OF environment;
      data     : ARRAY [0 .. maxaddr] OF integer;
      macdefs  : ARRAY ['A'..'Z'] OF 0 .. maxproglen;

      ch : char;
      charpos, proglen : 0 .. maxproglen;
      sp : 0 .. stacksize;
      esp, tsp : 0 .. envstacksize;
      offset, nextfree, temp, parbal, parnum : integer;
      tracing, disaster : boolean;

{Display an environment; used for reporting errors and tracing.}

   PROCEDURE display (charpos : progindex);
      VAR pos : integer;
      BEGIN
         FOR pos := charpos - halfwidth TO charpos + halfwidth DO
            IF      (pos >= 1)
            AND     (pos <= proglen)
            AND     (prog[pos] >= ' ')  {ASCII graphic character}
               THEN write(prog[pos])
               ELSE write(' ');
         writeln;
         writeln(' ' : halfwidth,'^')
      END;   {display}

{ Report an error and set 'disaster' flag to stop the interpreter.}

   PROCEDURE error (code : byte);
      VAR tsp : byte;
      BEGIN
         writeln;
         FOR tsp := 1 TO esp DO
            display(envstack[tsp].charpos);
         display(charpos);
         write('Stack:');
         FOR tsp := 1 TO sp DO
            write(' ', stack[tsp]:1);
         writeln;
            write ('***** Error: ');
            CASE code OF
               1 : write('Ran off end of program');
               2 : write('Calculation stack overflowed');
               3 : write('Calculation stack underflowed');
               4 : write('Attempted to divide by zero');
               5 : write('Attempted to find modulus by zero');
               6 : write('Undefined macro');
               7 : write('Illegal character follows "#"');
               8 : write('Environment stack overflowed');
               9 : write('Environment stack underflowed');
              10 : write('Data space exhausted');
              11 : write('Illegal character');
            END; {CASE}
            writeln;
            disaster := true
         END;   {error}

{Get next character from program buffer and check for end of program.}

   PROCEDURE getchar;
      BEGIN
         IF charpos < proglen
            THEN
               BEGIN
                  charpos := charpos + 1;
                  ch := prog[charpos]
               END
            ELSE error(1)
         END;   {getchar}

{Backspace the character pointer.}

   PROCEDURE backspace;
      BEGIN
         charpos := charpos - 1
      END;   {backspace}

{Push an item onto the calculation stack and check for stack overflow.}

   PROCEDURE push (datum : integer);
      BEGIN
         IF sp < stacksize
            THEN
               BEGIN
                  sp := sp + 1;
                  stack[sp] := datum
               END
            ELSE error(2)
         END;   {push}

{Pop an item from the calculation stack; check for underflow.}

   FUNCTION pop: integer;
      BEGIN
         IF sp > 0
            THEN
               BEGIN
                  pop := stack[sp];
                  sp := sp - 1
               END
            ELSE error(3)
         END;   {pop}

{Skip over a string; " has been scanned on entry.}

   PROCEDURE skipstring;
      BEGIN
         REPEAT
            getchar
         UNTIL ch = '"'
      END;   {skipstring}

{Skip bracketed sequences; lch has been scanned on entry.}

   PROCEDURE skip (lch, rch : char);
      VAR count : byte;
      BEGIN
      count := 1;
      REPEAT
         getchar;
         IF ch = '"'
            THEN skipstring
         ELSE IF ch = lch
            THEN count := count + 1
         ELSE IF ch = rch
            THEN count := count - 1
      UNTIL count = 0
   END;   {skip}

{Return the binary value of an ASCII digit.}

   FUNCTION value (digit : char) : byte;
      BEGIN
         value := ord(digit) - ord('0')
      END;   {value}

{Convert a lower case letter to upper case.}

   PROCEDURE uppercase;
      BEGIN
         IF ch IN ['a'..'z']
            THEN ch := chr(ord(ch) - ord('a') + ord('A'))
      END;   {uppercase}

{Push an environment; check for environment stack overflow.}

   PROCEDURE pushenv (tag : tagtype);
      BEGIN
         IF esp < envstacksize
            THEN
               BEGIN
                  esp := esp + 1;
                  envstack[esp].tag := tag;
                  envstack[esp].charpos := charpos;
                  envstack[esp].offset := offset
               END
            ELSE error(8)
      END;   {pushenv}

{Pop an environment; check for environment stack underflow.}

   PROCEDURE popenv;
      BEGIN
         IF esp > 0
            THEN
               BEGIN
                  charpos := envstack[esp].charpos;
                  offset := envstack[esp].offset;
                  esp := esp - 1
               END
            ELSE error(9)
      END;   {popenv}

{The Loader.}

   PROCEDURE load;
      BEGIN
         FOR charpos := 1 TO maxproglen DO
            prog[charpos] := ' ';
         reset(progfile);
         charpos := 0;
         disaster := false;
         WHILE NOT (eof(progfile) OR disaster) DO
            BEGIN
               read(progfile,ch);
               IF ch = '~'
                  THEN readln(progfile)
               ELSE IF charpos < maxproglen
                  THEN
                     BEGIN
                        charpos := charpos + 1;
                        prog[charpos] := ch
                     END
               ELSE
                  BEGIN
                     writeln('Program is too long');
                     disaster := true
                  END
            END;   {WHILE}
         proglen := charpos
      END;   {load}

{Construct macro definition table.}

   PROCEDURE makedeftable;
      BEGIN
         FOR ch := 'A' TO 'Z' DO
            macdefs[ch] := 0;
         charpos := 0;
         REPEAT
            getchar;
            IF ch = '$'
               THEN
                  BEGIN
                     getchar;
                     uppercase;
                     IF ch IN ['A'..'Z']
                        THEN macdefs[ch] := charpos
                  END
         UNTIL charpos = proglen
      END;   {makedeftable}

{The Interpreter.}

   PROCEDURE interpret;
      BEGIN
         charpos := 0;
         sp := 0;
         esp := 0;
         offset := 0;
         nextfree := locsize;
         REPEAT
            getchar;
            IF tracing AND (ch <> ' ')
               THEN display(charpos);
            CASE ch OF
               ' ' : ;                   {No action}
               chr(10) : ;               {No action}
               chr(13) : ;               {No action}
               '$' : ;                   {No action}
               '0'..'9' :                {Encode a decimal number}
                  BEGIN
                     temp := 0;
                     WHILE ch IN ['0'..'9'] DO
                        BEGIN
                           temp := 10 * temp + value(ch);
                           getchar
                        END;   {WHILE}
                     push(temp);
                     backspace
                  END;
               '+' : push(pop + pop);     {Add}
               '-' :                      {Subtract}
                  BEGIN
                     temp := pop;
                     push(pop - temp);
                  END;
               '*' : push(pop * pop);     {Multiply}
               '/' :                      {Divide with zero check}
                  BEGIN
                     temp := pop;
                     IF temp <> 0
                        THEN push(pop DIV temp)
                        ELSE error(4)
                  END;
               '\' :                      {Remainder with zero check}
                  BEGIN
                     temp := pop;
                     IF temp <> 0
                        THEN push(pop MOD temp)
                        ELSE error(5)
                  END;
               '?' :                      {Read character or}
                  BEGIN                   {number from keyboard}
                     getchar;
                     IF ch = ''''
                        THEN
                           BEGIN
                              read(ch);
                              push(ord(ch))
                           END
                        ELSE
                           BEGIN
                              read(temp);
                              push(temp);
                              backspace
                           END
                  END;
               '!' :                      {Display character}
                  BEGIN                   {or number on screen}
                     getchar;
                     IF ch = ''''
                        THEN write(chr(pop))
                        ELSE
                           BEGIN
                              write(pop:1);
                              backspace
                           END
                  END;
               '"' :
                  REPEAT
                     getchar;
                     IF ch = '!'
                        THEN writeln
                     ELSE IF ch <> '"'
                        THEN write(ch)
                  UNTIL ch = '"';
               'A'..'Z' : push(ord(ch) - ord('A') + offset);
               'a'..'z' : push(ord(ch) - ord('a') + offset);
               ':' :                      {Assignment}
                  BEGIN
                     temp := pop;
                     data[temp] := pop;
                  END;
               '.' : push(data[pop]);     {Dereference}
               '<' :
                  BEGIN
                     temp := pop;
                     push(ord(pop < temp));
                  END;
               '=' : push(ord(pop = pop));
               '>' :
                  BEGIN
                     temp := pop;
                     push(ord(pop > temp));
                  END;
               '[' : IF pop <= 0          {Conditional statement}
                        THEN skip('[',']');
               ']' : ;                    {No action}
               '(' : pushenv(loop);       {Begin loop}
               ')' :                      {End loop}
                  charpos := envstack[esp].charpos + 1;
               '^' : IF pop <= 0          {Exit loop}
                        THEN
                           BEGIN
                              popenv;
                              skip('(',')')
                           END;
               '#':                       {Macro call}
                  BEGIN
                     getchar;
                     uppercase;
                     IF ch IN ['A'..'Z']
                        THEN
                           IF macdefs[ch] > 0
                              THEN
                                 BEGIN
                                    pushenv(macro);
                                    charpos := macdefs[ch];
                                    IF nextfree + locsize <= maxaddr
                                       THEN
                                          BEGIN
                                             offset := nextfree;
                                             nextfree := nextfree + locsize
                                          END
                                       ELSE error(10)
                                 END
                              ELSE error(6)
                        ELSE error(7)
                  END;
               '@':                       {Return from macro}
                  BEGIN
                     popenv;
                     skip('#',';');
                     nextfree := nextfree - locsize
                  END;
               '%':                       {Replace formal by actual}
                  BEGIN
                     pushenv(parameter);
                     parbal := 1;
                     tsp := esp;
                     REPEAT
                        tsp := tsp - 1;   {Search in stack...}

                        CASE envstack[tsp].tag OF
                           macro : parbal := parbal - 1;
                           parameter : parbal := parbal + 1;
                           loop:
                        END   {CASE}
                     UNTIL parbal = 0;    {...for call environment}
                     charpos := envstack[tsp].charpos;
                     offset := envstack[tsp].offset;
                     parnum := pop;       {Get parameter number}
                     REPEAT
                        getchar;
                        IF ch = '"'
                           THEN skipstring
                        ELSE IF ch = '#'
                           THEN skip('#',';')
                        ELSE IF ch = ','
                           THEN parnum := parnum - 1
                        ELSE IF ch = ';'
                           THEN
                              BEGIN
                                 parnum := 0;
                                 popenv   {Null parameter}
                              END
                     UNTIL parnum = 0
                  END;
               ',',                       {End of actual parameter}
               ';'  : popenv;             {End of macro call}
               ''''  :                    {Stack next character}
                  BEGIN
                     getchar;
                     push(ord(ch))
                  END;
               '{' : tracing := true;
               '}' : tracing := false;
               '`',                       {Unused characters}
               '&',
               '|',
               '_' :  error(11);
               ELSE error(11)
            END;   {CASE}
         UNTIL (ch = '$') OR disaster
      END;   {interpret}

{Main program}

   BEGIN
      assign(progfile, 'test.mou');
      load;
      IF NOT disaster
         THEN
            BEGIN
               makedeftable;
               interpret
            END

END.   {MouseInterpreter}
