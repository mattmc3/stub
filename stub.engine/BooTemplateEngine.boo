# $Id: BooTemplateEngine.boo 60 2007-05-14 02:52:16Z Matt $

#region License
/*
Matt McElheny <mattmc3 at gmail dot com>
Copyright (c) 2007
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list 
  of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice, this list
  of conditions and the following disclaimer in the documentation and/or other materials 
  provided with the distribution.

- Neither the name of this software nor the names of its contributors may be used to 
  endorse or promote products derived from this software without specific prior written 
  permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS &AS IS& AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#endregion License

namespace Stub

#region TODO list
# TODO: Allow imports of user dlls (custom classes / non-GAC)
# TODO: Boo script output will be poorly indented.  Consider cleaning that up.
# TODO: Currently methods do not support doc comments
# TODO: Consider allowing classes to be defined in templates
# TODO: Consider putting template comments in resulting Boo script
# TODO: Consider supporting other scripting languages.  Note: it seems much harder to handle "context" without the duck typing I get from Boo.
# TODO: Improve error reporting, because right now there isn't much and it's not super useful
# TODO: Consider adding template validation?
# TODO: add <%@ %> class properties
# TODO: Add option for letting <% and %> be treated like <%- and -%>
# TODO: Export license to LICENSE.TXT and insert it into code blocks with NAnt
#endregion TODO list

#region Imports
import System
import System.Collections
import System.Text
import System.Text.RegularExpressions

import Boo.Lang.Parser
import Boo.Lang.Compiler
import Boo.Lang.Compiler.IO
import Boo.Lang.Compiler.Pipelines;
#endregion Imports

class BooTemplateEngine(ITemplateEngine):
"""Parses a template file used for text generation."""
	#region Constants
	
	#region Regex patterns

	# We're going to standardize on \n as a newline internally so no matter what
	# platform we're on, there's no effort involved in determining the end of a
	# line.  This pattern is an 'or' list of newlines that aren't '\n'
	private static final PAT_NEWLINES = """ \r\n | \r """
	
	# A left trim tag ( <%- ) will trim any indention whitespace if whitespace
	# is the only thing preceeding it on a line.  This tag doesn't have to trim
	# leading whitepsace however, and is perfectly valid for use as an opening
	# tag anytime.  So, this pattern must match all opening trim tags regardless
	# of leading whitespace.
	private static final PAT_LTRIM_OPEN_TAG = """ (?: ^ [\t\ ]* )? <%- """
	
	# A right trim tag ( -%> ) will trim any trailing whitespace and new line if
	# said whitespace is the only thing following it on a line.  This tag
	# doesn't have to trim trailing whitepsace however, and is perfectly valid
	# for use as a closing tag anytime (even on comments <%#, expressions <%=,
	# and control blocks <%@). So, this pattern must match all closing trim tags
	# regardless of trailing whitespace.
	private static final PAT_RTRIM_CLOSE_TAG = """ -%> (?: [\t\ ]* (?: \n | \z) )?"""
	
	# A one-liner is a single line of code.  The line begins with a percent sign
	# (%) and runs all the way to the end of the line including the new line
	# character.  It is a shorthand version of "<% code -%>" and is borrowed from
	# Ruby's ERB syntax.  Any leading whitespace or characters on the line prior
	# to the % means that the % is part of a normal literal in the template.  If
	# you need a literal % at the begininng of a line, use %% instead.  This
	# pattern captures all valid one-liners.
	private static final PAT_ONE_LINER = """ ^ %(?! %|>) (.*?) (?: \n | \z) """
	
	# This pattern captures all escaped one-liners and is used to replace the
	# double percent signs with a single percent sign.
	private static final PAT_ESC_ONE_LINER = """ ^ %% """
	
	# This pattern matches template comment blocks so that they are not
	# processed by the engine
	private static final PAT_COMMENT = """ <%\# .*? (?<!%)%> """
	
	# Since I'd like to support methods in my templates, I need to match the Boo
	# syntax for defining a method.  I'm pretty strict about what a method
	# definition looks like.
	private static final PAT_METHOD_DEF = """
		###- method defined...
		def [\ \t]+             # def keyword followed by whitespace
		[A-Za-z_]+[0-9A-Za-z_]* # the name of the method
		[\ \t]*                 # optional whitespace
		\(.*?\)                 # literal parens with a non-greedy match of the innards
		                        # +   note: You could have an array as a param, so watch
		                        # +   the matching end paren
		(?:                     # non-capturing group for method's return type
		    [\ \t]+             # whitespace
		    as                  # keyword 'as'
		    [\ \t]+             # whitespace
		    [^:]+               # anything that's not a :
		)?                      # end optional group
		[\ \t]*                 # optional whitespace
		: [\ \t]* \n            # the colon that starts the def block
		###- now deal with trying to find the 'end' statement that goes with the
		###- method definition
		(?>
		        : [\ \t]* \n    # a colon that starts another block
		        (?<DEPTH>)      # + increase depth counter
		    |                   # or
		        ^ [\ \t]*       # beginning of a line followed by whitespace
		        end             # end keyword to end a block
		        [\ \t]* \n      # optional trailing whitespace and a newline
		        (?<-DEPTH>)     # + decrease depth counter
		    |                   # or
		        .?              # something else
		)*?                     # optionally, non-greedy
		(?(DEPTH)(?!))          # verify that we're at zero depth
		^ [\ \t]*               # beginning of a line followed by whitespace
		end                     # end keyword to end athe def block
		(?= \s)                 # lookahead for whitespace after the end keyword
	"""

	# After a template is normalized, only non-trim variations on <% and %> will
	# remain.  These blocks are called instructions for lack of a better term.
	# This pattern identifies any instructions so that they can be separated
	# from literals during final parsing.  Note that this pattern matches all
	# blocks that begin with <%, such as (<%#, <%@,<%=, and any future blocks)
	private static final PAT_INSTRUCTION = """ <%(?!%) (.*?) (?<!%)%> """

	#endregion Regex patterns

	#region Regex objects

	# Make Regex objects out of the patterns
	private static final RE_OPTS = RegexOptions.Compiled | RegexOptions.IgnorePatternWhitespace | RegexOptions.Multiline
	private static final RE_NEWLINES        = Regex(PAT_NEWLINES,        RE_OPTS)
	private static final RE_LTRIM_OPEN_TAG  = Regex(PAT_LTRIM_OPEN_TAG,  RE_OPTS)
	private static final RE_RTRIM_CLOSE_TAG = Regex(PAT_RTRIM_CLOSE_TAG, RE_OPTS)
	private static final RE_ONE_LINER       = Regex(PAT_ONE_LINER,       RE_OPTS)
	private static final RE_ESC_ONE_LINER   = Regex(PAT_ESC_ONE_LINER,   RE_OPTS)
	private static final RE_METHOD_DEF      = Regex(PAT_METHOD_DEF,      RE_OPTS | RegexOptions.Singleline)

	# Comments can span lines, so we need to treat as Singleline
	private static final RE_COMMENT = Regex(PAT_COMMENT, RE_OPTS | RegexOptions.Singleline)

	# Code blocks can span lines, so we need to treat as Singleline
	private static final RE_INSTRUCTION = Regex(PAT_INSTRUCTION, RE_OPTS | RegexOptions.Singleline)

	#endregion Regex objects

	#endregion Constants

	#region Fields / Properties
	
	_importStatements as List
	_methods as List
	_normalizedTemplate as string

	# A template adhering to the syntax rules defined in the README
	_template as string
	Template as string:
		get:
			return _template
		set:
			_template = value
			_normalizedTemplate = Normalize(self.Template)

	# Someone may desire to control the name of the private StringBuilder() in
	# the Boo script
	[property(OutputVariable)]
	_outVar as string
	
	# Someone may desire to control the name of the class returned from
	# BuildScript()
	[property(ScriptClassName)]
	_scriptClassName as string

	#endregion Fields / Properties

	#region Public methods

	def constructor(template as string):
	"""Public constructor that sets the template value"""
		self.Template = template
		self.OutputVariable = "_stubout"
		self.ScriptClassName = "MyTemplateClass"
		_importStatements = []
		_methods = []

	def Run() as string:
	"""Run the template and return the results"""
		return Run(Hash())

	def Run(context as IDictionary) as string:
	"""Run the template using external variables"""
		script = BuildScript(context)
		return RunBooScript(script, context)

	def BuildScript() as string:
	"""Wrap the template logic in Boo code with access to external variables"""
		return BuildScript(Hash())

	def BuildScript(context as IDictionary) as string:
	"""Wrap the template logic in Boo code"""
		workingTemplate = _normalizedTemplate
		output = StringBuilder()

		priorIndex = 0
		for match as Match in RE_INSTRUCTION.Matches(workingTemplate):
			# append previous string literal
			if priorIndex < match.Index:
				output.Append(BuildLiteral(workingTemplate.Substring(priorIndex, match.Index - priorIndex)))

			instruction = match.Groups[1].Value
			# expression
			if instruction.StartsWith('='):
				expression = instruction.Substring(1) # get everything after the =
				output.Append(BuildExpression(expression))
			# control statement
			elif instruction.StartsWith('@'):
				control = instruction.Substring(1) # get everything after the @
				_importStatements.Push(BuildControlStatement(control))
			# code block
			else:
				output.Append(BuildCode(instruction))

			priorIndex = match.Index + match.Length

		# add the final literal
		output.Append(BuildLiteral(workingTemplate.Substring(priorIndex)))

		# extract method definitions
		script = ExtractMethods(output.ToString())	

		# display output
		return GetBooClass(script, context)

	#endregion Public methods

	#region Private methods

	private def BuildExpression(instruction as string) as string:
	"""Build the syntax for an expression block"""
		expression = UnescapeTags(instruction)
		expression = expression.Trim()
		return String.Format('{0}.Append({1}){2}', _outVar, expression, System.Environment.NewLine)

	private def BuildCode(instruction as string) as string:
	"""Build the syntax for a code block"""
		code = UnescapeTags(instruction)
		return code.Trim() + System.Environment.NewLine

	private def BuildControlStatement(instruction as string) as string:
	"""Build the syntax for a control statement"""
		return instruction.Trim()

	private def BuildLiteral(literal as string) as string:
	"""Build the syntax for a literal string"""
		if literal == String.Empty:
			return String.Empty

		output = StringBuilder()
		lines = literal.Split(("\n",), System.StringSplitOptions.None)
		for i in range(lines.Length):
			line = lines[i].Codify()
			line = UnescapeTags(line)
			method = (i == lines.Length-1 and 'Append' or 'AppendLine')
			code = String.Format("{0}.{1}('{2}')", _outVar, method, line)
			output.AppendLine(code)

		return output.ToString()

	private def ExtractMethods(booScript as string) as string:
		# see if there are any method definitions.  If so, pull the whole method
		# out of the code and insert it as a method of the generated Boo class
		for methodDef as Match in RE_METHOD_DEF.Matches(booScript):
			_methods.Add(methodDef.Value)

		return RE_METHOD_DEF.Replace(booScript, String.Empty)

	private def UnescapeTags(str as string) as string:
	"""Replace escaped tags with their unescaped value"""
		str = str.Replace("<%%", "<%")
		str = str.Replace("%%>", "%>")
		return str

	private def Normalize(template as string) as string:
	"""Normalize the template to remove all syntax except literals, <%@ control statements %>, <% code blocks %>, and <%= expressions %>"""
		workingTemplate = template

		# Standardize on \n as newline character
		workingTemplate = RE_NEWLINES.Replace(workingTemplate, "\n")

		# Normalize all one-liners first so they don't get pulled up during trims
		workingTemplate = RE_ONE_LINER.Replace(workingTemplate, MatchEvaluator(NormalizeOneLiner))

		# Perform trims next
		workingTemplate = RE_LTRIM_OPEN_TAG.Replace(workingTemplate, "<%")
		workingTemplate = RE_RTRIM_CLOSE_TAG.Replace(workingTemplate, "%>")
		
		# Remove all comments after trims are done
		workingTemplate = RE_COMMENT.Replace(workingTemplate, String.Empty)

		# Now that there are no one-lines, there's no need for escaped one-liners
		workingTemplate = RE_ESC_ONE_LINER.Replace(workingTemplate, "%")

		return workingTemplate

	private def NormalizeOneLiner(m as Match) as string:
	"""Take one-liner and convert it to be a normal code block"""
		rtn = "<% {0} %>" % (m.Groups[1].ToString().Trim(),)
		return rtn

	private def GetBooClass(code as string, context as IDictionary) as string:
	"""Take the code that was generated and place it in a Boo class"""
		classSkeleton = """{0}
class {1}:
	private {3} as System.Text.StringBuilder

	#region Properties

	{2}

	#endregion Properties
	
	def Run() as string:
		return Run(Hash()) # run with empty hash
	end

	def Run(context as System.Collections.IDictionary) as string:
		Set{1}Properties(context)
		{3} = System.Text.StringBuilder()
		# # # # # # # # # #
		{4}
		# # # # # # # # # #
		return {3}.ToString()
	end

	#region Methods from stub

	{5}

	#endregion Methods from stub

	private def Emit(str as string):
		{3}.Append(str)
	end

	private def EmitLine(str as string):
		{3}.Append(str)
		{3}.Append(System.Environment.NewLine)
	end

	private def Set{1}Properties(context as System.Collections.IDictionary):
		for stubProperty as System.Collections.DictionaryEntry in context:
			instanceProp = self.GetType().GetProperty(stubProperty.Key)	
			instanceProp.SetValue(self, stubProperty.Value, null)
		end
	end
end

#t = {1}()
#print t.Run()
"""
		propertyGenerator = CreateBooPropertySnippet(key) for key in context.Keys
		properties = join(propertyGenerator, System.Environment.NewLine)
		importStmts = join(_importStatements, System.Environment.NewLine) + System.Environment.NewLine
		methods = join(_methods, System.Environment.NewLine) + System.Environment.NewLine

		thescript = classSkeleton % (importStmts, self.ScriptClassName, properties, self.OutputVariable, code, methods)
		return thescript

	private def CreateBooPropertySnippet(property as string) as string:
	"""Produces Boo syntax to create an object's property"""
		return "\t[property({0})]{1}\t_{0} as duck{1}{1}" % (property, System.Environment.NewLine)

	private def RunBooScript(script as string, context as IDictionary) as string:
	"""Accepts a Boo script containing a template class and returns the string from the class' Run() method"""
		# http://boo.codehaus.org/Scripting+with+the+Boo.Lang.Compiler+API
		booc = BooCompiler()
		booc.Parameters.Input.Add(StringInput("Input", script));
		booc.Parameters.Pipeline = CompileToMemory()
		booc.Parameters.Pipeline[0] = WSABooParsingStep()

		output = StringBuilder()
		compilerContext as CompilerContext = booc.Run()
		if compilerContext.GeneratedAssembly is null:
			for error as CompilerError in compilerContext.Errors:
				output.AppendLine(error.Message)
			raise TemplateSyntaxException(output.ToString())
		else:
			myClass = compilerContext.GeneratedAssembly.GetType(self.ScriptClassName, true, true)
			myInstance as duck = myClass()
			output.Append(myInstance.Run(context))

		return output.ToString()

	#endregion Private methods
