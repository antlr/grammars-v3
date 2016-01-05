/*
 [The "RUBY licence"]
 Copyright (c) 2006 Sara di Gregorio and Pasquale De Medio
 All rights reserved.

 Ruby is copyrighted free software by Yukihiro Matsumoto <matz@netlab.co.jp>.
 You can redistribute it and/or modify it under either the terms of the GPL
 (see COPYING.txt file), or the conditions below:

  1. You may make and give away verbatim copies of the source form of the
     software without restriction, provided that you duplicate all of the
     original copyright notices and associated disclaimers.

  2. You may modify your copy of the software in any way, provided that
     you do at least ONE of the following:

       a) place your modifications in the Public Domain or otherwise
          make them Freely Available, such as by posting said
	  modifications to Usenet or an equivalent medium, or by allowing
	  the author to include your modifications in the software.

       b) use the modified software only within your corporation or
          organization.

       c) rename any non-standard executables so the names do not conflict
	  with standard executables, which must also be provided.

       d) make other distribution arrangements with the author.

  3. You may distribute the software in object code or executable
     form, provided that you do at least ONE of the following:

       a) distribute the executables and library files of the software,
	  together with instructions (in the manual page or equivalent)
	  on where to get the original distribution.

       b) accompany the distribution with the machine-readable source of
	  the software.

       c) give non-standard executables non-standard names, with
          instructions on where to get the original software distribution.

       d) make other distribution arrangements with the author.

  4. You may modify and include the part of the software into any other
     software (possibly commercial).  But some files in the distribution
     are not written by the author, so that they are not under this terms.

     They are gc.c(partly), utils.c(partly), regex.[ch], st.[ch] and some
     files under the ./missing directory.  See each file for the copying
     condition.

  5. The scripts and library files supplied as input to or produced as 
     output from the software do not automatically fall under the
     copyright of the software, but belong to whomever generated them, 
     and may be sold commercially, and may be aggregated with this
     software.

  6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
     IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
     PURPOSE.
*/

/** Ruby 1.0 Grammar
 *
 *  Sara di Gregorio and Pasquale De Medio
 *  September 2006
 *
 *  This grammar is a simplified Ruby grammar. It's a starter point for construct 
 *  an extended Ruby Grammar.
 *  We had tested this grammar with many simple examples.
 *
 *  We had worked with ANTLR version 2.7.5
 **/

header 
/**
 * PARSER    
 **/
class P extends Parser;
options {
	k = 6; // set to 6 the token lookahead
        buildAST = true;
}

imaginaryTokenDefinition:
  PROGRAM;

// begin Ruby Program
program 
    :   ( class_def (NEWLINE)+  | statement (NEWLINE)+)* 
    ;

class_def
    :   "class"^ 
        class_name
        (NEWLINE 
        | "<" class_parent 
        ("<" class_parent
        )* NEWLINE )
        class_body
        "end"
    ;

class_name
    :   IDENTIFIER 
    ;

class_parent
    :   IDENTIFIER
    ;

class_body
    : ( (statement NEWLINE  ) | ( method_def NEWLINE) )+
    ;

method_def
    :   "def"^ 
        (class_name ".")? method_name
        ((method_par)*
        |( "(" method_par ("," method_par )* ")" )* )
        ( NEWLINE )+
        method_body
        "end"
    ;

method_name
    :   IDENTIFIER
    ;

method_par
    :   IDENTIFIER
    ;

method_body
    : (statement NEWLINE  )*
    ;

// Instruction in the program body
statement
    :   // if
          "if"^ 
          "(" c=condition ")" NEWLINE b=block "end" 
	| "break if"^ 
          "(" c=condition ")" 
	| // loop do
          "loop" "do"^ NEWLINE loopBody=block "end"
	| // yield
          "yield"^
          "(" operando ")" 
        | // return
          "return"^ (operando  | "("operando ")" )
        | // return
          "return"^ (booleani | "(" booleani ")" )
        | // puts
          "puts"^ statement 
	| // id = (number | id | string)
          (DAT IDENTIFIER) 
          "="^ (operando | "(" operando_par ")" )
        | // id = id (id, id, ...)
          (DAT IDENTIFIER)
          "="^ 
          (class_name "." method_name)
          ( ("(" ")") | ( "(" 
          opAsClassMet=operando 
          ("," 
          op1AsClassMet=operando )* 
          ")" ) )?
        | // id = id (id, id, ...)
          (DAT IDENTIFIER)
          "="^ 
          method_name
          ( ("(" ")") | ( "(" 
          operando
          ("," 
          operando )* 
          ")" ) )?
        | // id = (number | id | string)
	  (AT IDENTIFIER) 
          "="^ (operando | "(" operando ")" )
        | // id = id (id, id, ...)
          (AT iAsClassMetF:IDENTIFIER)
          "="^ 
          (class_name "." method_name)
          ( ("(" ")") | ( "(" 
          operando 
          ("," 
          operando )* 
          ")" ) )?
        | // id = id (id, id, ...) 
          (AT IDENTIFIER)
          "="^ 
          method_name
          ( ("(" ")") | ( "(" 
          operando 
          ("," 
          operando )* 
          ")" ) )?
        | // id = (number | id | string)
          IDENTIFIER  
          "="^ (operando  | "(" operando ")" )
        | // id = id (id, id, ...)
          IDENTIFIER 
          "="^ 
          (class_name "." method_name)
          ( ("(" ")")| ( "(" 
          opAsClassMet=operando 
          ("," 
          op1AsClassMet=operando)* 
          ")" ) )?
        | // id = id (id, id, ...)
          IDENTIFIER 
          "="^ 
          method_name
          ( ("(" ")")  | ( "(" 
          operando 
          ("," 
          operando )* 
          ")" ) )?
        | operando 
    ;

block
    :   (s=statement NEWLINE  )+
    ;
	   
// condition or operation 
condition
    :   // condition operator (IDENTIFIER | NUMBER)
          booleani 
        | booleani ("&"^ 
                    | "|"^) 
          booleani  
        | "(" condition ")" 
        | booleani "|"^
          condition 
        | booleani "&"^ booleani ("&"^
                               | "|"^) 
        condition
    ;

// math instruction
instruction returns
    :     "(" operando_par ")"  ( "/"^ operando
                                | "*"^  operando  
                                | "+"^  operando 
                                | "-"^ operando  )?
        | "(" instruction_par ")" ( "/"^  operando
                                  | "*"^ operando
                                  | "+"^ operando
                                  | "-"^ operando )?
        | (DAT IDENTIFIER) ( "/"^ operando 
                           | "*"^ operando 
                           | "+"^ operando 
                           | "-"^ operando  )
        | (AT IDENTIFIER) ( "/"^ operando 
                          | "*"^ operando 
                          | "+"^ operando 
                          | "-"^ operando )
        | IDENTIFIER ( "/"^ operando 
                     | "*"^ operando
                     | "+"^ operando 
                     | "-"^ operando  )
        | //NUMBER operator NUMBER
          n:NUMBER ( "/"^ operando
                   | "*"^ operando 
                   | "+"^ operando
                   | "-"^ operando)
    ;

instruction_par
    :   instruction  
    ;

operando_par
    :   operando  
    ;

// "return"
operando
    :     NUMBER 
        | (DAT IDENTIFIER) 
        | (AT IDENTIFIER) 
        | IDENTIFIER 
        | class_name "." "new" ( "." method_name  ("." method_name)* )?
          ( "(" 
          operando 
          ("," 
          operando 
          )* ")" )?
        | // id((id | number),(id|number)*) do |id|
          (class_name "." method_name)
          ( ("(" ")")  | ( "(" 
          operando 
          ("," 
          operando  )* 
          ")" ) )?
          ( "do" "|" IDENTIFIER 
                 "|" NEWLINE 
                  block
                  "end")?
        | // id((id | number),(id|number)*) do |id|
          method_name
          ( ("(" ")")  | ( "(" 
          operando
          ("," 
          operando )* 
          ")" ) )?
	  ( "do" "|" IDENTIFIER 
                 "|" NEWLINE 
                 block
                 "end")?
        | instruction 
        | "(" instruction_par ")" 
    ;

booleani
    :     "true" 
        | "false"
        | operando ( "<"^ operando
                   | "<="^ operando
                   | ">="^ operando 
                   | ">"^  operando
                   | "=="^ operando  )
      
    ;

/**
 * LEXER
 **/
class RubyLexer extends Lexer;

options {
  k = 6; 
}

WS	: ' '{ _ttype = Token.SKIP; }
	;

LPAREN  : '('
	;

RPAREN  : ')'
	;

LT      : '<'
        ;
LE      : "<="
        ;
GE      : ">="
        ;
GT      : '>'
        ;
EGUAL   : "=="
        ;
DIV     : '/'
        ;
MUL     : '*'
        ;
ASSIGN  : '='
        ;
PLUS    : '+'
        ;
OR      : '|' 
        ;  
AND     : '&'
        ;
SUB     : '-'
        ;
MOD     : '%'
        ;
NUMBER  : ('0'..'9')+ 
        ;
POINT   : ('.')+
        ;
AT      : '@'
        ;
DAT     : "@@"
        ;
	 
// Id
IDENTIFIER : ('a'..'z'|'A'..'Z')+ (NUMBER)*
           ;

// new line
NEWLINE : ( "\r\n" // DOS
        | "\r" // MAC
        | "\n" // Unix
        );
