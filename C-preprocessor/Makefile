#ANTLR_HOME=../../antlr-3.0b5
#CP=".;$(ANTLR_HOME)/lib/antlr-2.7.6.jar;$(ANTLR_HOME)/lib/antlr-3.0b5.jar;$(ANTLR_HOME)/lib/stringtemplate-2.3b9.jar"
ANTLR_TOOL=org.antlr.Tool
all: generate build
generate:
	java   $(ANTLR_TOOL) Cpp.g
	java   $(ANTLR_TOOL) CppTree.g
#	java   $(ANTLR_TOOL) Macro.g
#	java   $(ANTLR_TOOL) MacroTree.g
build:
	javac  *.java
run:
	java  Main b.c
clean:
	rm -f *.tokens
	rm -f *.class
	rm -f Cpp*.java
	rm -f *~
	rm -f *.lexer.g
