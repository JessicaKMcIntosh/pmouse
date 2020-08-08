/*****************************************************************************/
/*                                                                           */
/*                               M O U S E                                   */
/*                                                                           */
/*  Program:      MOUSE                                                      */
/*                                                                           */
/*  Programmer:   David G. Simpson                                           */
/*                Laurel, Maryland                                           */
/*                February 3, 2002                                           */
/*                                                                           */
/*  Language:     C                                                          */
/*                                                                           */
/*  Description:  This is an interpreter for the Mouse-2002 programming      */
/*                language.                                                  */
/*                                                                           */
/*  Version:      19  (April 1, 2007)                                        */
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
/*****************************************************************************/

/*****************************************************************************/
/*  #includes                                                                */
/*****************************************************************************/

#include <stdio.h>                          /* standard i/o                  */
#include <stdlib.h>                         /* standard library              */
#include <string.h>                         /* string functions              */
#include <ctype.h>                          /* character functions           */
#include <math.h>                           /* mathematical functions        */
#include <time.h>                           /* time functions                */



/*****************************************************************************/
/*  #defines                                                                 */
/*****************************************************************************/

#define  MAXPROGLEN   10000                 /* max length of Mouse program   */
#define  MAXPROGLINELEN 132                 /* max length of interactive line*/
#define  STACKSIZE     1024                 /* maximum depth of calc stack   */
#define  ENVSTACKSIZE  1024                 /* maximum depth of env stack    */
#define  LOCSIZE         26                 /* size of local variable space  */
#define  MAXADDR       1300                 /* 50 local variable spaces      */
#define  HALFWIDTH       39                 /* a number < half screen width  */
#define  MOUSE_EXT    ".mou"                /* default source file extension */
#define  ARRAYSIZE     1000                 /* size of universal array       */
#define  MAXFILES        10                 /* max number of files open      */

#define  BACKSPACE     charpos--            /* backspace one char in program */
#define  VALUE(digit)  (digit - '0')        /* convert char to corresp digit */
#define  UPPERCASE     ch = toupper(ch)     /* convert ch to uppercase       */

#define  TOLERANCE     1.0e-6

#ifndef  PI
#define  PI  3.14159265358979323846264338327950288419716939937510582097494459230
#endif

#define  SPEED_OF_LIGHT  299792458.0                   /* m/s                */
#define  ELEMENTARY_CHG  1.60217653e-19                /* C                  */
#define  GRAV_ACCEL      9.80665                       /* m s**-2            */
#define  GRAV_CONST      6.6742e-11                    /* m**3 kg**-1 s**-2  */
#define  PLANCK          6.6260693e-34                 /* J s                */
#define  H_BAR           1.05457168e-34                /* J s                */
#define  PERMEABILITY    (4.0e-7*PI)                   /* N A**-2            */
#define  PERMITTIVITY    (1.0/(PERMEABILITY*SPEED_OF_LIGHT*SPEED_OF_LIGHT))
#define  MASS_ELECTRON   9.1093826e-31                 /* kg                 */
#define  MASS_PROTON     1.67262171e-27                /* kg                 */
#define  MASS_NEUTRON    1.67492728e-27                /* kg                 */
#define  AVAGADRO        6.0221415e23                  /* mol**-1            */
#define  BOLTZMANN       1.3806505e-23                 /* J/K                */

#define  AU              1.49597870e11                 /* m                  */
#define  GM_EARTH        3.9860005e14                  /* m**3 s**-2         */
#define  GM_SUN          1.32712438e20                 /* m**3 s**-2         */
#define  R_EARTH         6.378140e6                    /* m                  */

#define  LB_KG           0.45359237
#define  IN_CM           2.54
#define  GAL_L           3.7854118


#define  DEFAULT_ANGLE_FACTOR    1.0
#define  DEFAULT_DISPLAY_MODE    2
#define  DEFAULT_DISPLAY_DIGITS  15
#define  DEFAULT_DISPLAY_WIDTH   0
#define  DEFAULT_WORDSIZE        32
#define  DEFAULT_OCTHEX_DIGITS   ((DEFAULT_WORDSIZE-1)/4+1)

#define  VERSION         19
#define  PROMPT          "\n> "


/*****************************************************************************/
/*  type definitions                                                         */
/*****************************************************************************/

enum  tagtype {macro, parameter, loop};     /* tag type for environmnt stack */

typedef struct {                            /* environment stack entry type  */
   enum tagtype  tag;                       /* type of entry                 */
   long     charpos;                        /* instruction pointer           */
   long     offset;                         /* variable offset level         */
   } environment;



/*****************************************************************************/
/*  global variables                                                         */
/*****************************************************************************/

FILE         *progfile;                     /* pointer to Mouse source file  */

char         prog[MAXPROGLEN];              /* array to hold program         */
char         prog_line[MAXPROGLINELEN+2];
double       stack[STACKSIZE];              /* calculation stack             */
environment  envstack[ENVSTACKSIZE];        /* environment stack             */
double       data[MAXADDR];                 /* variables                     */
long         macdefs[26];                   /* macro definitions             */

char         ch;                            /* current character in program  */
long         charpos;                       /* instruction pointer           */
long         proglen;                       /* total length of program code  */
long         sp;                            /* calculation stack pointer     */
long         esp;                           /* environment stack pointer     */
long         tsp;                           /* temporary stack pointer       */
long         offset;                        /* variable offset               */
long         nextfree;                      /* next free variable address    */
double       temp, temp2, temp3;            /* temporary doubles             */
long         itemp, itemp2;                 /* temporary integers            */
long         parbal;                        /* matches pairs in env stack    */
long         parnum;                        /* macro parameter number        */
int          tracing;                       /* tracing on/off flag           */
int          disaster;                      /* disaster flag; 1=disaster     */
int          j;                             /* loop index                    */
char         filename[101];                 /* Mouse source file name        */
char         format_str[11];                /* printf format string          */
long         ntemp;                         /* temporary integer             */
int          done;                          /* 1=exit interactive mode       */
char         line[133];                     /* input line                    */
int          source;                        /* 0=compile, 1=interactive      */
double       array[ARRAYSIZE];              /* array for &sto and &rcl       */
int          error_flag;                    /* error flag                    */
FILE         *fp[MAXFILES];                 /* array of file pointers        */
char         filename_str[13];              /* i/o filename                  */
char         filenum_str[4];                /* file numbers string (000-999) */
char         filemode_str[3];               /* file mode string (r,w,rb,wb)  */
char         temp_str[25];                  /* temporary string              */
enum tagtype envtag;                        /* tag from environment stack    */

double       angle_factor = DEFAULT_ANGLE_FACTOR;      /* "to radians" factor*/
long         display_mode = DEFAULT_DISPLAY_MODE;      /* 0=fix, 1=sci, 2=gen*/
long         display_digits = DEFAULT_DISPLAY_DIGITS;  /* #digits to show    */
long         display_width = DEFAULT_DISPLAY_WIDTH;    /* print width        */
long         wordsize = DEFAULT_WORDSIZE;              /* word size (bits)   */
long         octhex_digits = DEFAULT_OCTHEX_DIGITS;    /* octal/hex digits   */
long         octhex_mask = 0xFFFFFFFF;                 /* octal/hex mask     */


/*****************************************************************************/
/*  function prototypes                                                      */
/*****************************************************************************/

void chomp (char *str);                     /* remove final \n from a string */
void display (long charpos);                /* display an environment        */
void error (short code);                    /* report error; stop interpreter*/
void Getchar(void);                         /* get next character in program */
void push (double datum);                   /* push item onto calc stack     */
double pop (void);                          /* pop item from calc stack      */
void skipstring(void);                      /* skip over a string            */
void skip (char lch, char rch);             /* skip bracketed sequences      */
void skip2 (char lch, char rch1,char rch2); /* skip bracketed sequences      */
void pushenv (enum tagtype tag);            /* push an environment on env stk*/
void popenv (void);                         /* pop an environmnt from env stk*/
void load (void);                           /* loader: loads program code    */
void makedeftable (void);                   /* create macro definition table */
void interpret (void);                      /* interpreter: runs program code*/
void process_amp(char *str);                /* process & functions           */
double Int (double f);                      /* integer part                  */
double Frac (double f);                     /* fractional part               */
long round(double x);                       /* round to nearest integer      */







/*****************************************************************************/
/*                                                                           */
/*  main()                                                                   */
/*                                                                           */
/*****************************************************************************/

int main (int argc, char *argv[])
{
/*---------------------------------------------------------------------------*/
/*  Check command-line arguments.                                            */
/*---------------------------------------------------------------------------*/

if (argc == 1)                              /* check for 1 cmd line argument */
   {
   source = 1;
   done = 0;
   printf("Mouse-2002 Interpreter Version %d\n", VERSION);
   sp = -1;                                 /* init stack pointer            */
   esp = -1;                                /* init environ stack pointer    */
   do {
      printf(PROMPT);
      fgets(line,132,stdin);
      load();
      interpret();
      } while (!done);
   exit(0);                                 /* and return to oper system     */
   }


/*---------------------------------------------------------------------------*/
/*  If not interactive mode (source from file), set source flag to 0.        */
/*---------------------------------------------------------------------------*/

source = 0;


/*---------------------------------------------------------------------------*/
/*  If no file extension given, add the default extension to filename.       */
/*---------------------------------------------------------------------------*/

strcpy(filename, argv[1]);                  /* copy cmd line argument        */
if (strchr(filename, (int)'.') == NULL)     /* if no file extension given..  */
   strcat(filename, MOUSE_EXT);             /* ..append default extension    */


/*---------------------------------------------------------------------------*/
/*  Open mouse source file.                                                  */
/*---------------------------------------------------------------------------*/

if ((progfile=fopen(filename,"rb"))==NULL)  /* open Mouse source file        */
   {
   printf("Error opening file %s\n",        /* if open error, print err msg  */
          filename);
   exit(1);                                 /* and return to operating sys   */
   }

/*---------------------------------------------------------------------------*/
/*  Load Mouse source file into memory, then close the source file.          */
/*---------------------------------------------------------------------------*/

load();                                     /* load program into memory      */
fclose(progfile);                           /* close Mouse source file       */

/*---------------------------------------------------------------------------*/
/*  If load went OK, then define macros and run the interpreter.             */
/*---------------------------------------------------------------------------*/

if (!disaster)                              /* if no load problems..         */
   {
   makedeftable();                          /* create macro definition table */
   interpret();                             /* and run interpreter           */
   }

/*---------------------------------------------------------------------------*/
/*  All done.  Return to operating system.                                   */
/*---------------------------------------------------------------------------*/

return 0;                                   /* return to operating system    */

}                                           /* end MouseInterpreter          */






/*****************************************************************************/
/*                                                                           */
/*  display()                                                                */
/*                                                                           */
/*  Display an environment; used for reporting errors and tracing.           */
/*  This routine displays a line of code centered on the given pointer, with */
/*  a ^ pointing to the character at the pointer.                            */
/*                                                                           */
/*****************************************************************************/

void display (long charpos)
{
long  pos;                                  /* loop index                    */
char  *prog_ptr;


if (source == 0)
   prog_ptr = prog;
else
   prog_ptr = prog_line;

for (j=0; j<4; j++)                         /* print stack                   */
   {
   if (j > sp)
      printf("  ..........");
   else
      printf("%12.4e", stack[sp-j]);
   }
printf("      ");

for (pos = charpos - HALFWIDTH;             /* for HALFWIDTH chars centered..*/
     pos <= charpos + HALFWIDTH; pos++)     /*..on current position..        */
   {
   if ((pos >= 0) && (pos < proglen)        /* if within program bounds..    */
              && (prog_ptr[pos] >= ' '))    /*..and printable character..    */
      printf("%c", prog_ptr[pos]);          /* print program character       */
   else                                     /* otherwise,                    */
      printf(" ");                          /* just print a space            */
   }

printf ("\n");                              /* end of line                   */
for (j=0; j<HALFWIDTH+54; j++)              /* print spaces to position ^    */
   printf(" ");
printf("^\n");                              /* print ^ pointer               */
}                                           /* end display                   */





/*****************************************************************************/
/*                                                                           */
/*  error()                                                                  */
/*                                                                           */
/*  Report an error and set "disaster" flag to stop the interpreter.         */
/*                                                                           */
/*****************************************************************************/

void error (short code)
{
short  tsp;                                 /* loop counter                  */


printf("\nEnvironment:\n");                 /* start new line                */
for (tsp = 0; tsp < esp; tsp++)             /* for each entry in env stack.. */
   display(envstack[tsp].charpos);          /* display the code at that entry*/

printf("Instruction pointer:\n");           /* display code at instruct ptr  */
display(charpos);

printf("Stack:");                           /* display stack contents        */
for (tsp = 0; tsp <= sp; tsp++)
   printf(" [%17.10E] ", stack[tsp]);
printf("\n");

printf ("***** Error %d: ", code);          /* print error message           */
switch (code)                               /* select err message from list  */
   {
   case  1 : printf("Ran off end of program");            break;
   case  2 : printf("Calculation stack overflowed");      break;
   case  3 : printf("Calculation stack underflowed");     break;
   case  4 : printf("Attempted to divide by zero");       break;
   case  5 : printf("Attempted to find modulus by zero"); break;
   case  6 : printf("Undefined macro");                   break;
   case  7 : printf("Illegal character follows \"#\"");   break;
   case  8 : printf("Environment stack overflowed");      break;
   case  9 : printf("Environment stack underflowed");     break;
   case 10 : printf("Data space exhausted");              break;
   case 11 : printf("Illegal character %d", ch);          break;
   case 12 : printf("Invalid argument for &acos");        break;
   case 13 : printf("Invalid argument for &acosh");       break;
   case 14 : printf("Invalid argument for &asin");        break;
   case 15 : printf("Invalid argument for &atanh");       break;
   case 16 : printf("Invalid argument for &ln");          break;
   case 17 : printf("Invalid argument for &log2");        break;
   case 18 : printf("Invalid argument for &log10");       break;
   case 19 : printf("Invalid argument for &recip");       break;
   case 20 : printf("Invalid argument for &sqrt");        break;
   case 21 : printf("Invalid argument for &!");           break;
   case 22 : printf("Invalid word size");                 break;
   case 23 : printf("Invalid arguments for &cnr");        break;
   case 24 : printf("Invalid arguments for &pnr");        break;
   case 25 : printf("Array index out of bounds");         break;
   case 26 : printf("Invalid argument for ` or &power");  break;
   case 27 : printf("Invalid arguments for &root");       break;
   case 28 : printf("Error opening file");                break;
   case 29 : printf("Invalid & function name");           break;
   case 30 : printf("Invalid argument for &cubert");      break;
   case 31 : printf("Invalid argument for &4thrt");       break;
   }  /* end case */
printf("\n");
disaster = 1;                               /* set disaster flag             */
sp = -1;                                    /* clear stack                   */
}                                           /* end error                     */





/*****************************************************************************/
/*                                                                           */
/*  Getchar()                                                                */
/*                                                                           */
/*  Get next character from program buffer and check for end of program.     */
/*                                                                           */
/*****************************************************************************/

void Getchar(void)
{
if (charpos < proglen-1)                    /* if next chr is within program */
   {
   charpos++;                               /* increment instruction pointer */
   if (source == 0)
      ch = prog[charpos];                   /* put next char into ch         */
   else
      ch = prog_line[charpos];
   }
else                                        /* else ran off end of program   */
   error(1);                                /* print error message           */
}                                           /* end Getchar                   */





/*****************************************************************************/
/*                                                                           */
/*  push()                                                                   */
/*                                                                           */
/*  Push an item onto the calculation stack and check for stack overflow.    */
/*                                                                           */
/*****************************************************************************/

void push (double datum)
{
if (sp < STACKSIZE-1)                       /* if enough room on calc stack..*/
   {
   sp++;                                    /* increment stack pointer       */
   stack[sp] = datum;                       /* store data item on stack      */
   }
else                                        /* else calc stack filled up     */
   error(2);                                /* print error message           */
}                                           /* end push                      */





/*****************************************************************************/
/*                                                                           */
/*  pop()                                                                    */
/*                                                                           */
/*  Pop an item from the calculation stack; check for underflow.             */
/*                                                                           */
/*****************************************************************************/

double pop (void)
{
double result;                              /* returned stack value          */

if (sp >= 0)                                /* if an item is avail on stack..*/
   {
   result = stack[sp];                      /* get value on top of stack     */
   sp--;                                    /* decrement stack pointer       */
   }
else                                        /* otherwise stack underflow     */
   error(3);                                /* print error message           */
return result;
}                                           /* end pop                       */





/*****************************************************************************/
/*                                                                           */
/*  skipstring()                                                             */
/*                                                                           */
/*  Skip over a string; " has been scanned on entry.                         */
/*                                                                           */
/*****************************************************************************/

void skipstring(void)
{
do {                                        /* do until we find ending "     */
   Getchar();                               /* read program character        */
   } while (ch != '"');                     /* stop when ending " found      */
}                                           /* end skipstring                */





/*****************************************************************************/
/*                                                                           */
/*  skip()                                                                   */
/*                                                                           */
/*  Skip bracketed sequences; lch has been scanned on entry.                 */
/*                                                                           */
/*****************************************************************************/

void skip (char lch, char rch)
{
short  count;                               /* counter used for matching     */

count = 1;                                  /* one bracket already read      */
do {                                        /* do until matching end bracket */
   Getchar();                               /* read program character        */
   if (ch == '"')                           /* if it starts a string..       */
      skipstring();                         /* ..then skip to end of string  */
   else if (ch == lch)                      /* if another 'left' character.. */
      count++;                              /* ..then increment counter      */
   else if (ch == rch)                      /* if closing 'right' character..*/
      count--;                              /* ..then decrement counter      */
   } while (count != 0);                    /* repeat until matching right ch*/
}                                           /* end skip                      */





/*****************************************************************************/
/*                                                                           */
/*  skip2()                                                                  */
/*                                                                           */
/*  Skip bracketed sequences; lch has been scanned on entry.                 */
/*  End bracket is either rch1 or rch2.                                      */
/*                                                                           */
/*****************************************************************************/

void skip2 (char lch, char rch1, char rch2)
{
short  count;                               /* counter used for matching     */

count = 1;                                  /* one bracket already read      */
do {                                        /* do until matching end bracket */
   Getchar();                               /* read program character        */
   if (ch == '"')                           /* if it starts a string..       */
      skipstring();                         /* ..then skip to end of string  */
   else if (ch == lch)                      /* if another 'left' character.. */
      count++;                              /* ..then increment counter      */
   else if (ch == rch1 || ch == rch2)       /* if closing 'right' character..*/
      count--;                              /* ..then decrement counter      */
   } while (count != 0);                    /* repeat until matching right ch*/
}                                           /* end skip                      */





/*****************************************************************************/
/*                                                                           */
/*  pushenv()                                                                */
/*                                                                           */
/*  Push an environment; check for environment stack overflow.               */
/*                                                                           */
/*****************************************************************************/

void pushenv (enum tagtype tag)
   {
if (esp < ENVSTACKSIZE-1)                   /* if room avail on env stack..  */
   {
   esp++;                                   /* ..increment env stack pointer */
   envstack[esp].tag = tag;                 /* save tag type                 */
   envstack[esp].charpos = charpos;         /* save instruction pointer      */
   envstack[esp].offset = offset;           /* save variable offset          */
   }
else                                        /* otherwise, env stack overflow */
   error(8);                                /* print error message           */
}                                           /* end pushenv                   */





/*****************************************************************************/
/*                                                                           */
/*  popenv()                                                                 */
/*                                                                           */
/*  Pop an environment; check for environment stack underflow.               */
/*                                                                           */
/*****************************************************************************/

void popenv(void)
{
if (esp >= 0)                               /* if item avail on env stack..  */
   {
   envtag = envstack[esp].tag;              /* pop tag type                  */
   charpos = envstack[esp].charpos;         /* pop instruction pointer       */
   offset = envstack[esp].offset;           /* pop variable offset           */
   esp--;                                   /* decrement stack pointer       */
   }
else                                        /* otherwise stack underflow     */
   error(9);                                /* print error message           */
}                                           /* end popenv                    */





/*****************************************************************************/
/*                                                                           */
/*  load()                                                                   */
/*                                                                           */
/*  The Loader.                                                              */
/*  This version of the loader has been optimized to remove all spaces       */
/*  except for spaces within strings and spaces separating numbers (for      */
/*  which all but one space is removed).  It also eliminates all CR/LF       */
/*  characters.  Optimizing the loader to eliminate all unnecessary          */
/*  characters greatly improves the execution speed of the interpreter.      */
/*                                                                           */
/*****************************************************************************/

void load (void)
{
char  lastchr;                              /* previously loaded character   */
char  in = 0;                               /* 1=within a string             */
char  in_amp = 0;                           /* 1 = processing & string       */
char  *p;
char  *prog_ptr;
long  maxlen;


if (source == 0)
   {
   for (charpos = 0; charpos<MAXPROGLEN;    /* init entire program array..   */
     charpos++)
       prog[charpos] = ' ';                 /* ..to all spaces               */
   rewind(progfile);                        /* position to beginning of file */
   prog_ptr = prog;
   maxlen = MAXPROGLEN;
   }
else
   {
   p = line;
   prog_ptr = prog_line;
   maxlen = MAXPROGLINELEN;
   }
charpos = -1;                               /* init ptr to start of memory   */
disaster = 0;                               /* clear disaster flag           */
ch = '~';                                   /* init first character to ~     */
while (!disaster)                           /* while loading OK..            */
   {
   lastchr = ch;                            /* save previously loaded char   */
   if (source == 0)
      {
      fread(&ch, 1, 1, progfile);           /* read one char from Mouse file */
      if (feof(progfile))                   /* if end of Mouse file..        */
         break;                             /* then break out of loop        */
      }
   else
      {
      ch = *p++;
      if (ch=='\0' || ch=='\n')
         break;
      }
   if (ch == '~')                           /* if start of comment..         */
      {
      if (source == 0)
         do {
            fread(&ch, 1, 1, progfile);     /* ..read characters..           */
            } while (ch != '\n');           /* ..until next newline          */
      else
         break;
      }
   else if (charpos < maxlen-1)             /* else if program memory left.. */
      {
      charpos++;                            /* increment pointer to memory   */
      prog_ptr[charpos] = ch;               /* save read character to memory */
      if (ch == '\"')                       /* if current char is " ..       */
         in = !in;                          /* ..then toggle quote flag      */
      if (ch=='&' && !in)                   /* if current char is & ..       */
         in_amp = 1;                        /* ..then set & processing flag  */
      if (ch==10 || ch==13 || ch=='\n'      /* if CR or LF or newline..      */
          || ch=='\t' || ch=='\r')          /* ..or tab or \r..              */
         prog_ptr[charpos] = ch = ' ';      /* ..replace with space          */
      if (in_amp && ch==' ')                /* if end of & string..          */
         {
         prog_ptr[charpos] = ch = '&';      /* ..replace final space w/ &    */
         in_amp = 0;                        /* turn off & processing flag    */
         }
      if (in_amp && ch==';')                /* if end of & string (found ;)  */
         {
         prog_ptr[charpos] = ch = '&';      /* ..insert final & correctly    */
         charpos++;
         prog_ptr[charpos] = ch = ';';
         in_amp = 0;                        /* turn off & processing flag    */
         }
      if (ch==' ' && !in &&                 /* if a space not in string..    */
           !isdigit(lastchr) &&             /* ..and not after a number..    */
           (lastchr != '\''))               /* ..and not after a '..         */
         {
         charpos--;                         /* then backspace pointer        */
         ch = prog_ptr[charpos];            /* update last read character    */
         }
      else if (!in && lastchr == ' ' &&     /* if last char was a space and..*/
            !isdigit(ch) && ch != '\"'      /*..this char isn't a digit..    */
            && prog_ptr[charpos-2] != '\'') /*..and it isn't a quote-space.. */
         prog_ptr[--charpos] = ch;          /* then remove the last space    */
      }
   else                                     /* if no program memory left..   */
      {
      printf("Program is too long\n");      /* print error message           */
      disaster = 1;                         /* and set disaster flag         */
      }
   }                                        /* end while                     */
proglen = charpos + 1;                      /* set total program length      */
if (source==1)
   {
   prog_ptr[charpos+1] = '$';
   charpos++;
   proglen = charpos + 1;
   }

}                                           /* end load                      */





/*****************************************************************************/
/*                                                                           */
/*  makedeftable()                                                           */
/*                                                                           */
/*  Construct macro definition table.                                        */
/*                                                                           */
/*****************************************************************************/

void makedeftable (void)
{
for (ch = 'A' ; ch <= 'Z'; ch++)            /* for all macro table entries.. */
   macdefs[ch-'A'] = 0;                     /*..initialize all entries to 0  */
charpos = -1;                               /* init ptr to start of memory   */
do {                                        /* for all program characters    */
   Getchar();                               /* read next program character   */
   if (ch=='$' && charpos < proglen-1)      /* if this is a $ (macro defn..  */
      {                                     /* ..or end of program           */
      Getchar();                            /* read next char (macro letter) */
      UPPERCASE;                            /* convert it to uppercase       */
      if ((ch >= 'A') && (ch <= 'Z'))       /* if it's a macro definition..  */
         macdefs[ch-'A'] = charpos;         /* save pointer in macro def tbl */
      }
   } while (charpos < proglen-1);           /* repeat until end of program   */
}                                           /* end makedeftable              */





/*****************************************************************************/
/*                                                                           */
/*  interpret()                                                              */
/*                                                                           */
/*  The Interpreter.                                                         */
/*                                                                           */
/*****************************************************************************/

void interpret (void)
{
char         amp_str[11];                   /* & function string             */
char         *p;                            /* character pointer             */
char instr[26];                             /* input string                  */


charpos = -1;                               /* init instruction pointer      */
if (source==0)
   {
   sp = -1;                                 /* init stack pointer            */
   esp = -1;                                /* init environ stack pointer    */
   }
offset = 0;                                 /* init variable offset          */
nextfree = LOCSIZE;                         /* init next free variable addr  */

do {                                        /* repeat until end of program   */
   Getchar();                               /* read next program character   */
   if (ch == ' ')                           /* if it's a space..             */
      continue;                             /* ..skip to end of loop         */

   if (tracing)                             /* if tracing on..               */
      display(charpos);                     /* ..display code w/ curr posn   */

   if (isdigit(ch))                         /* if char is a digit..          */
      {                                     /* ..encode a decimal number     */
      temp = 0;                             /* init decimal number to 0      */
      while (isdigit(ch))                   /* repeat for each digit         */
         {
         temp = 10 * temp + VALUE(ch);      /* add digit to number           */
         Getchar();                         /* get next character            */
         }                                  /* end while                     */
      if (ch == '.')
         {
         Getchar();
         temp2 = 1.0;
         while (isdigit(ch))
            {
            temp2 /= 10.0;
            temp += temp2 * VALUE(ch);
            Getchar();
            }
         }
      push(temp);                           /* push final number onto stack  */
      BACKSPACE;                            /* backspace to last digit       */
      }

   else if ((ch >= 'A') && (ch <= 'Z'))     /* if A to Z..                   */
      push(ch - 'A');                       /* put 0 to 25 on stack          */

   else if ((ch >= 'a') && (ch <= 'z'))     /* if a to z..                   */
      push(ch - 'a' + offset);              /* put 0 to 25 + offset on stack */

   else                                     /* if not alphanumeric..         */

      switch (ch)                           /* big switch on current char    */
         {

         case '$' :                         /*  $   macro defn / end of prog */
            break;                          /*         no action             */

         case '_' :                         /*  _   change sign              */
            push(-pop());
            break;

         case '+' :                         /*  +   add                      */
            push(pop() + pop());
            break;

         case  '-' :                        /*  -   subtract                 */
            temp = pop();
            push(pop() - temp);
            break;

         case '*' :                         /*  *   multiply                 */
            push(pop() * pop());
            break;

         case '/' :                         /*  /   divide with zero check   */
            temp = pop();
            if (temp != 0)                  /*         check for div by zero */
               push(pop() / temp);          /*         push if not div by 0  */
            else
               error(4);                    /*         error if div by zero  */
            break;

         case '\\' :                        /*  \   remainder w/ zero check  */
            temp = pop();
            if (temp != 0)                  /*         check for rem by zero */
               push((long)pop() %           /*         push if not rem by 0  */
                    (long)temp);
            else
               error(5);                    /*         error if rem by zero  */
            break;

         case '?' :                         /*  ?   read from keyboard       */
            Getchar();
            if (ch == '\'')                 /*  ?'   read character          */
               {
               fgets(instr, 2, stdin);      /*         read as a string      */
               chomp(instr);                /*         remove \n             */
               sscanf(instr, "%c", &ch);    /*         read character        */
               push((double)ch);
               }
            else                            /*  ?    read number             */
               {
               fgets(instr, 25, stdin);     /*         read as a string      */
               chomp(instr);                /*         remove \n             */
               sscanf(instr, "%lf", &temp); /*         read number           */
               push(temp);
               BACKSPACE;
               }
            break;

         case '!' :                         /*  !   display on screen        */
            Getchar();
            if (ch == '\'')                 /*  !'   display character       */
               printf("%c", round(pop()));
            else                            /*  !    display number          */
               {
               sprintf(format_str, "%%%d.", /*         create format string  */
                  display_width);
               sprintf(temp_str, "%d",
                  display_digits);
               strcat(format_str,temp_str);
               if (display_mode == 0)       /*         if fixed mode         */
                  strcat(format_str,"f");
               else if (display_mode == 1)  /*         if sci mode           */
                  strcat(format_str,"E");
               else                         /*         if general mode       */
                  strcat(format_str,"G");
               printf(format_str, pop());   /*         print number          */
               BACKSPACE;
               }
            break;

         case '"' :                         /*  "   display string on screen */
            do {
               Getchar();
               if (ch == '!')               /*         check for newline     */
                  printf("\n");             /*         print newline         */
               else if (ch != '"')          /*         check for end of str  */
                  printf ("%c", ch);        /*         print if not "        */
               } while (ch != '"');
            break;

         case ':' :                         /*  :   assignment               */
            temp = pop();
            data[round(temp)] = pop();
            break;

         case '.' :                         /*  .   dereference              */
            push(data[round(pop())]);
            break;

         case '<' :                         /*  <   less than                */
            temp = pop();
            push ((pop() < temp) ? 1 : 0);
            break;

         case '=' :                         /*  =   equal to                 */
            push ((pop()==pop()) ? 1 : 0);
            break;

         case '>' :                         /*  >   greater than             */
            temp = pop();
            push ((pop() > temp) ? 1 : 0);
            break;

         case '[' :                         /*  [   conditional statement    */
            if (pop() <= 0)                 /*         true if > 0           */
               skip2('[','|',']');
            break;

         case ']' :                         /*  ]   end of conditional       */
            break;                          /*         no action             */

         case '|':                          /*  |   else                     */
            skip('[',']');
            break;

         case '(' :                         /*  (   begin loop               */
            pushenv(loop);
            break;

         case ')' :                         /*  )   end loop                 */
            charpos=envstack[esp].charpos;
            break;

         case '^' :                         /*  ^   exit loop                */
            if (pop() <= 0)
               {
               popenv();
               skip('(',')');
               }
            break;

         case '#':                          /*  #   macro call               */
            Getchar();                      /*         get macro letter      */
            UPPERCASE;                      /*         convert to uppercase  */
            if ((ch>='A') && (ch<='Z'))     /*         if A to Z..           */
               {
               if (macdefs[ch-'A'] > 0)     /*         if macro defined..    */
                  {
                  pushenv(macro);           /*         push env stack frame  */
                  charpos=macdefs[ch-'A'];  /*         instruct ptr to macro */
                  if (nextfree + LOCSIZE    /*         if variables avail..  */
                          <= MAXADDR)
                     {
                     offset = nextfree;     /*         increment offset      */
                     nextfree += LOCSIZE;   /*         increment nextfree    */
                     }
                  else                      /*         out of variable space */
                     error(10);             /*         print error message   */
                  }
               else                         /*         macro not defined     */
                  error(6);                 /*         print error message   */
               }
            else                            /*         invalid char after #  */
               error(7);                    /*         print error message   */
            break;

         case '@':                          /*  @   return from macro        */
            do {                            /*         loop to discard loops */
               popenv();                    /*         pop env stack frame   */
               } while (envtag != macro);   /*         repeat til macro found*/
            skip('#',';');                  /*         skip to ;             */
            nextfree -= LOCSIZE;            /*         decrement nextfree    */
            break;

         case '%':                          /*  %   replace formal by actual */
            pushenv(parameter);             /*         push stack frame      */
            parbal = 1;                     /*         1 stack already pushed*/
            tsp = esp;                      /*         temp env stack pointer*/
            do {                            /*         loop thru env stack   */
               tsp--;                       /*         decrement stack ptr   */
               switch (envstack[tsp].tag)   /*         check tag type        */
                  {
                  case macro :              /*         if macro (#)..        */
                     parbal--;              /*         decrement counter     */
                     break;
                  case parameter :          /*         if parameter (%)..    */
                     parbal++;              /*         nest another level    */
                     break;
                  case loop :               /*         if loop [ ( ]..       */
                     break;                 /*         keep searching        */
                  }
               } while (parbal != 0);       /*        til calling macro found*/
            charpos=envstack[tsp].charpos;  /*        update instruct ptr    */
            offset = envstack[tsp].offset;  /*        pt to new variable set */
            parnum = pop();                 /*        get parameter number   */
            do {                            /*        look for actual param  */
               Getchar();                   /*        read program character */
               if (ch == '"')               /*         param contains string */
                  skipstring();             /*         skip string           */
               else if (ch == '#')          /*         param has macro call  */
                  skip('#',';');            /*         skip to end of macro  */
               else if (ch == ',')          /*         count commas          */
                  parnum--;                 /*         decrement comma ctr   */
               else if (ch == ';')          /*         param doesn't exist   */
                  {
                  parnum = 0;               /*         stop loop             */
                  popenv();                 /*         null parameter        */
                  }
               } while (parnum != 0);       /*         loop until param found*/
            break;

         case ',' :                         /*  ,   end of actual parameter  */
         case ';' :                         /*  ;   end of macro call        */
            popenv();
            break;

         case '\''  :                       /*  '   stack next character     */
            Getchar();
            push(ch);
            break;

         case '{' :                         /*  {   trace on                 */
            tracing = 1;
            break;

         case '}' :                         /*  }   trace off                */
            tracing = 0;
            break;

         case '&':                          /*  &   & function               */
            p = amp_str;
            Getchar();                      /*         read 1st char after & */
            while (ch!='&' && ch!='$')      /*         loop until end & or $ */
               {
               *p++ = tolower(ch);          /*         copy char to amp_str  */
               Getchar();                   /*         read next char        */
               }
            *p = '\0';                      /*         add end-of-string     */
            process_amp(amp_str);           /*         call & subroutine     */
            break;

         default :                          /*      unused character         */
            error(11);                      /*         print error message   */
            break;
         }                                  /* end switch                    */

   } while (!((ch == '$') || disaster));    /* loop until end of program ($) */
}                                           /* end interpret                 */





/*****************************************************************************/
/*                                                                           */
/*  process_amp()                                                            */
/*                                                                           */
/*  Process & functions.                                                     */
/*                                                                           */
/*****************************************************************************/

void process_amp(char *str)
{
long i, j;                                  /* loop counters                 */
double  hr, min, sec;
struct tm *systime;
time_t  t;
char instr[26];                             /* input string                  */


if (!strcmp(str,"2x"))                      /* &2x                           */
   push(pow(2.0,pop()));

else if (!strcmp(str,"4th"))                /* &4th                          */
   {
   temp = pop();
   push(temp*temp*temp*temp);
   }

else if (!strcmp(str,"4thrt"))              /* &4thrt                        */
   {
   temp = pop();
   if (temp >= 0.0)
      push(sqrt(sqrt(temp)));
   else
      error(31);
   }

else if (!strcmp(str,"10x"))                /* &10x                          */
   push(pow(10.0,pop()));

else if (!strcmp(str,"abs"))                /* &abs                          */
   push(fabs(pop()));

else if (!strcmp(str,"acos"))               /* &acos                         */
   {
   temp = pop();
   if (fabs(temp) <= 1.0)
      push(acos(temp)/angle_factor);
   else
      error(12);
   }

else if (!strcmp(str,"acosh"))              /* &acosh                        */
   {
   temp = pop();
   if (temp >= 1.0)
      push(log(temp+sqrt(temp*temp-1.0)));
   else
      error(13);
   }

else if (!strcmp(str,"and"))                /* &and                          */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   push((double)(itemp & itemp2));
   }

else if (!strcmp(str,"asin"))               /* &asin                         */
   {
   temp = pop();
   if (fabs(temp) <= 1.0)
      push(asin(temp)/angle_factor);
   else
      error(14);
   }

else if (!strcmp(str,"asinh"))              /* &asinh                        */
   {
   temp = pop();
   push(log(temp+sqrt(temp*temp+1.0)));
   }

else if (!strcmp(str,"atan"))               /* &atan                         */
   push(atan(pop())/angle_factor);

else if (!strcmp(str,"atan2"))              /* &atan2                        */
   {
   temp = pop();
   push(atan2(pop(),temp)/angle_factor);
   }

else if (!strcmp(str,"atanh"))              /* &atanh                        */
   {
   temp = pop();
   if (fabs(temp) < 1.0)
      push(0.5*log((1.0+temp)/(1.0-temp)));
   else
      error(15);
   }

else if (!strcmp(str,"au"))                 /* &au                           */
   push(AU);

else if (!strcmp(str,"beep"))               /* &beep                         */
   printf("\a");

else if (!strcmp(str,"c"))                  /* &c                            */
   push(SPEED_OF_LIGHT);

else if (!strcmp(str,"clrstk"))             /* &clrstk                       */
   sp = -1;

else if (!strcmp(str,"cm>in"))              /* &cm>in                        */
   push(pop()/IN_CM);

else if (!strcmp(str,"cnr"))                /* &cnr                          */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   if ((itemp>=0) && (itemp2>=0) &&
       (itemp<=itemp2))
      {
      temp = 1.0;
      for (i=itemp2, j=(itemp2-itemp);
           j>=1; i--, j--)
         temp *= (double)i/(double)j;
      push(temp);
      }
   else
      error(23);
   }

else if (!strcmp(str,"cont"))               /* &cont                         */
   charpos=envstack[esp].charpos;

else if (!strcmp(str,"cos"))                /* &cos                          */
   push(cos(pop()*angle_factor));

else if (!strcmp(str,"cosh"))               /* &cosh                         */
   push(cosh(pop()));

else if (!strcmp(str,"cube"))               /* &cube                         */
   {
   temp = pop();
   push(temp*temp*temp);
   }

else if (!strcmp(str,"cubert"))             /* &cubert                       */
   {
   temp = pop();
   if (temp > 0.0)
      push(pow(temp, 1.0/3.0));
   else if (temp == 0.0)
      push(0.0);
   else
      error(30);
   }

else if (!strcmp(str,"c>f"))                /* &c>f                          */
   push(pop()*9.0/5.0+32.0);

else if (!strcmp(str,"deg"))                /* &deg                          */
   angle_factor = PI/180.0;

else if (!strcmp(str,"dom"))                /* &dom                          */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)systime->tm_mday);
   }

else if (!strcmp(str,"dow"))                /* &dow                          */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)(systime->tm_wday+1));
   }

else if (!strcmp(str,"doy"))                /* &doy                          */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)(systime->tm_yday+1));
   }

else if (!strcmp(str,"drop"))               /* &drop                         */
   pop();

else if (!strcmp(str,"dup"))                /* &dup                          */
   {
   temp = pop();
   push(temp);
   push(temp);
   }

else if (!strcmp(str,"d>r"))                /* &d>r                          */
   push(pop()*PI/180.0);

else if (!strcmp(str,"e"))                  /* &e                            */
   push(ELEMENTARY_CHG);

else if (!strcmp(str,"eex"))                /* &eex                          */
   {
   temp = pop();
   push(pop()*pow(10.0,temp));
   }

else if (!strcmp(str,"eps0"))               /* &eps0                         */
   push(PERMITTIVITY);

else if (!strcmp(str,"exit"))               /* &exit                         */
   done = 1;

else if (!strcmp(str,"exp"))                /* &exp                          */
   push(exp(pop()));

else if (!strcmp(str,"fact"))               /* &fact                         */
   {
   ntemp = round(pop());
   if (ntemp >= 0)
      {
      temp = 1.0;
      for (i=2; i<=ntemp; i++)
         temp *= (double)i;
      push(temp);
      }
   else
      error(21);
   }

else if (!strcmp(str,"fclose"))             /* &fclose                       */
   fclose(fp[round(pop())]);

else if (!strcmp(str,"feof"))               /* &feof                         */
   push(feof(fp[round(pop())]) ? 1 : 0);

else if (!strcmp(str,"fix"))                /* &fix                          */
   {
   display_mode = 0;
   display_digits = round(pop());
   }

else if (!strcmp(str,"fopen"))              /* &fopen                        */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   sprintf(filenum_str,"%03d",itemp2);
   strcpy(filename_str,"mouse.");
   strcat(filename_str, filenum_str);
   switch (itemp)
      {
      case 0:  strcpy(filemode_str,"r");
               break;
      case 1:  strcpy(filemode_str,"w");
               break;
      case 2:  strcpy(filemode_str,"rb");
               break;
      case 3:  strcpy(filemode_str,"wb");
               break;
      }
   if ((fp[itemp2] = fopen(filename_str,
        filemode_str))==NULL)
      {
      error(28);
      return;
      }
   }

else if (!strcmp(str,"frac"))               /* &frac                         */
   push(Frac(pop()));

else if (!strcmp(str,"frewind"))            /* &frewind                      */
   rewind(fp[round(pop())]);

else if (!strcmp(str,"f>c"))                /* &f>c                          */
   push((pop()-32.0)*5.0/9.0);

else if (!strcmp(str,"f?"))                 /* &f?                           */
   {
   fscanf(fp[round(pop())],"%lf", &temp);
   push(temp);
   }

else if (!strcmp(str,"f?'"))                /* &f?'                          */
   {
   fscanf(fp[round(pop())],"%c", &ch);
   push((double)ch);
   }

else if (!strcmp(str,"f!"))                 /* &f!                           */
   {
   sprintf(format_str, "%%%d.",             /*         create format string  */
      display_width);
   sprintf(temp_str, "%d",
      display_digits);
   strcat(format_str,temp_str);
   if (display_mode == 0)                   /*         if fixed mode         */
      strcat(format_str,"f");
   else if (display_mode == 1)              /*         if sci mode           */
      strcat(format_str,"E");
   else                                     /*         if general mode       */
      strcat(format_str,"G");
   itemp = round(pop());
   fprintf(fp[itemp],format_str,pop());     /*         print number          */
   }

else if (!strcmp(str,"f!'"))                /* &f!'                          */
   {
   itemp = round(pop());
   fprintf(fp[itemp],"%c", round(pop()));
   }

else if (!strcmp(str,"f\""))                /* &f"                           */
   {
   itemp = round(pop());
   do {
      Getchar();
      if (ch == '!')                        /*         check for newline     */
         fprintf(fp[itemp],"\n");           /*         print newline         */
      else if (ch != '"')                   /*         check for end of str  */
         fprintf (fp[itemp],"%c", ch);      /*         print if not "        */
      } while (ch != '"');
   }

else if (!strcmp(str,"g"))                  /* &g                            */
   push(GRAV_CONST);

else if (!strcmp(str,"g0"))                 /* &g0                           */
   push(GRAV_ACCEL);

else if (!strcmp(str,"gal>l"))              /* &gal>l                        */
   push(pop()*GAL_L);

else if (!strcmp(str,"ge"))                 /* &ge                           */
   {
   temp = pop();
   push ((pop() >= temp) ? 1 : 0);
   }

else if (!strcmp(str,"gen"))                /* &gen                          */
   {
   display_mode = 2;
   display_digits = round(pop());
   }

else if (!strcmp(str,"gmearth"))            /* &gmearth                      */
   push(GM_EARTH);

else if (!strcmp(str,"gmsun"))              /* &gmsun                        */
   push(GM_SUN);

else if (!strcmp(str,"grad"))               /* &grad                         */
   angle_factor = PI/200.0;

else if (!strcmp(str,"h"))                  /* &h                            */
   push(PLANCK);

else if (!strcmp(str,"halfpi"))             /* &halfpi                          */
   push(0.5*PI);

else if (!strcmp(str,"hbar"))               /* &hbar                         */
   push(H_BAR);

else if (!strcmp(str,"hms>h"))              /* &hms>h                        */
   {
   temp = pop();
   hr = Int(temp);
   min = Int(100.0*Frac(temp));
   sec = 100.0*Frac(100.0*temp);
   push(hr + min/60.0 + sec/3600.0);
   }

else if (!strcmp(str,"hour"))               /* &hour                         */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)systime->tm_hour);
   }

else if (!strcmp(str,"h>hms"))              /* &h>hms                        */
   {
   temp = pop();
   hr = Int(temp);
   min = Int(60.0*Frac(temp));
   sec = 60.0*Frac(60.0*temp);
   push(hr + min/100.0 + sec/10000.0);
   }

else if (!strcmp(str,"int"))                /* &int                          */
   push(Int(pop()));

else if (!strcmp(str,"in>cm"))              /* &in>cm                        */
   push(pop()*IN_CM);

else if (!strcmp(str,"kb"))                 /* &kb                           */
   push(BOLTZMANN);

else if (!strcmp(str,"kg>lb"))              /* &kg>lb                        */
   push(pop()/LB_KG);

else if (!strcmp(str,"lb>kg"))              /* &lb>kg                        */
   push(pop()*LB_KG);

else if (!strcmp(str,"le"))                 /* &le                           */
   {
   temp = pop();
   push ((pop() <= temp) ? 1 : 0);
   }

else if (!strcmp(str,"ln"))                 /* &ln                           */
   {
   temp = pop();
   if (temp > 0.0)
      push(log(temp));
   else
      error(16);
   }

else if (!strcmp(str,"log"))                /* &log                          */
   {
   temp = pop();
   if (temp > 0.0)
      push(log(temp));
   else
      error(16);
   }

else if (!strcmp(str,"log2"))               /* &log2                         */
   {
   temp = pop();
   if (temp > 0.0)
      push(log(temp)/log(2.0));
   else
      error(17);
   }

else if (!strcmp(str,"log10"))              /* &log10                        */
   {
   temp = pop();
   if (temp > 0.0)
      push(log10(temp));
   else
      error(18);
   }

else if (!strcmp(str,"l>gal"))              /* &l>gal                        */
   push(pop()/GAL_L);

else if (!strcmp(str,"me"))                 /* &me                           */
   push(MASS_ELECTRON);

else if (!strcmp(str,"min"))                /* &min                          */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)systime->tm_min);
   }

else if (!strcmp(str,"mn"))                 /* &mn                           */
   push(MASS_NEUTRON);

else if (!strcmp(str,"month"))              /* &month                        */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)(systime->tm_mon+1));
   }

else if (!strcmp(str,"mp"))                 /* &mp                           */
   push(MASS_PROTON);

else if (!strcmp(str,"mu0"))                /* &mu0                          */
   push(PERMEABILITY);

else if (!strcmp(str,"na"))                 /* &na                           */
   push(AVAGADRO);

else if (!strcmp(str,"ne"))                 /* &ne                           */
   {
   temp = pop();
   push ((pop() != temp) ? 1 : 0);
   }

else if (!strcmp(str,"nip"))                /* &nip                          */
   {
   temp = pop();
   pop();
   push(temp);
   }

else if (!strcmp(str,"not"))                /* &not                          */
   {
   itemp = round(pop());
   push((double)(~itemp));
   }

else if (!strcmp(str,"or"))                 /* &or                           */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   push((double)(itemp | itemp2));
   }

else if (!strcmp(str,"over"))               /* &over                         */
   {
   temp = pop();
   temp2 = pop();
   push(temp2);
   push(temp);
   push(temp2);
   }

else if (!strcmp(str,"pi"))                 /* &pi                           */
   push(PI);

else if (!strcmp(str,"pnr"))                /* &pnr                          */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   if ((itemp>=0) && (itemp2>=0) &&
       (itemp<=itemp2))
      {
      temp = 1.0;
      for (i=itemp2;
           i>=(itemp2-itemp+1);
           i--)
         temp *= (double)i;
      push(temp);
      }
   else
      error(24);
   }

else if (!strcmp(str,"pow"))                /* &pow                          */
   {
   temp = pop();
   temp2 = pop();
   error_flag = ((temp2==0.0) &&
      (temp<=0.0)) ||
      ((temp2<0) &&
      (temp!=round(temp)));
   if (!error_flag)
      push(pow(temp2, temp));
   else
      error(26);
   }

else if (!strcmp(str,"p>r"))                /* &p>r                          */
   {
   temp = pop();
   temp2 = pop();
   push(temp*cos(temp2*angle_factor));
   push(temp*sin(temp2*angle_factor));
   }

else if (!strcmp(str,"quit"))               /* &quit                         */
   done = 1;

else if (!strcmp(str,"rad"))                /* &rad                          */
   angle_factor = 1.0;

else if (!strcmp(str,"rand"))               /* &rand                         */
   push((double)rand()/(double)RAND_MAX);

else if (!strcmp(str,"rcl"))                /* &rcl                          */
   {
   itemp = round(pop());
   if ((itemp>=0) && (itemp<ARRAYSIZE))
      push(array[itemp]);
   else
      error(25);
   }

else if (!strcmp(str,"rearth"))             /* &rearth                       */
   push(R_EARTH);

else if (!strcmp(str,"recip"))              /* &recip                        */
   {
   temp = pop();
   if (temp != 0.0)
      push(1.0/temp);
   else
      error(19);
   }

else if (!strcmp(str,"rev"))                /* &rev                          */
   angle_factor = PI+PI;

else if (!strcmp(str,"root"))               /* &root                         */
   {
   temp = pop();
   temp2 = pop();
   error_flag = (temp==0.0) ||
      ((temp2==0.0) && (temp<=0.0)) ||
      ((temp2<0) &&
      ((1.0/temp)!=round(1.0/temp)));
   if (!error_flag)
      push(pow(temp2, 1.0/temp));
   else
      error(27);
   }

else if (!strcmp(str,"rot"))                /* &rot                          */
   {
   temp = pop();
   temp2 = pop();
   temp3 = pop();
   push(temp2);
   push(temp);
   push(temp3);
   }

else if (!strcmp(str,"round"))              /* &round                        */
   push((double)round(pop()));

else if (!strcmp(str,"r>d"))                /* &r>d                          */
   push(pop()*180.0/PI);

else if (!strcmp(str,"r>p"))                /* &r>p                          */
   {
   temp = pop();
   temp2 = pop();
   push(atan2(temp2,temp)/angle_factor);
   push(sqrt(temp*temp + temp2*temp2));
   }

else if (!strcmp(str,"sci"))                /* &sci                          */
   {
   display_mode = 1;
   display_digits = round(pop());
   }

else if (!strcmp(str,"sec"))                /* &sec                          */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)systime->tm_sec);
   }

else if (!strcmp(str,"seed"))               /* &seed                         */
   srand(round(pop()));

else if (!strcmp(str,"shl"))                /* &shl                          */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   push((double)(itemp2 << itemp));
   }

else if (!strcmp(str,"shr"))                /* &shr                          */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   push((double)(itemp2 >> itemp));
   }

else if (!strcmp(str,"sin"))                /* &sin                          */
   push(sin(pop()*angle_factor));

else if (!strcmp(str,"sinh"))               /* &sinh                         */
   push(sinh(pop()));

else if (!strcmp(str,"sqr"))                /* &sqr                          */
   {
   temp = pop();
   push(temp*temp);
   }

else if (!strcmp(str,"sqrt"))               /* &sqrt                         */
   {
   temp = pop();
   if (temp >= 0.0)
      push(sqrt(temp));
   else
      error(20);
   }

else if (!strcmp(str,"sto"))                /* &sto                          */
   {
   itemp = round(pop());
   if ((itemp>=0) && (itemp<ARRAYSIZE))
      array[itemp] = pop();
   else
      error(25);
   }

else if (!strcmp(str,"swap"))               /* &swap                         */
   {
   temp = pop();
   temp2 = pop();
   push(temp);
   push(temp2);
   }

else if (!strcmp(str,"tan"))                /* &tan                          */
   push(tan(pop()*angle_factor));

else if (!strcmp(str,"tanh"))               /* &tanh                         */
   push(tanh(pop()));

else if (!strcmp(str,"time"))               /* &time                         */
   push((double)time(NULL));

else if (!strcmp(str,"tuck"))               /* &tuck                         */
   {
   temp = pop();
   temp2 = pop();
   push(temp);
   push(temp2);
   push(temp);
   }

else if (!strcmp(str,"twopi"))              /* &twopi                           */
   push(PI+PI);

else if (!strcmp(str,"ver"))                /* &ver                          */
   push(VERSION);

else if (!strcmp(str,"width"))              /* &width                        */
   display_width = round(pop());

else if (!strcmp(str,"wsize"))              /* &wsize                        */
   {
   if ((wordsize >= 1) && (wordsize <= 32))
      wordsize = round(pop());
   else
      error(22);
   }

else if (!strcmp(str,"xor"))                /* &xor                          */
   {
   itemp = round(pop());
   itemp2 = round(pop());
   push((double)(itemp ^ itemp2));
   }

else if (!strcmp(str,"y2x"))                /* &y2x                          */
   {
   temp = pop();
   push(pop()*pow(2.0,temp));
   }

else if (!strcmp(str,"year"))               /* &year                         */
   {
   t = time(NULL);
   systime = localtime(&t);
   push((double)(systime->tm_year+1900));
   }

else if (!strcmp(str,"?hex"))               /* &?hex                         */
   {
   fgets(instr, 25, stdin);                 /*         read as a string      */
   chomp(instr);                            /*         remove \n             */
   sscanf(instr, "%lx", &itemp);            /*         read number           */
   push((double)itemp);
   }

else if (!strcmp(str,"?oct"))               /* &?oct                         */
   {
   fgets(instr, 25, stdin);                 /*         read as a string      */
   chomp(instr);                            /*         remove \n             */
   sscanf(instr, "%lo", &itemp);            /*         read number           */
   push((double)itemp);
   }

else if (!strcmp(str,"!dec"))               /* &!dec                         */
   {
   sprintf(format_str, "%%%d.",
      display_width);
   sprintf(temp_str,"%dd",display_width);
   strcat(format_str,temp_str);
   printf(format_str,
         (long)pop());
   }

else if (!strcmp(str,"!hex"))               /* &!hex                         */
   {
   octhex_digits = ((wordsize-1)/4)+1;
   if (wordsize == 32)
      octhex_mask = 0xFFFFFFFF;
   else
      octhex_mask = (1L << wordsize) - 1;
   sprintf(format_str, "%%%d.",
      octhex_digits);
   sprintf(temp_str,"%dX",octhex_digits);
   strcat(format_str,temp_str);
   printf(format_str,
         (long)pop() & octhex_mask);
   }

else if (!strcmp(str,"!oct"))               /* &!oct                         */
   {
   octhex_digits = ((wordsize-1)/3)+1;
   if (wordsize == 32)
      octhex_mask = 0xFFFFFFFF;
   else
      octhex_mask = (1L << wordsize) - 1;
   sprintf(format_str, "%%%d.",
      octhex_digits);
   sprintf(temp_str,"%do",octhex_digits);
   strcat(format_str,temp_str);
   printf(format_str,
         (long)pop() & octhex_mask);
   }

else if (!strcmp(str,"!stk"))               /* &!stk                         */
   {
   sprintf(format_str, "%%%d.",             /*         create format string  */
      display_width);
   sprintf(temp_str, "%d",
      display_digits);
   strcat(format_str,temp_str);
   if (display_mode == 0)                   /*         if fixed mode         */
      strcat(format_str,"f\n");
   else if (display_mode == 1)              /*         if sci mode           */
      strcat(format_str,"E\n");
   else                                     /*         if general mode       */
      strcat(format_str,"G\n");
   if (sp < 0)
      printf("Stack empty");
   else
      for (i=0; i<=sp; i++)
         printf(format_str, stack[i]);
   }

else
   error(29);
}





/*****************************************************************************/
/*  chomp()                                                                  */
/*                                                                           */
/*  Remove final \n from end of string.                                      */
/*****************************************************************************/

void chomp (char *str)
{
int  len;                                   /* length of str (incl \n)       */

len = strlen (str);                         /* get length of str incl \n     */
if (str[len-1] == '\n')                     /* if final char is \n ..        */
   str[len-1] = '\0';                       /* ..then remove it              */
}





/*****************************************************************************/
/*                                                                           */
/*  Int()                                                                    */
/*                                                                           */
/*****************************************************************************/

double Int (double f)
{
return ((long)(f));
}





/*****************************************************************************/
/*                                                                           */
/*  Frac()                                                                   */
/*                                                                           */
/*****************************************************************************/

double Frac (double f)
{
return (f - (long)(f));
}





/*****************************************************************************/
/*                                                                           */
/*  round()                                                                  */
/*                                                                           */
/*  Round a double to the nearest integer.                                   */
/*                                                                           */
/*****************************************************************************/

long round(double x)
{
double result;

if (x < 0.0)
   result = (long)(x-0.5);
else
   result = (long)(x+0.5);
return result;
}

