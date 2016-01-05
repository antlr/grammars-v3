//
// Oracle JDBC URL (with integrated TNSNAMES.ORA) parser
//
// Author: Nathaniel Harward
//
// A simple parser for Oracle JDBC URLs, also includes a simple parser
// for a TNSNAMES.ORA stream.
//
// I am not an Oracle expert and did not consult the Oracle documentation
// for the format of the TNSNAMES.ORA file -- so in some cases it may need
// to be extended.  But for the examples I encountered it worked without
// any problems.  Use/extend as you see fit.
//


//
// JDBC URL (with integrated TNSNAMES.ORA) parser
//

class OracleJdbcUrlParser extends Parser;

options {
    k = 2;
    buildAST = true;
}

tokens {
	JDBC_DRIVER_TYPE;
	JDBC_DB_DEFINITION;
	KEY_VALUE_LIST;
	KEY;
	VALUE;
	TNSNAMES_ENTRY;
	TNSENTRY_SID;
}

//
// TNSNAMES.ORA productions, they define the oracle_sid and key_value_list productions
// that are [potentially] used in an Oracle JDBC URL
//

tnsnames_stream: (tnsnames_entry)*;

tnsnames_entry: tnsentry_sid EQUALS_SIGN key_value_list
		{ #tnsnames_entry = #([TNSNAMES_ENTRY, "tnsnames_entry"], #tnsnames_entry); }
	;

tnsentry_sid: oracle_sid
		{ #tnsentry_sid = #([TNSENTRY_SID, "tnsentry_sid"], #tnsentry_sid); }
	;

key_value_list:
	OPEN_PAREN key EQUALS_SIGN ( ( key_value_list )+ | value ) CLOSE_PAREN
		{
			#key_value_list = #([KEY_VALUE_LIST, "key_value_list"], #key_value_list);
		}
	;

key:
	( ~( OPEN_PAREN | CLOSE_PAREN | EQUALS_SIGN ) )+
		{ #key = #([KEY, "key"], #key); }
	;

value:
	( ~( OPEN_PAREN | CLOSE_PAREN | EQUALS_SIGN ) )+
		{ #value = #([VALUE, "value"], #value); }
	;

oracle_sid: WORD ( WORD | NUMBER | UNDERSCORE )*
	;

hostname: ( NUMBER | WORD ) ( NUMBER | WORD | HYPHEN | UNDERSCORE )* ( DOT ( ( NUMBER | WORD ) ( NUMBER | WORD | HYPHEN | UNDERSCORE )* ) )*
	;

//
// Oracle JDBC URL productions
//

oracle_jdbc_url: jdbc_literal_string COLON oracle_literal_string COLON ( oracle_oci_sub_url | oracle_thin_sub_url )
	;

oracle_oci_sub_url:
		oracle_oci_driver (COLON username_and_password)? COLON AT_SIGN oracle_oci_database_definition
	;

oracle_thin_sub_url:
		oracle_thin_driver (COLON username_and_password)? COLON AT_SIGN oracle_thin_database_definition
	;

username_and_password: ( ~( SLASH | AT_SIGN ) )+ SLASH ( ~COLON )*
	;

oracle_oci_driver: oci_literal_string
		{ #oracle_oci_driver = #([JDBC_DRIVER_TYPE, "driver_type"], #oracle_oci_driver); }
	;

oracle_thin_driver: thin_literal_string
		{ #oracle_thin_driver = #([JDBC_DRIVER_TYPE, "driver_type"], #oracle_thin_driver); }
	;

oracle_oci_database_definition: oracle_sid | key_value_list
		 { #oracle_oci_database_definition = #([JDBC_DB_DEFINITION, "database_definition"], #oracle_oci_database_definition); }
	;

oracle_thin_database_definition: ( hostname COLON port COLON oracle_sid ) | key_value_list
		 { #oracle_thin_database_definition = #([JDBC_DB_DEFINITION, "database_definition"], #oracle_thin_database_definition); }
	;

port: NUMBER
	;

jdbc_literal_string: "jdbc"
	;

oracle_literal_string: "oracle"
	;

oci_literal_string: "oci"
	;

thin_literal_string: "thin"
	;

//
// SQL*Net lexer
//

class OracleJdbcUrlLexer extends Lexer;

options {
    charVocabulary = '\3' .. '\177';
    k = 2;
}

EQUALS_SIGN : '=';

OPEN_PAREN : '(';

CLOSE_PAREN : ')';

COLON: ':';

DOLLAR_SIGN: '$';

POUND_SIGN: '#';

AT_SIGN: '@';

SLASH: '/';

HYPHEN: '-';

UNDERSCORE: '_';

DOT: '.';

protected
DIGIT: '0' .. '9';

protected
LETTER: 'a' .. 'z' | 'A' .. 'Z';

NUMBER:
	DIGIT ( DIGIT )+
	| DIGIT { $setType(DIGIT); }
	;

WORD:
	LETTER ( LETTER )+
	| LETTER { $setType(LETTER); }
	;

WS  :   (   ' '
        |   '\t'
        |   '\r' ( '\n' )? { newline(); }
        |   '\n' ( '\r' )? { newline(); }
        )
        { $setType(Token.SKIP); }
    ;
