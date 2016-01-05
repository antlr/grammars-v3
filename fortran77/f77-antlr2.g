/*
 * Fortran 77 grammar for ANTLR 2.7.5
 * Adadpted from Fortran 77 PCCTS grammar by Olivier Dragon
 * Original PCCTS grammar by Terence Parr
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *
 */

header {
package fortran77.parser;

import antlr.CommonToken;
}

class Fortran77Parser extends Parser;
options {
    k = 2;
    exportVocab=Fortran77;
    defaultErrorHandler = false; // useful to get stackstraces and reduce noise
    buildAST = true;
    codeGenMakeSwitchThreshold=3;
    codeGenBitsetTestThreshold=6;
}

tokens
{
	LABELREF; // reference to a defined LABEL, eg. in a goto statement
	XCON;
	PCON;
	FCON;
	RCON;
	CCON;
	HOLLERITH;
	CONCATOP;
	CTRLDIRECT;
	CTRLREC;
	TO;
	SUBPROGRAMBLOCK;
	DOBLOCK;
	AIF;
	THENBLOCK;
	ELSEIF;
	ELSEBLOCK;
	CODEROOT;
}

{
	private AST createNewNode(int type, String text, int line, int column)
	{
		Token t = new CommonToken(type, text);
		t.setLine(line);
		t.setColumn(column);
		return new TokenAST(t);
	}
}

/* Start rule */
program :
	((~COMMENT)=> executableUnit |
		( options { greedy=true; } : COMMENT )+
	)+
	
	// This action creates a single root node for the whole code. Otherwise
	// ANTLR makes all top-level nodes (eg. subroutine, function, etc.) as
	// siblings without a parent.
	{ #program = #([CODEROOT, "[program]"], #program) ; }
	;

/* one unit of a fortran program */
executableUnit :
	(functionStatement)=>functionSubprogram | 
	mainProgram |
	subroutineSubprogram |
	blockdataSubprogram
	;

/* 2 */
mainProgram :
	(s:programStatement)? b:subprogramBody!
	
	// This action ensures that subprogramBody is a child node of
	// programStatement. Without it subprogramBody becomes the child of
	// program. For this to work we must omit subprogramBody from the
	// automatic AST building (using "!") otherwise we get the subtree twice.
	{
		if (#s != null) {
			#s.addChild(#b);
			#mainProgram = #s;
		} else {
			#mainProgram = #([LITERAL_program, "program"], [NAME, "main"], #b);
		}
	}
	;

/* 3 */
functionSubprogram :
	s:functionStatement b:subprogramBody!
	
	// This action ensures that subprogramBody is a child node of
	// functionStatement. Without it subprogramBody becomes the child of
	// program.
	{
		#s.addChild(#b);
		#functionSubprogram = #s;
	}
	;

/* 4 */
subroutineSubprogram :
	s:subroutineStatement b:subprogramBody!
	
	// This action ensures that subprogramBody is a child node of
	// subroutineStatement. Without it subprogramBody becomes the child of
	// program.
	{
		#s.addChild(#b);
		#subroutineSubprogram = #s;
	}
	;

/* 5 - blockDataSubprogram */
blockdataSubprogram :
	s:blockdataStatement b:subprogramBody!
	
	// This action ensures that subprogramBody is a child node of
	// blockdataStatement. Without it subprogramBody becomes the child of
	// program.
	{
		#s.addChild(#b);
		#blockdataSubprogram = #s;
	}
	;

/* 6 */
otherSpecificationStatement :
    dimensionStatement |
	equivalenceStatement |
	intrinsicStatement |
	saveStatement
	;

/* 7 */
executableStatement :
    (assignmentStatement |
	gotoStatement |
	ifStatement |
	doStatement |
	continueStatement |
	stopStatement |
	pauseStatement |
	readStatement |
	writeStatement |
	printStatement |
	rewindStatement |
	backspaceStatement |
	openStatement |
	closeStatement |
	endfileStatement |
	inquireStatement |
	callStatement |
	returnStatement )
	;

/* 8 */
programStatement :
	"program"^ NAME seos ;

seos : EOS! ;

/* 9, 11, 13 */
entryStatement : 
	"entry"^ NAME (LPAREN! namelist RPAREN!)? ;

/* 10 */
functionStatement :
	(type)?
	"function"^ NAME LPAREN! (namelist)? RPAREN! seos ;

blockdataStatement :
	"block"^ NAME seos ;

/* 12 */
subroutineStatement :
	"subroutine"^ NAME ( LPAREN! (namelist)? RPAREN! )? seos ;
	
namelist:
	identifier ( COMMA! identifier )* ;

statement :
	formatStatement |
	entryStatement |
	implicitStatement |
	parameterStatement |
	typeStatement |
	commonStatement |
	pointerStatement |
	externalStatement |
	otherSpecificationStatement |
	dataStatement |
	(statementFunctionStatement)=>statementFunctionStatement |
	executableStatement
	;

/* 2,3,4,5 body of a subprogram (after program/subroutine/function line) */
subprogramBody :
	( wholeStatement )*
	endStatement
	
	// This action creates a root AST node with token type CODEBLOCK and
	// token text "subprogramBody". Therefore all statements within the
	// sub-program's body are children of a single node.
	{#subprogramBody = #([SUBPROGRAMBLOCK, "[subprogramBody]"], #subprogramBody);}
	;

wholeStatement :
	COMMENT |
	(l:LABEL!)?
		{LA(1) != LITERAL_end}? s:statement seos
	 
	 // This action inserts the label as the first child of the root node of
	 // the statement. It is only executed if the matched token is not a
	 // COMMENT.
	 {
	 	if (#l != null)
	 	{
	 		AST tmpFirstChild = #s.getFirstChild();
	 		#l.setNextSibling(tmpFirstChild);
	 		#s.setFirstChild(#l);
	 	}
	 }
	 ;

endStatement :
	 (LABEL)? "end"^ seos ;

/* 15 */
dimensionStatement : 
	"dimension"^ arrayDeclarators ;

/* 16 */
arrayDeclarator : 
	( NAME^ | n:"real"^ {n.setType(NAME);})
	LPAREN! arrayDeclaratorExtents RPAREN!
	;

arrayDeclarators : 
	arrayDeclarator (COMMA! arrayDeclarator)* ;

arrayDeclaratorExtents :
	arrayDeclaratorExtent (COMMA! arrayDeclaratorExtent)* ;

arrayDeclaratorExtent : 
	iexprCode (COLON^ (iexprCode | STAR ) )? |
	STAR
	;

/* 17 */
equivalenceStatement : 
	"equivalence"^ equivEntityGroup (COMMA! equivEntityGroup)* ;

equivEntityGroup: LPAREN^ equivEntity (COMMA! equivEntity)* RPAREN! ;

/* 18 */
equivEntity : varRef ;

/* 19 */
commonStatement :
	"common"^ (commonBlock (COMMA! commonBlock)* | commonItems) ;
commonName : 
	DIV (NAME DIV | DIV) ;
commonItem :
	NAME | arrayDeclarator ;
commonItems :
	commonItem (COMMA! commonItem)* ;
commonBlock :
	commonName commonItems ;

/* 20 */
// need to expand the typename rule to produce a better AST
typeStatement! :
	ty:typename ls:typeStatementNameList
	{ #ty.addChild(#ls); #typeStatement = #ty; }
	|
	c:characterWithLen t:typeStatementNameCharList!
	{ #c.addChild(#t); #typeStatement = #c; }
	;

typeStatementNameList :
	typeStatementName (COMMA! typeStatementName)*
	;
typeStatementName :
	NAME | arrayDeclarator ;

typeStatementNameCharList :
	typeStatementNameChar (COMMA! typeStatementNameChar)* ;
typeStatementNameChar! :
	n:typeStatementName (len:typeStatementLenSpec)?
	{ #n.addChild(#len); #typeStatementNameChar = #n; }
	;

typeStatementLenSpec :
	  STAR^ lenSpecification ;
	
typename :
	("real" |
	 c:"complex" (STAR! i:ICON! {Integer.parseInt(i.getText()) == 16}?
	 		{ #c.setType(LITERAL_double); #c.setText("double"); } )? |
	 "double" "complex"! |
	 "double"! "precision" |
	 "integer" |
	 "logical")
	;
	
type : typename | characterWithLen ;

typenameLen :
	STAR^ ICON ;

/* "Cray" pointer */

pointerStatement :
	"pointer"^ pointerDecl (COMMA! pointerDecl)* ;

pointerDecl :
	LPAREN!
	NAME^ COMMA! NAME
	RPAREN!
	;


/* 21 */
implicitStatement : 
	"implicit"^ (implicitNone | implicitSpecs) ;

implicitSpec! : 
	ty:type LPAREN! im:implicitLetters RPAREN!
	{ #ty.addChild(#im); #implicitSpec = #ty; }
	;

implicitSpecs : implicitSpec (COMMA! implicitSpec)* ;

implicitNone : "none" ;

implicitLetter : NAME ;

implicitRange : implicitLetter (MINUS^ implicitLetter)?;

implicitLetters : 
	implicitRange (COMMA! implicitRange)* ;

/* 22 */
lenSpecification : 
	(LPAREN STAR RPAREN)=> LPAREN! STAR RPAREN! |
	ICON |
	LPAREN intConstantExpr RPAREN ;

characterWithLen : "character"^ (cwlLen)? ; 

cwlLen :
	STAR^ lenSpecification
	;

/* 23 */
parameterStatement : 
	"parameter"^ LPAREN! paramlist RPAREN!;

paramlist : paramassign ( COMMA! paramassign )* ;
paramassign : NAME ASSIGN^ constantExpr ;

/* 24 */
externalStatement :
	"external"^ namelist ;

/* 25 */
intrinsicStatement : 
	"intrinsic"^ namelist ;

/* 26 */
saveStatement : "save"^ (saveEntity (COMMA! saveEntity)*)? ;
saveEntity : ( NAME | DIV^ NAME DIV! ) ;

/* 27 */
dataStatement : 
	"data"^ dataStatementEntity ((COMMA!)? dataStatementEntity)* ;
dataStatementItem : 
	varRef | dataImpliedDo ;

dataStatementMultiple : 
	((ICON | NAME) STAR^)? (constant | NAME) ;

dataStatementEntity :
	dse1 dse2 ;

dse1:   dataStatementItem (COMMA! dataStatementItem)* DIV^ ;
dse2:   dataStatementMultiple (COMMA! dataStatementMultiple)* DIV^ ;

/* 28 */
dataImpliedDo : 
	LPAREN^	dataImpliedDoList COMMA! dataImpliedDoRange	RPAREN!
	;
	
dataImpliedDoRange :
	NAME ASSIGN^ intConstantExpr COMMA! intConstantExpr
		(COMMA! intConstantExpr)?
	;

dataImpliedDoList :
	dataImpliedDoListWhat | COMMA! dataImpliedDoList ;

dataImpliedDoListWhat : 
	(varRef | dataImpliedDo ) ;

/* 29 */
assignmentStatement : 
	varRef ASSIGN^ expression |
//	"let" varRef ASSIGN expression |
	"assign"^ ICON to! variableName 
	;

/* 30 */
gotoStatement : 
	("goto"^ | "go"^ to!)
	(unconditionalGoto | computedGoto | assignedGoto)
	;

/* 31 */
unconditionalGoto : 
	lblRef ;

/* 32 */
computedGoto :
	LPAREN! labelList RPAREN (COMMA!)? integerExpr ;

lblRef :
	l:ICON   { #l.setType(LABELREF); }
	;

labelList : lblRef (COMMA! lblRef)* ;

/* 33 */
assignedGoto : 
	NAME ( (COMMA!)? LPAREN! labelList RPAREN! )? ;


/* 34 */
ifStatement :
	i:"if"^ LPAREN! logicalExpression RPAREN!
	(blockIfStatement | logicalIfStatement[i] |
		arithmeticIfStatement { #i.setType(AIF); } )
	;

arithmeticIfStatement : 
	lblRef COMMA! lblRef COMMA! lblRef ;

/* 35 */
logicalIfStatement[Token ifstmt] : 
	executableStatement
	
	{ #logicalIfStatement = #(createNewNode(THENBLOCK, "then", ifstmt.getLine(),
		ifstmt.getColumn()), #logicalIfStatement); }
	;

/* 36 */
blockIfStatement : 
	firstIfBlock
	(options { greedy=true; } :
		elseIfStatement)*
	(elseStatement)?
	endIfStatement
	;

firstIfBlock :
	then:"then"! seos
	(wholeStatement)+
	
	{ #firstIfBlock = #(createNewNode(THENBLOCK, "then", then.getLine(),
		then.getColumn()), #firstIfBlock); }
	;

/* 37 */
elseIfStatement { Token el = null;}	: 
	{ el = LT(1); }
	("elseif"! | "else"! "if"!)
	LPAREN! le:logicalExpression! RPAREN! t:"then"! seos
	(wholeStatement)*
	
	// this action is used to ensure that in the AST there is a clear difference
	// between
	// ELSE IF ...
	// and
	// ELSE
	//    IF ... END IF
	// END IF
	// this is done by replacing the "else if" by one "elseif" inside the AST
	{
		#elseIfStatement =
		#(createNewNode(ELSEIF, "elseif", el.getLine(), el.getColumn()),
			#le,
			#(createNewNode(THENBLOCK, "then", t.getLine(), t.getColumn()),
				#elseIfStatement) ) ;
	}
	;

/* 38 */
elseStatement :
	e:"else"! seos
	(wholeStatement)*
	
	{ #elseStatement = #(createNewNode(ELSEBLOCK, "else", e.getLine(),
		e.getColumn()), #elseStatement) ; }
	;

/* 39 */
endIfStatement : ("endif"! | "end"! "if"!) ;

/* 40 */
doStatement : 
	d:"do"^ (doWithLabel | doWithEndDo[d]) ;

doVarArgs :
	variableName ASSIGN! intRealDpExpr COMMA!
	intRealDpExpr ( COMMA! intRealDpExpr )?
	;

doWithLabel :
	lblRef (COMMA!)? doVarArgs ;

doBody [Token doT] :
	(wholeStatement)*
	
	// this action ensures that the loop body's statements are children of a
	// CODEBLOCK node for the loop.
	{ #doBody = #(createNewNode(DOBLOCK, "[doLoopBody]", doT.getLine(),
		doT.getColumn()), #doBody) ; }
	;

doWithEndDo [Token doT] :
	doVarArgs
	doBody[doT]
	enddoStatement
	;
	
enddoStatement : ("enddo"! | "end"! "do"!) ;

/* 41 */
continueStatement : "continue" ;

/* 42 */
stopStatement : "stop"^ (ICON|HOLLERITH)? ;

/* 43 */
pauseStatement : "pause"^ (ICON|HOLLERITH) ;

/* 44 */
writeStatement : 
	"write"^ LPAREN controlInfoList RPAREN ( ioList )? ;

/* 45 */
readStatement : 
	"read"^ 
	(
		(formatIdentifier ( COMMA ioList )? EOS)=>
	  		(formatIdentifier ( COMMA ioList )?) |
		LPAREN controlInfoList RPAREN ( ioList )?
	)
	;

/* 46 */
printStatement : 
	"print"^ formatIdentifier (COMMA ioList)? ;

/* 47 */
controlInfoList : 
	controlInfoListItem (COMMA! controlInfoListItem)* ;

controlErrSpec :
	controlErr  ASSIGN^ (lblRef | NAME) ;

controlInfoListItem :	
	unitIdentifier | HOLLERITH | SCON |
	controlFmt ASSIGN^ formatIdentifier |
	controlUnit ASSIGN^ unitIdentifier |
	controlRec ASSIGN^ integerExpr |
	controlEnd ASSIGN^ lblRef |
	controlErrSpec |
	controlIostat ASSIGN^ varRef
	;

/* 48 */
/* ioList : (ioListItem COMMA ioList)=>| ioListItem ; */
ioList : 
	(ioListItem COMMA NAME ASSIGN)=> ioListItem |
	(ioListItem COMMA ioListItem)=>ioListItem COMMA ioList |
	ioListItem
	;

ioListItem : 
	(LPAREN ioList COMMA NAME ASSIGN)=> ioImpliedDoList  |
	expression
	;

/* 49 */
ioImpliedDoList : 
	LPAREN^
	ioList COMMA
	NAME ASSIGN! intRealDpExpr COMMA!
	intRealDpExpr ( COMMA! intRealDpExpr )?
	RPAREN!
	;

/* 50 */
openStatement : 
	"open"^ LPAREN! openControl (COMMA! openControl)* RPAREN! ;

openControl : 
	unitIdentifier |
	controlUnit ASSIGN^ unitIdentifier |
	controlErrSpec |
	controlFile ASSIGN^ characterExpression |
	controlStatus ASSIGN^ characterExpression |
	(controlAccess|controlPosition) ASSIGN^ characterExpression|
	controlForm ASSIGN^ characterExpression |
	controlRecl ASSIGN^ integerExpr |
	controlBlank ASSIGN^ characterExpression |
	controlIostat ASSIGN^ varRef ;

controlFmt : "fmt" ;
controlUnit : "unit" ;
controlRec : n:NAME {n.getText().compareToIgnoreCase("rec") == 0}?
	{n.setType(CTRLREC);} ;
controlEnd : "end" ;
controlErr : "err" ;
controlIostat : "iostat" ;
controlFile : "file" ;
controlStatus : "status" ;
controlAccess : "access" ;
controlPosition : "position" ;
controlForm : "form" ;
controlRecl : "recl" ;
controlBlank : "blank" ;
controlExist : "exist" ;
controlOpened : "opened" ;
controlNumber : "number" ;
controlNamed : "named" ;
controlName : "name" ;
controlSequential : "sequential" ;
controlDirect : n:NAME {n.getText().compareToIgnoreCase("direct") == 0}?
	{n.setType(CTRLDIRECT);} ;
controlFormatted : "formatted" ;
controlUnformatted : "unformatted" ;
controlNextrec : "nextrec" ;

/* 51 */
closeStatement : 
	"close"^ LPAREN! closeControl (COMMA! closeControl)* RPAREN! ;

closeControl : 
	unitIdentifier |
	controlUnit ASSIGN^ unitIdentifier |
	controlErrSpec |
	controlStatus ASSIGN^ characterExpression |
	controlIostat ASSIGN^ varRef ;

/* 52 */
inquireStatement : 
	"inquire"^ LPAREN! inquireControl (COMMA! inquireControl)* RPAREN! ;

inquireControl : 
	controlUnit ASSIGN^ unitIdentifier |
	controlFile ASSIGN^ characterExpression |
	controlErrSpec |
	(controlIostat | controlExist | controlOpened |
	 controlNumber | controlNamed | controlName |
	 controlAccess | controlSequential | controlDirect |
	 controlForm | controlFormatted | controlUnformatted |
	 controlRecl | controlNextrec | controlBlank) 
	  ASSIGN^ varRef  |
	unitIdentifier
	;

/* 53 */
backspaceStatement : "backspace"^ berFinish ;

/* 54 */
endfileStatement : "endfile"^ berFinish ;

/* 55 */
rewindStatement : "rewind"^ berFinish ;

berFinish : 
	( (unitIdentifier EOS)=> (unitIdentifier) | 
	  LPAREN
	  berFinishItem (COMMA! berFinishItem)*
	  RPAREN!
	) ;

berFinishItem : 
	unitIdentifier | 
	controlUnit ASSIGN^ unitIdentifier |
	controlErrSpec |
	controlIostat ASSIGN^ varRef;

/* 56 */
unitIdentifier : 
	iexpr | STAR ;

/* 57 */
formatIdentifier : 
	 SCON | HOLLERITH | iexpr | STAR ;

/* 58-59 */
formatStatement : "format"^ LPAREN! fmtSpec RPAREN! ;

/* 60 */
fmtSpec:
  (formatedit | formatsep (formatedit)?)
  (
  	formatsep (formatedit)? |
  	COMMA (formatedit | formatsep (formatedit)?)
  )*
  ;
  
formatsep: DIV | COLON | DOLLAR ;

formatedit :
  XCON |
  editElement |
  ICON editElement |
  (PLUS|MINUS)? PCON ((ICON)? editElement)?
  ;
editElement:
  FCON | SCON | HOLLERITH | n:NAME {n.setType(FCON);} | LPAREN fmtSpec RPAREN ;

/* 70 */
statementFunctionStatement : 
	"let"^ sfArgs ASSIGN! expression ;

sfArgs :
	NAME^ LPAREN! namelist RPAREN! ;

/* 71 */
callStatement : 
	"call"^ subroutineCall ;

subroutineCall :
	NAME^ ( LPAREN! (callArgumentList)? RPAREN! )? ;

callArgumentList : 
	callArgument (COMMA! callArgument)* ;
callArgument : 
	expression | STAR! lblRef ;

/* 72 */
returnStatement : "return"^ ( integerExpr )? ;

/* 74 */
expression : ncExpr (COLON^ ncExpr)? ;
ncExpr : lexpr0 ({LA(2) == DIV}? concatOp lexpr0)* ; // concatenation
lexpr0 : lexpr1 ((NEQV^ | EQV^) lexpr1)* ;
lexpr1 : lexpr2 (LOR^ lexpr2)* ;
lexpr2 : lexpr3 (LAND^ lexpr3)* ;
lexpr3 : LNOT^ lexpr3 | lexpr4 ;
lexpr4 : aexpr0 ( (LT^ | LE^ | EQ^ | NE^ | GT^ | GE^) aexpr0 )? ;
aexpr0 : aexpr1 ((PLUS^ | MINUS^) aexpr1)* ;
aexpr1 : aexpr2 ((STAR^ | DIV^) aexpr2)* ;
aexpr2 : (PLUS^ | MINUS^)* aexpr3 ;
aexpr3 : aexpr4 ( POWER^ aexpr4 )* ;
aexpr4 : (unsignedArithmeticConstant)=> unsignedArithmeticConstant | 
		  HOLLERITH |
		  SCON |
		  logicalConstant |
		  varRef |
		  LPAREN! expression RPAREN! ;

/* integer expression */
iexpr :
	iexpr1 ((PLUS^ | MINUS^) iexpr1)* ;

/* integer expression with fpe return code. */
iexprCode:
	iexpr1 ((PLUS^ | MINUS^) iexpr1)* ;
iexpr1:
	iexpr2 ((STAR^ | DIV^) iexpr2)* ;
iexpr2:
	 (PLUS^ | MINUS^)* iexpr3 ;
iexpr3: 
	iexpr4 (POWER^ iexpr3)? ;
iexpr4:
	ICON | varRefCode | LPAREN^ iexprCode RPAREN ;

/* 75 */
constantExpr : expression ;

/* 76 */
arithmeticExpression : expression ;

/* 77 */
integerExpr : iexpr ;

/* 78 */
intRealDpExpr : expression ;

/* 79 */
arithmeticConstExpr : expression ;

/* 80 */
intConstantExpr :  expression ;

/* 82 */
characterExpression : expression ;

concatOp! :
	DIV DIV

	{ #concatOp = #[CONCATOP, "//"] ; }
	;

/* 84 */
logicalExpression : expression ;

/* 85 */
logicalConstExpr : expression ;
	
/* 88 */
arrayElementName : 
	NAME^ LPAREN! integerExpr (COMMA! integerExpr)* RPAREN! ;

subscripts:
	LPAREN! ( expression (COMMA! expression)* )? RPAREN! ;

varRef :
	(NAME^ | n:"real"^ {n.setType(NAME);}) (subscripts ( substringApp )? )? ;

varRefCode :
	NAME^ (subscripts ( substringApp )? )? ;

substringApp :
	LPAREN! (ncExpr)? COLON^ (ncExpr)? RPAREN! ;

/* 91 */
variableName : NAME ;
/* 92 */
arrayName : NAME;

/* 97 */
subroutineName : NAME ;

/* 98 */
functionName : NAME ;

/* 100 */
constant : 
	( (PLUS^ | MINUS^) )? unsignedArithmeticConstant |	
	SCON | HOLLERITH | logicalConstant ;

/* 101 */
unsignedArithmeticConstant : 
	ICON | RCON | complexConstant ;

/* 107 */
complexConstant! : 
	LPAREN!
	  ((p1:PLUS|m1:MINUS))? (i1:ICON|r1:RCON)
	COMMA!
	  ((p2:PLUS|m2:MINUS))? (i2:ICON|r2:RCON)
	RPAREN!
	// sanity check
	{(i1 != null && i2 != null) || (r1 != null && r2 != null)}?
	
	{
		AST re, im;
		if (i1 != null)
		{
			re = #i1;
			im = #i2;
		}
		else // if (r1 != null)
		{
			re = #r1;
			im = #r2;
		}
		
		if (p1 != null)
			re = #(p1, re);
		else if (m1 != null)
			re = #(m1, re);

		if (p2 != null)
			im = #(p2, im);
		else if (m2 != null)
			im = #(m2, im);
		
		#complexConstant = #([CCON, "[complex]"], re, im);
	}
	;

/* 108 */
logicalConstant : (TRUE | FALSE);

// needed because Fortran doesn't have reserved keywords. Putting the rule
// "keyword" instead of a few select keywords breaks the parser with harmful
// non-determinisms
identifier { Token id = LT(1); }:
	NAME |
	( "real" )
	{ id.setType(NAME); }
	;

to : n:NAME {n.getText().compareToIgnoreCase("to") == 0}? {n.setType(TO);} ;

// keyword contains all of the FORTRAN keywords.
keyword:
	"program" |
	"entry" |
	"function" |
	"block" |
	"subroutine" |
	"end" |
    "dimension" |
    "equivalence" |
    "common" |
    "real"
    "complex" |
    "double" |
    "precision" |
    "integer" |
    "logical" |
    "pointer" |
    "implicit" |
    "none" |
    "character" |
    "parameter" |
    "external" |
    "intrinsic" |
    "save" |
    "data" |
    "assign" |
//    "to" |
    "goto" |
    "go" |
    "if" |
    "then" |
    "elseif" |
    "else" |
    "endif" |
    "do" |
    "enddo" |
    "continue" |
    "stop" |
    "pause" |
    "write" |
    "read" |
    "print" |
    "open" |
    "fmt" |
    "unit" |
//    "rec" |
    "err" |
    "iostat" |
    "file" |
    "status" |
    "access" |
    "position" |
    "form" |
    "recl" |
    "blank" |
    "exist" |
    "opened" |
    "number" |
    "named" |
    "name" |
    "sequential" |
//    "direct" |
    "formatted" |
    "unformatted" |
    "nextrec" |
    "close" |
    "inquire" |
    "backspace" |
    "endfile" |
    "rewind" |
    "format" |
    "let" |
    "call" |
    "return"
	;

/*#****************************************************************************
 * The Fortran Lexer
 *****************************************************************************/

class Fortran77Lexer extends Lexer;
options {
    exportVocab=Fortran77; // call the vocabulary "Fortran77"
    testLiterals=false;    // don't automatically test for literals
    k=4;                   // character lookahead
    codeGenMakeSwitchThreshold=6; // necessary high, else lexer generated is bad
    codeGenBitsetTestThreshold=6;
    caseSensitive=false;
	caseSensitiveLiterals=false;
}

// Need 4 lookahead for logical operators (eg .NE. and .NEQV.)
DOLLAR       : '$'  ;
COMMA        : ','  ;
LPAREN       : '('  ;
RPAREN       : ')'  ;
COLON        : ':'  ;
//CONCAT     : "//" ; // define in parser. Not all // are concat ops.
ASSIGN       : '='  ;
MINUS        : '-'  ;
PLUS         : '+'  ;
DIV          : '/'  ;
STAR         : {getColumn() != 1}? '*'  ; // not a comment
POWER        : {getColumn() != 1}? "**" ; // not a comment
LNOT         : ".not."   ;
LAND         : ".and."   ;
LOR          : ".or."    ;
EQV          : ".eqv."   ;
NEQV         : ".neqv."  ;
XOR          : ".xor."   ;
EOR          : ".eor."   ;
LT           : ".lt."    ;
LE           : ".le."    ;
GT           : ".gt."    ;
GE           : ".ge."    ;
NE           : ".ne."    ;
EQ           : ".eq."    ;
TRUE         : ".true."  ;
FALSE        : ".false." ;

protected CONTINUATION : ~('0' | ' ') ;
EOS:
	( ('\n' | '\r' (options {greedy=true;}:'\n')?) { newline(); } )+
	(("     " CONTINUATION)=>
		"     " CONTINUATION { $setType(Token.SKIP); } | )  // skip if cont'd
                                                            // End Of Statement
	;

// Fortran 77 doesn't allow for empty lines. Therefore EOS (newline) is NOT
// part of ignored white spaces. It is only ignored for line continuations.
WS : WHITE { $setType(Token.SKIP); } // White spaces or empty lines
	;

// Fortran 77 comments must start with the character on the first column
// we keep the comments inside the AST. See parser rules "wholeStatement".
// We however trim empty comment lines.
COMMENT :
	{getColumn() == 1}?
	('c' | '*')
	(options {generateAmbigWarnings=false;} :
		('%' '&' (NOTNL)* | ) // special or empty comment line
		{$setType(Token.SKIP);} 
		|
		{LA(1) != '%' || LA(2) != '&'}?
		(NOTNL)+
	)
	(('\n' | '\r' (options {greedy=true;}:'\n')?) { newline(); })+
	;

// '' is used to drop the charater when forming the lexical token
// Strings are assumed to start with a single quote (') and two
// single quotes is meant as a literal single quote
SCON :
	'\''
	( '\'' '\'' | ~('\''|'\n'|'\r') |
		( ('\n' | '\r' ('\n')?) "     " CONTINUATION)=>
			('\n' | '\r' ('\n')?) "     " CONTINUATION
	)*
	
	'\''
	{
		String str = $getText;
		str = str.substring(1, str.length()-1);
		str = str.replaceAll("''", "'");
		str = str.replaceAll("(\n|\r|\r\n)     [^0 ]", "");
		$setText(str);
	}
	;
	
// numeral literal
ICON {int counter=0;} :
	// plain integer
	counter=INTVAL
	
	(
	// code label
		{getColumn()<=6}? { $setType(LABEL); }
		|
	// hollerith
		'h' ({counter>0}? NOTNL {counter--;})* {counter==0}?
		{
			$setType(HOLLERITH);
			String str = $getText;
			str = str.replaceFirst("([0-9])+h", "");
			$setText(str);
		}
		|
	// real
		 // avoid tokenizing the . from an operator (eg. "1.eq.2")
	 	('.' ( NUM | EXPON | ~('n'|'e'|'a'|'o'|'x'|'l'|'g'|'t'|'f'|'0'..'9')))=>
		'.' (NUM)* (EXPON)?   // 123.456 or 123.
		{ $setType(RCON); }
		|
	// X format descriptor
		'x'
		{ $setType(XCON); }
		|
	// P format descriptor
		'p'
		{ $setType(PCON); }
	)?
	;	

// real
RCON:
	'.' (NUM)* (EXPON)? ;     // .12345

// hexadecimal
ZCON:
	'z' '\'' (HEX)+	'\''
	{
		String str = $getText;
		str = str.substring(2,str.length() - 1);
		$setText(str);
	}
	;


// identifier (keyword or variable)
NAME options {testLiterals=true;} :
	(('i'|'f'|'d'|'g'|'e') (NUM)+ '.') => FDESC
	{ $setType(FCON); } // format descriptor
	
	| ALPHA (ALNUM)*    // regular identifier
	;

protected WHITE: (' ' | '\t') ;
protected ALPHA: ('a'..'z') ; // case-insensitive
protected NUM  : ('0'..'9') ;
protected ALNUM: (ALPHA | NUM) ;
protected HEX  : (NUM | 'a'..'f') ;
protected SIGN : ('+' | '-') ;
protected NOTNL: ~('\n'|'\r') ;
protected INTVAL returns [int val=0]: (NUM)+ {val=Integer.parseInt($getText);} ;
protected FDESC: ('i'|'f'|'d') (NUM)+ '.' (NUM)+ |
	('e'|'g') (NUM)+ '.' (NUM)+  ('e' (NUM)+)? ;
protected EXPON: ('e' | 'd') (SIGN)? (NUM)+ 
	{
		String str = $getText;
		str = str.replaceAll("^[dD]", "0e");
		str = str.replaceAll("[dD]", "e");
		$setText(str);
	}
	;
