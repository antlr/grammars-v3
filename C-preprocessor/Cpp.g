grammar Cpp;
options
{
	backtrack=true;
	memoize=true;
	output=AST;
}
tokens
{
	IFDEF;		IFNDEF;		IF;			ELSE;		ENDIF; 		
	WARNING; 	ERROR;		PRAGMA;
	EXPR;		EXPR_DEF;	EXPR_NDEF;
	UNARY_MINUS;UNARY_PLUS;	REFERANCE;
	TYPECAST;	SIZEOF_TYPE;INDEX_OP;	POST_INC;
	POST_DEC;	POINTER_AT;	POINTER;	EXPR_GROUP; 

	METHOD_CALL;ARGS; 

	TEXT_LINE;
	TEXT_GROUP;
	TEXT_END;

	EXPAND;		
	EXP_ARGS;
	EXP_ARG;
	EXEC_MACRO;
	CONCATENATE;

	LINE;
	INCLUDE; 	
	INCLUDE_EXPAND; 	
	DEFINE;		UNDEF;
	MAC_OBJECT; MAC_FUNCTION;			MAC_FUNCTION_OBJECT; 
	MACRO_DEFINE;
}
@lexer::header
{
	import java.io.File;
	import java.io.IOException;
}
@lexer::members {
	boolean inDirective =false;
	boolean inDefineMode=false;
	boolean discardSpace=true;
	int   ltoken=End;
	static char cpp = 'X';
	static String [] includeSearchPaths	=	
	{ "/usr/local/include", 
	  "/usr/lib/gcc/i386-redhat-linux/4.0.0/include",
	  "/usr/include/linux/stddef.h",
	 "/usr/include"	};
}

preprocess
		: procLine+ 
		;

procLine
		:	
		(	DIRECTIVE!
		|	text_line	
		|	diagnostics
		|	fileInclusion
		|	macroDefine
		|	macroUndef
		|	conditionalCompilation
		|	lineControl	
		|	macroExecution
		)?	End
		;

fileInclusion	
		:	INCLUDE  ->	 ^(INCLUDE)
		|	INCLUDE_EXPAND 	-> ^(INCLUDE_EXPAND)
		;

macroDefine		
		:	DEFINE  IDENTIFIER  LPAREN	WS?	RPAREN 	macro_text?	 -> ^(MAC_FUNCTION_OBJECT IDENTIFIER  macro_text?)
		|	DEFINE	mac=IDENTIFIER	 LPAREN	WS?		(arg+=macroParam	WS?	(COMMA	WS*	arg+=macroParam WS*)*)?	
			RPAREN	macro_text?  									-> ^(MAC_FUNCTION  $mac $arg+ macro_text? )
		| 	DEFINE	IDENTIFIER	macro_text?  						-> ^(MAC_OBJECT IDENTIFIER 		macro_text?)
		;

macroParam		
		:	IDENTIFIER ELLIPSIS ->^(ELLIPSIS IDENTIFIER) 
		|	ELLIPSIS
		|	IDENTIFIER
		;

macroExecution
		:	EXEC_MACRO ifexpression	-> ^(EXEC_MACRO ifexpression)
		;

macroUndef		
		:	UNDEF	mac=IDENTIFIER  -> ^(UNDEF IDENTIFIER)
		;

conditionalCompilation
		:	IF		ifexp+=ifexpression 	ifstmt+=statement		
			(ELIF	ifexp+=ifexpression 	ifstmt+=statement )*	 (ELSE 	elsestmt=statement)?	ENDIF
			->  ^(IF ($ifexp $ifstmt)+ (ELSE  $elsestmt)?)
		;

lineControl 	
		:	LINE	n=DECIMAL_LITERAL	(theFile=STRING_LITERAL)?  ->^(LINE $n ($theFile)? )
		;

diagnostics		
		:	WARNING	-> ^(WARNING)
		|	ERROR	-> ^(ERROR)
		|	PRAGMA	-> ^(PRAGMA)
		;

text_line		
		:	source_text+     -> ^(TEXT_LINE	source_text+)
		;


statement 		
		:	procLine+
		;

type_name		
		:	IDENTIFIER
		;

ifexpression
		: IDENTIFIER {input.LT(-2).getText().equals("ifndef")}?    -> ^(EXPR_NDEF  IDENTIFIER)
		| IDENTIFIER {input.LT(-2).getText().equals("ifdef")}?    -> ^(EXPR_DEF  IDENTIFIER)
		| assignmentExpression -> ^(EXPR assignmentExpression)
		;

assignmentExpression
		:	conditionalExpression
			(	(	ASSIGNEQUAL^^
				|   TIMESEQUAL^^
				|   DIVIDEEQUAL^^
				|   MODEQUAL^^
				|   PLUSEQUAL^^
				|   MINUSEQUAL^^
				|   SHIFTLEFTEQUAL^^
				|   SHIFTRIGHTEQUAL^^
				|	BITWISEANDEQUAL^^
				|	BITWISEXOREQUAL^^
				|	BITWISEOREQUAL^^
				)
			assignmentExpression
			)?
		;

conditionalExpression
		:	logicalOrExpression 
			( QUESTIONMARK^^ assignmentExpression COLON conditionalExpression )?
		;

logicalOrExpression
		:	logicalAndExpression (OR^^ logicalAndExpression)*
		;

logicalAndExpression
		:	inclusiveOrExpression (AND^^ inclusiveOrExpression)*
		;

inclusiveOrExpression
		:	exclusiveOrExpression (BITWISEOR^^ exclusiveOrExpression)*
		;

exclusiveOrExpression
		:	andExpression (BITWISEXOR^^ andExpression)*
		;

andExpression
		:	equalityExpression (AMPERSAND^^ equalityExpression)*
		;

equalityExpression
		:	relationalExpression ((NOTEQUAL^^ | EQUAL^^) relationalExpression)*
		;

relationalExpression
		:	shiftExpression
			(	(	(	LESSTHAN^^
					|	GREATERTHAN^^
					|	LESSTHANOREQUALTO^^
					|	GREATERTHANOREQUALTO^^
					)
				shiftExpression
				)*
			)
		;
shiftExpression
		:	additiveExpression ((SHIFTLEFT^^ | SHIFTRIGHT^^) additiveExpression)*
		;

additiveExpression
		:	multiplicativeExpression ((PLUS^^ | MINUS^^) multiplicativeExpression)*
		;

multiplicativeExpression
		:	unaryExpression ((STAR^^ | DIVIDE^^ | MOD^^ ) unaryExpression)*
		;

unaryExpression
		:	PLUSPLUS 	unaryExpression	-> ^(PLUSPLUS unaryExpression)
		|	MINUSMINUS	unaryExpression -> ^(MINUSMINUS unaryExpression)
		|	SIZEOF	unaryExpression	-> ^(SIZEOF unaryExpression)
		|	SIZEOF	LPAREN type_name RPAREN	->	^(SIZEOF_TYPE type_name)
		|	DEFINED	type_name			-> ^(DEFINED type_name)
		|	DEFINED	LPAREN type_name  RPAREN	->^(DEFINED type_name)
		|	unaryExpressionNotPlusMinus
		;

unaryExpressionNotPlusMinus
		:	NOT			unaryExpression	->	^(NOT	unaryExpression)
		|	TILDE		unaryExpression ->	^(TILDE		unaryExpression)
		|	AMPERSAND	unaryExpression ->	^(REFERANCE	unaryExpression)
		|	STAR		unaryExpression ->	^(POINTER_AT	unaryExpression)
		|	MINUS  unaryExpression 	-> ^(UNARY_MINUS unaryExpression)
		|	PLUS   unaryExpression	-> ^(UNARY_PLUS unaryExpression)
		|	LPAREN type_name RPAREN  unaryExpression -> ^(TYPECAST type_name unaryExpression)
		|	postfixExpression
		;

postfixExpression
		:   primaryExpression
		(   l=LSQUARE^^	{l.setType(INDEX_OP);} assignmentExpression RSQUARE!
		|   DOT^^     	IDENTIFIER       
		|	s=STAR^^	{s.setType(POINTER);}	IDENTIFIER
		|   POINTERTO^^ IDENTIFIER
		|   p=PLUSPLUS^^    {p.setType(POST_INC);}
		|   m=MINUSMINUS^^ {m.setType(POST_DEC);}
		)*  
		;

primaryExpression
		:   (IDENTIFIER LPAREN)	=> 	functionCall
		|   IDENTIFIER      
		|   constant     
		|   LPAREN  assignmentExpression RPAREN  -> ^(EXPR_GROUP assignmentExpression)
		;   

functionCall
		:	id=IDENTIFIER LPAREN argList? RPAREN	 -> ^(METHOD_CALL $id argList?)
		;

argList
		:	assignmentExpression (COMMA assignmentExpression)* -> ^(ARGS assignmentExpression+)
		;

constant		
		:   HEX_LITERAL
		|   OCTAL_LITERAL
		|   DECIMAL_LITERAL
		|	CHARACTER_LITERAL
		|	STRING_LITERAL
		|   FLOATING_POINT_LITERAL
		;

 
//		|	(IENTIFIER {System.out.println(input.LT(1).getText().equals("(")}?) => IDENTIFIER
source_text
		:   sourceExpression
		|	COMMA
		|	LPAREN
		|	RPAREN
		|	WS
		;

macroExpansion	
		:	id=IDENTIFIER WS? LPAREN WS?   RPAREN	 -> ^(EXPAND $id)
		|	id=IDENTIFIER WS? LPAREN WS? macArgs  WS? RPAREN	 -> ^(EXPAND $id macArgs?)
		;

macArgs	:	marg+=mArg ( WS? COMMA WS? marg+=mArg)*	 -> ^(EXP_ARGS $marg+)
		;

mArg	:	sourceExpression+ 	-> ^(EXP_ARG sourceExpression+)
		|	-> ^(EXP_ARG)
		;

sourceExpression	
		:	(IDENTIFIER WS? LPAREN)=> macroExpansion
		|	(primarySource	WS? SHARPSHARP ) =>  concatenate
		|	STRINGIFICATION	IDENTIFIER		->	^(STRINGIFICATION IDENTIFIER)
		|	primarySource
		|	STRING_OP
		|	SIZEOF
		|	LPAREN macArgs? RPAREN	-> ^(TEXT_GROUP macArgs?)
		|	SEMICOLON
		|	TEXT_END
		|	WS
		;

concatenate
		:	prim+=primarySource	(WS? SHARPSHARP  WS? prim+=primarySource)+  -> ^(CONCATENATE $prim+)
		;

primarySource
		: 	SHARPSHARP WS?	IDENTIFIER	-> ^(SHARPSHARP IDENTIFIER)
		|	IDENTIFIER 
		|	constant
		|	CKEYWORD
		|	COPERATOR
		;

STRING_OP:   {inDefineMode}? '#' WS?  id=IDENTIFIER
			{	this.setText(id.getText());	}
        ;    	

DIRECTIVE
@init 
{
	File 	sourceFile = null;
	File	currentDirectory=null;
	String	includeFile = null;
}
		:	{!inDirective && !inDefineMode}?	 '#' {inDirective=true; cpp='X'; discardSpace=false;}	 WS?
		(		'ifdef'	 		{ _type = IF;     discardSpace=true; this.setText("ifdef");}
			|	'ifndef' 		{ _type = IF;     discardSpace=true; this.setText("ifndef");}
			|	'if' 	  		{ _type = IF; 	  discardSpace=true; this.setText("if");}
			|	'elif' 	 		{ _type = ELIF;	  discardSpace=true;}
			|	'else' 	 		{ _type = ELSE;	  discardSpace=true;}
			|	'endif'	 		{ _type = ENDIF;  discardSpace=true;}
			|	'line'	 		{ _type = LINE;   discardSpace=true;}
			|	'undef'   WS 	{ _type = UNDEF;  discardSpace=true;}			
			|	'define'  WS	{ _type = DEFINE; cpp = 'D'; discardSpace=false;  }	
			|	'exec_macro_expression' {_type=EXEC_MACRO;discardSpace=true;}
			|	('include'|'include_next') WS	f=IDENTIFIER
				{
					_type = INCLUDE_EXPAND;
					this.setText(f.getText());
					discardSpace=true ;
				}	
			|	('include'|'include_next') WS	f=INCLUDE_FILE	
				{ 
				 	sourceFile = new File(String.valueOf(((ANTLRFileStream)input).getSourceName()));
					currentDirectory = sourceFile.getParentFile();
					String absolutePath = currentDirectory.getAbsolutePath();
					includeFile=f.getText();
	
					if(includeFile.startsWith("<"))
					{
						includeFile = includeFile.substring(1,includeFile.length()-1);
					
						if(!includeFile.startsWith("/"))
						{
							for (int i = 0; i < includeSearchPaths.length; ++i)
							{
								try 
								{   
										String path = new File(includeSearchPaths[i]).getCanonicalPath(); 
										File incFile = new File(path,includeFile);
										if (incFile.exists())
										{
											includeFile  = incFile.getCanonicalPath();
										}
								} 
								catch (Exception  e) 
								{; }
							}
						 }
					}
					else
					{
							includeFile = includeFile.substring(1,includeFile.length()-1);
							if(!includeFile.startsWith("/"))
							{
								try {   
									File incFile = new File(absolutePath,includeFile);
									if (incFile.exists())
									{
										includeFile  = incFile.getCanonicalPath();
									}
								} catch (Exception  e) 
								{
								}
							}
					}
							_type = INCLUDE;
							discardSpace=true ;
							this.setText(includeFile);
				}
			|	'warning'  { _type = WARNING;}  m=MACRO_TEXT 	{ this.setText(m.getText());}
			|	'error'    { _type = ERROR;  }  (m=MACRO_TEXT	{ this.setText(m.getText());})?
			|	'pragma'   { _type = PRAGMA; }  m=MACRO_TEXT	{ this.setText(m.getText());}
			|	
			)   	
		;

fragment MACRO_TEXT     
        :       (   ('/*' ) => '/*'  ( options {greedy=false;}:.)* '*/' 
            |   ('\\\n') => ('\\\n')
            |   ('\\\r\n') => ('\\\n')
            |   ~'\n'   
            ) +
        ;

SIZEOF	:	'sizeof'
		;

DEFINED	:	'defined'
			{	
				if(!inDirective)
				_type = CKEYWORD;
			}
		;
	
IDENTIFIER		
		:	LETTER (LETTER|'0'..'9')* 
			{
				if(inDirective == true)
				{
					if(cpp == 'D') 
					{
						if(input.LA(1) != '(' )
						{
				 			inDefineMode= true; 
				 			inDirective = false; 
				 			cpp = 'X';
						}
						else 
						{  
							cpp = '('; 
						}
					}
				}
			}
		;

fragment
LETTER	:   '$'
		|   'A'..'Z'
		|   'a'..'z'
		|   '_'
		;

/* Operators: */
					
STRINGIFICATION	:	'#_#_'
				;

SHARPSHARP		:	'##';

ASSIGNEQUAL		:	'='	;

COLON			:	':' ;

COMMA			:	',' ;

QUESTIONMARK	:	'?' ;

SEMICOLON		:	';' ;

POINTERTO		:	'->' ;

LPAREN			:	'(' ;

RPAREN	:	')' 
			{
				if(cpp=='(')
				{
					if(input.LA(1) != '\n')
					{
						inDefineMode = true; 
						inDirective = false; 
					}
					cpp ='X';
				}
			}
		;

LSQUARE			:	'[' ;

RSQUARE			:	']' ;

LCURLY			:	'{' ;

RCURLY			:	'}' ;

EQUAL			:	'==';

NOTEQUAL		:	'!=';

LESSTHANOREQUALTO
				:	'<=';

LESSTHAN 		:	'<' ;

GREATERTHANOREQUALTO
				:	'>=';

GREATERTHAN		:	'>' ;

DIVIDE			:	'/' ;

DIVIDEEQUAL		:	'/=';

PLUS			:	'+' ;

PLUSEQUAL		:	'+=';

PLUSPLUS		:	'++';

MINUS			:	'-' ;

MINUSEQUAL		:	'-=';

MINUSMINUS		:	'--';

STAR			:	'*' ;

TIMESEQUAL		:	'*=';

MOD				:	'%' ;

MODEQUAL		:	'%=';

SHIFTRIGHT		:	'>>';

SHIFTRIGHTEQUAL	:	'>>=';

SHIFTLEFT		:	'<<';

SHIFTLEFTEQUAL	:	'<<=';

AND				:	'&&';

NOT				:	'!' ;

OR				:	'||';

AMPERSAND		:	'&' ;

BITWISEANDEQUAL	:	'&=';

TILDE			:	'~' ;

BITWISEOR		:	'|' ;

BITWISEOREQUAL	:	'|=';

BITWISEXOR		:	'^' ;

BITWISEXOREQUAL	:	'^=';

DOT				:	'.' ;	

POINTERTOMBR	:	'->*' ;

DOTMBR			:	'.*'  ;

SCOPE			:	'::'  ;

ELLIPSIS		:	'...' ;

fragment
INCLUDE_FILE 	
		: '<' ( ' ' | '!' | '#' ..';' | '=' | '?' .. '[' | ']' .. '\u00FF')+ '>'
     	|   '"' ( ' ' | '!' | '#' ..';' | '=' | '?' .. '[' | ']' .. '\u00FF')+ '"'
     	;

CHARACTER_LITERAL
		:	('L')? '\'' ( EscapeSequence | ~('\''|'\\') ) '\''
		;

//STRING_LITERAL	:	'"' (options {greedy=false;} : EscapeSequence | ~('"'))* '"'
STRING_LITERAL	
		:	'"' (EscapeSequence | ~('"'))* '"'
		;

HEX_LITERAL		
		:	'0' ('x'|'X') HexDigit+ IntegerTypeSuffix? 
		;

DECIMAL_LITERAL	
		:	('0' | '1'..'9' '0'..'9'*) IntegerTypeSuffix?
		;

OCTAL_LITERAL	
		:	'0' ('0'..'7')+ IntegerTypeSuffix?
		;

fragment HexDigit		
		:	('0'..'9'|'a'..'f'|'A'..'F') 
		;

fragment IntegerTypeSuffix
		:	'u' | 'ul' | 'U' | 'UL' | 'l' | 'L'	
		;

FLOATING_POINT_LITERAL
		:	('0'..'9')+ '.' ('0'..'9')* Exponent? FloatTypeSuffix?
		|	'.' ('0'..'9')+ Exponent? FloatTypeSuffix?
		|	('0'..'9')+ Exponent FloatTypeSuffix?
		|	('0'..'9')+ FloatTypeSuffix
		;

fragment Exponent		
		:	('e'|'E') ('+'|'-')? ('0'..'9')+ 
		;

fragment FloatTypeSuffix	
		:	('f'|'F'|'d'|'D') 
		;

fragment EscapeSequence	
		: 	'\\' ('b'|'t'|'n'|'f'|'r'|'v'|'\"'|'\''|'\\')
		|	'\\' 'x' HexDigit+
		|   OctalEscape
		;

fragment OctalEscape		
		:	'\\' ('0'..'3') ('0'..'7') ('0'..'7')
		|	'\\' ('0'..'7') ('0'..'7')
		|	'\\' ('0'..'7')
		;

fragment UnicodeEscape	
		:	'\\' 'u' HexDigit HexDigit HexDigit HexDigit
		;

COMMENT			
		:	'/*'  ( options {greedy=false;}:.)* '*/' 			  {_channel=99;}
		|	'/' '\\' '\n' '*'  ( options {greedy=false;}:.)* '*/' {_channel=99;}
		;

LINE_COMMENT	
		:	'//' ~('\n'|'\r')* '\r'? '\n'
		{
			if(!inDirective)
			{
				try{					
						if(input.LT(1) != '#' && input.LT(1) != -1 )
						{
							_type = TEXT_END;
						}
						else
						{
							_type = End;
						}
				}
				catch(Exception e)
				{
					_type = End;
				}
			}
			else
			{
				 _type=End;
			}

			inDirective=false;
			inDefineMode=false;
			discardSpace = true;
		}
		;

WS		:	
		{ 
			if( this.getLine() != 1)
			{
				if(input.LA(-1) == '\n')
					ltoken = End;
				else
					ltoken = input.LA(-1);
			}
			else
			{
				try
				{
					if(input.LA(-1) == '\n')
						ltoken = End;
					else
						ltoken = input.LA(-1);	
				}
				catch (Exception e)
				{
					ltoken = End;
				}
			}

		}
		(' '|'\r'|'\t'|'\f')+
		{			 
			if(inDirective ==  true)
			{
				if(discardSpace == true)
				{
					_channel = 99;
				}
				else
				{
					_type = WS;
				}
			}
			else
			{
				if(!inDefineMode)
				{
					try
					{
						if(input.LA(1) != EOF  && input.LA(1) == '#' &&   ltoken == End )
						{
							_type = End;
						}
					}
					catch (Exception e)
					{
						_channel = 99;
					}
				}
			}
		}
		;

macro_text		
		:	source_text+ -> ^(MACRO_DEFINE source_text+)
		;

End		:	WS?	 '\n'
		{
			if(!inDirective)
			{
				if(inDefineMode) 
				{
					_type=End;
				}
				else
				{
						try{					
								if(input.LT(1) != '#' && input.LT(1) != -1 )
								{
									_type = TEXT_END;
								}
						}
						catch(Exception e)
						{
							_type = End;
						}
				}
			} else {_type=End;}
			ltoken =End;	
			inDirective=false;
			inDefineMode=false;
			discardSpace=true;
		}
		;

ESCAPED_NEWLINE	
		:	('\\\n' | '\\\r\n')
		{
			_channel=99;
		}
		;

COPERATOR       
		:   {!inDirective}? 
        (   COLON               |   QUESTIONMARK		
        |   POINTERTO			|	LCURLY				|	RCURLY			
		|	LSQUARE				|	RSQUARE           	|	STAR
        |   EQUAL               |   NOTEQUAL            |   LESSTHANOREQUALTO   |   LESSTHAN        
        |   GREATERTHANOREQUALTO|   GREATERTHAN         |   DIVIDE              |   PLUSPLUS
        |   MINUSMINUS          |   MOD                 |   SHIFTRIGHT          |   SHIFTLEFT 
        |   AND                 |   OR                  |   BITWISEOR           |   BITWISEXOR      
        |   DOT                 |   POINTERTOMBR        |   DOTMBR              |   SCOPE        
        |   AMPERSAND           |   PLUS                |   MINUS        
        |   TILDE               |   ASSIGNEQUAL         |   TIMESEQUAL          |   DIVIDEEQUAL
        |   MODEQUAL            |   PLUSEQUAL           |   MINUSEQUAL          |   SHIFTLEFTEQUAL 
        |   SHIFTRIGHTEQUAL     |   BITWISEANDEQUAL     |   BITWISEXOREQUAL     |   BITWISEOREQUAL
		|	NOT					|	ELLIPSIS			
        )
        ;

CKEYWORD	:	{!inDirective}?
					'typedef'	| '__va_list__'	| 'extern'	| 'static'	| 'auto'		| 'register' 
				|	'void' 		| 'char'		| 'short'	| 'int'		| 'long'		| 'float' 
				|	'double'	| 'signed'		| 'unsigned'| '__fpreg' | '__float80' 	| 'struct' 
				|	'union'		| 'enum'		| 'const'	| 'volatile'|  'case' 		| 'default'	
				|	'switch'	| 'while'		| 'do' 		| 'for' 	|	'goto'		| 'continue'	
				|	'break'		| 'return'  	| 'if' 		| 'else'	
				;
