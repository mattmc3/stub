Stub - "String Templating Using Boo"
========================================

The name Stub stands for "String Templating Using Boo".  Stub is a templating engine (aka: code/text generator) for .NET written entirely in Boo (http://boo.codehaus.org/).  It borrows its syntax from Ruby's ERB utility (http://www.ruby-doc.org/stdlib/libdoc/erb/rdoc/) bringing a powerful yet simple templating system to .NET.

Like its predecessors, Stub uses special markup (aka: tags) to inject string generation code within a text file.  While templating enginges are often used to generate HTML, Stub is useful for any text generation task; from creating form letters, to generating SQL queries, and yes, (X)HTML - Stub does it all.  And it's built entirely with Boo!


Why Stub?
========================================

Aren't there other similar templating engines?  Why use Stub?

Stub has some advantages over existing .NET templating engines like CodeSmith, NVelocity, and BooTE.  While the other engines have some of these features, I was unable to find any other engine that had everything I wanted.  Here are some advantages of Stub in no particular order:

* Stub is written entirely in Boo and licensed under an open-source license (BSD)
* Stub is being actively developed
* Stub doesn't use its own mini-language for its embedded code.  You have full access to all the power and flexibility of Boo, all the standard .NET libraries.
* Other engines that claim to be ERB-like, support only the minimal ERB syntax.  Stub supports all the ERB syntax mechanisms including <%-, -%>, and one-liners.
* Stub can generate the template in memory, or it can export a working Boo script containing a class that can be saved off and ran externally using booi.  The resulting Boo script is exactly the same script that runs in memory so it's great for debugging too!
* Stub uses Boo's whitespace agnostic (WSA) syntax so you don't need to jump through any hoops to figure out indentation in your template file.  Just begin your blocks with a colon (:) as usual, and end them with the keyword "end".  Other than that, embedded Boo behaves just like you'd expect.
* Stub allows you to call the special functions Emit() or EmitLine() instead of switching context to produce literals.  This is similar to classic ASP's Response.Write method.


Syntax
========================================

Stub files are merely text files with Boo code interspersed.  The supported syntax is defined below:

<%@ control statement %>
	-=- A control statement provides header info for your template.  The most common usage of control statements is to import .NET libraries like so: <%@ import System.Data %>

<% code block %>
	-=- A code block allows you to run Boo code.  A code block begins with <% and ends with %> or -%> and can span multiple lines.

<%- Opens a code block and trims leading whitespace
	-=- If a code block begins with <%-, any leading whitespace on the line is removed from the output.  If something other than whitespace precedes the <%- on the line, then no trim is performed.  Thus, the use of this tag is safe for anytime use.

-%> Closes a code block and trims trailing whitespace and newline
	-=- If a code block, expression, or comment ends with -%>, then any trailing whitespace and newline are removed from the output.  If something other than whitespace follows the -%> on the line, then no trim is performed.  Thus, the use of this tag is safe for anytime use.

<%= expression %>
	-=- An expression block begins with <%= and ends with %> or -%>.  The contents of an expression are evaluated and emitted into the resulting text.

<%# comment %>
	-=- A comment block is not evaluated and is removed from the resulting text.  A comment block begins with <%# and ends with %> or -%> and can span multiple lines.  This is useful when testing.

% A line of code
	-=- A line beginning with a percent sign (%) is short-hand indicating a single line of Boo code.  It has the same effect as beginning a line with <%- and ending it with -%>.  No white space or any other character is allowed before the %.

%% An escaped percent sign
	-=- A double percent sign (%%) on the first position on a line is an escaped %.  The double percents are replaced with a single percent sign and the line is considered text output rather than code.

<%% escaped tags %%>
	-=- If you need to use tags in your literal text output, you will need to escape those tags.  <%% becomes <% and %%> becomes %>.

Emit() and EmitLine()
	-=- Boo can appear inside any code block and can be used to generate output.  The special methods self.Emit('joe') and self.EmitLine('schmo') will add a string value to the output.  This is similar to ASP's Response.Write() method.  Note that the 'self.' prefix is optional.


Example template
========================================

Templates can be stand alone files.  By convention, they should end in .stub, but that's obviously not a requirement.

Place this text in a file called C:\test.stub
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
<%# Display "Hello, World!" 3 times -%>
% who = 'World' # assign variable who
<%- for i in range(0, 3): -%>
Hello, <%= who %>!
<%-
	end  # whitespace agnostic Boo requires an explicit 'end'
-%>
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

More examples can be found in the Examples folder.


Example stub.exe call
========================================
Run this command> stub.exe C:\test.stub
output:
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
Hello, World!
Hello, World!
Hello, World!
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Example API call
========================================
import Stub
template = """
<%-
	EmitLine(WhenIsIt.ToLongTimeString())
	for i in range(0, 3):
-%>
Hello, <%= WhoIsIt %>!
<%-
	end  # whitespace agnostic Boo requires an explicit 'end'
-%>
"""
engine = BooTemplateEngine(template)
context = { "WhoIsIt" : "Me", "WhenIsIt" : DateTime.Now }
script = engine.BuildScript(context)
print script
output = engine.Run(context)
print output


Revision History
========================================
0.7.1
-------------------------------------
* Fixed issue where ${} was interpolated in boo templates
* Fixed issue where defs could not be overloaded
* Fixed issue where methods had to be declared before they were called.  Now they
  can be decalred anywhere.
* Began using personal subversion repository so each source file now has $Id data
* Compiled against new boo release 0.7.7.2475
* Added new unit tests
* Improvements to CLI stub.exe
* Minor code cleanup

0.7 Beta
-------------------------------------
* Initial release


To Do's
========================================
See source code


Technical notes
========================================
At a high level, this object was designed to allow a programmer to "stub" out a
Boo text template (similar to Ruby's ERB), and either execute the code in memory
or return a working Boo class for later execution.

The engine works by generating a Boo class behind the scenes.  This Boo class
is instantiated in memory and it's Run() method is called - (not to be conused
with the engine's Run() method).  Run() can optionally take an IDictionary
object containing any pre-defined variables as name => value pairs (ie:
string => object pairs).  The generated Boo class (viewable by calling the
BuildScript() method) will have public properties corresponding to the keys
in the IDictionary.

Boo is quite spiffy with its Duck typing, so we don't have to care about what
type of objects you want to use (if any) to provide context for the template.
Just fill an object that implements IDictionary and send it to the engine's
Run(context) method.


WARNING(S)
========================================
I am committed to returning from BuildScript() the same exact Boo code that gets
executed in memory when you call Run().  What this means for you is that you
can predict the exact behavior of a template by looking at the generated boo code
and running it in booi if you have a problem.  The boo generated with the --script
option is exactly what runs in memory.

However, the downside is that this openness also exposes a major implementation
detail of the engine to the outside world.  I can think of no reason why I
wouldn't always return a class with a name of your choice containing Run() and
Run(context as IDictionary) public methods.  That seems pretty generic and
workable well into the future.  However, I felt it wise to be forthcoming with
this disclaimer.  DO NOT RELY TOO HEAVILY ON THE IMPLEMENTATION OF THE BOO CLASS
RETURNED BY BuildScript() OR YOU MAY EXPERIENCE FRUSTRATION, PAIN, AND PERHAPS
SUFFERING.  You have been warned.

PS - The software is open source so nothing I do will make you stuck :-)


License
========================================

Simply BSD.  Open Source freedom like it was meant to be.  "Do as you will - be
nice if you are."  See LICENSE.TXT for exact verbage.
