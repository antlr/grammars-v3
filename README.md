# grammars-v3

A collection of [Antlr3](http://www.antlr3.org/) grammars, from [http://www.antlr3.org/grammar/list.html](http://www.antlr3.org/grammar/list.html)

Expectation that the grammars are free of actions but it's not a hard and fast rule. There is no common license!

Beware of the licenses on the individual grammars. **THERE IS NO COMMON
LICENSE!** When in doubt or you don't know what you're doing, please use
the BSD or MIT license.

Testing the Grammars
------------

The directory /support/antlr3test-maven-plugin contains a maven plugin which compiles the grammars and then runs them against examples in the /examples subdirectory to verify that the grammars compile and produce a clean parse for each example.

To use the plugin, you will have to compile and install it.

<pre>
cd support/
mvn clean package install
</pre>

You can then test all grammars:

<pre>
mvn clean test
</pre>

Travis Status
---------

<a href="https://travis-ci.org/teverett/grammars-v3"><img src="https://api.travis-ci.org/teverett/grammars-v3.png"></a>


