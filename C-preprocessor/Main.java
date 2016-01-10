import java.io.*;
import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;

/** Parse a java file or directory of java files using the generated parser
 *  ANTLR builds from java.g
 */
class Main {

	//static CommonTokenStream tokens = new CommonTokenStream();
	//	static TokenRewriteStream tokens = new TokenRewriteStream();;

    public static void main(String[] args) {
		try {
			if (args.length > 0 ) {
				// for each directory/file specified on the command line
				for(int i=0; i< args.length;i++) {
					doFile(new File(args[i])); // parse it
				}
			}
			else {
				System.err.println("Usage: java Main <directory or file name>");
			}
		}
		catch(Exception e) {
			System.err.println("exception: "+e);
			e.printStackTrace(System.err);   // so we can get stack trace
		}
	}

	// This method decides what action to take based on the type of
	//   file we are looking at
	public static void doFile(File f)
							  throws Exception {
		// If this is a directory, walk each file/dir in that directory
		if (f.isDirectory()) {
			String files[] = f.list();
			for(int i=0; i < files.length; i++)
				doFile(new File(f, files[i]));
		}

		// otherwise, if this is a java file, parse it!
		else if ( ((f.getName().length()>2) &&
				f.getName().substring(f.getName().length()-2).equals(".c"))
			||	f.getName().substring(f.getName().length()-2).equals(".h")
			|| f.getName().equals("input") )
		{
			// System.err.println("   "+f.getAbsolutePath());
			parseFile(f.getAbsolutePath());
		}
	}

	// Here's where we do the real work...
	public static void parseFile(String f) throws Exception 
	{
		try {
			// Create a scanner that reads from the input stream passed to us
			System.out.println("file :"+f);
			CppLexer lexer = new CppLexer(new ANTLRFileStream(f,"iso8859-1"));
			//tokens.setTokenSource(lexer);
			TokenRewriteStream tokens = new TokenRewriteStream(lexer);
			tokens.LT(1);	
			//System.out.println("tokens : " + tokens);
/*
			System.out.println("size: "+tokens.size());
			for(int i=0; i<tokens.size()-1;i++)
			{
           		Token t = tokens.get(i);
            	System.out.println("Token: "+t);
			}
*/
			//tokens.discardOffChannelTokens(true);
			/*
			long t1 = System.currentTimeMillis();
			tokens.LT(1);
			long t2 = System.currentTimeMillis();
			System.out.println("lexing time: "+(t2-t1)+"ms");
			*/
			System.out.println("--------------------------------------------");
			// Create a parser that reads from the scanner
			CppParser parser = new CppParser(tokens);
			//parser.preprocess();
			// start parsing at the compilationUnit rule
			CppParser.preprocess_return ret = parser.preprocess();
 //       System.out.println("tree: "+((Tree)ret.tree).toStringTree());
			CommonTree root_0 = (CommonTree)ret.tree;
			//printTree(root_0,0);
	        CommonTreeNodeStream nodes = new CommonTreeNodeStream((Tree)ret.tree);
			CppTreeTreeParser walker = new CppTreeTreeParser(nodes,f);
        	walker.preprocess();
			System.out.println("finished parsing OK");
		}
		catch (Exception e) {
			System.err.println("parser exception: "+e);
			e.printStackTrace();   // so we can get stack trace		
		}
	}
	public static void printTree(CommonTree t, int indent) 
	{
    	if ( t != null ) 
		{
      		StringBuffer sb = new StringBuffer(indent);
      		for ( int i = 0; i < indent; i++ )
        		sb = sb.append("   ");

      		for ( int i = 0; i < t.getChildCount(); i++ ) 
			{ 
    			System.out.println(sb.toString() + t.getChild(i).toString());
    			printTree((CommonTree)t.getChild(i), indent+1);
      		}
    	}
  	}

/**

{
	import java.io.*;
	import java.util.*;
	import antlr.*;

	class cpp implements cppLexerTokenTypes 
	{
		public static TokenStreamSelector selector = new TokenStreamSelector();
		public static void main(String[] args) 
		{
			try 
			{
           		// will need a stack of lexers for #include and macro calls
				cppLexer mainLexer = new cppLexer(new DataInputStream(System.in));
				mainLexer.selector = selector;
				selector.select(mainLexer);
				for (;;) 
				{
					Token t = selector.nextToken();
					if (t.getType()==Token.EOF_TYPE) break;
					System.out.print(t.getText());
				}
			} 
			catch(Exception e) 
			{
				System.err.println("exception: "+e);
        	}
    	}
	}
}
**/

	
}

