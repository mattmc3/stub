# $Id: CmdArgProcessor.boo 59 2007-04-17 02:18:35Z Matt $

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

import System
import System.Text
import System.IO
import System.Reflection

class CmdArgProcessor:
	[property(TemplateFile)]
	_templateFile as string

	[property(OutputFile)]
	_outputFile as string

	[property(ScriptRequested)]
	_scriptRequested as bool

	[property(ClassName)]
	_className as string

	[property(HelpRequested)]
	_helpRequested as bool
	
	[property(VersionRequested)]
	_versionRequested as bool

	_args as List

	def constructor():
		Initialize()

	def Process(args as (string)):
		params = List(args)
		self.TemplateFile     = cast(CmdArg, _args[0]).GetValue(params)
		self.OutputFile       = cast(CmdArg, _args[1]).GetValue(params)
		self.ScriptRequested  = cast(CmdArg, _args[2]).GetValue(params)
		self.ClassName        = cast(CmdArg, _args[3]).GetValue(params)
		self.HelpRequested    = cast(CmdArg, _args[4]).GetValue(params) or cast(CmdArg, _args[5]).GetValue(params)
		self.VersionRequested = cast(CmdArg, _args[6]).GetValue(params)
		if (params.Count != 0):
			msg = "Unrecognized options:{0}{1}" % (System.Environment.NewLine, join(params, System.Environment.NewLine))
			raise Exception(msg)

	def Usage() as string:
		buf = StringBuilder()
		buf.AppendLine(VersionHeader())
		buf.AppendLine()
		buf.AppendLine("usage:")
		buf.AppendLine('stub.exe -t "C:\\template.stub"')
		buf.AppendLine('stub.exe -t "C:\\template.stub" -o "C:\\results.txt"')
		buf.AppendLine('stub.exe -t "C:\\template.stub" --script -o "C:\\script.boo"')
		buf.AppendLine()
		buf.AppendLine("Options:")
		for arg in _args:
			buf.AppendLine(arg.ToString())
		return buf.ToString()

	def VersionHeader() as string:
		asm as Assembly = Assembly.GetExecutingAssembly()
		version = asm.GetName().Version
		attrs as duck = asm.GetCustomAttributes(typeof(AssemblyProductAttribute), false)
		product = attrs[0].Product
		
		buf = StringBuilder()
		buf.AppendLine(product)
		buf.Append("version: ")
		buf.Append("${version.Major}.${version.Minor}")
		buf.Append(".${version.Build}.${version.Revision}")
		return buf.ToString()
		

	def ToString():
		buf = StringBuilder()
		buf.AppendFormat("TemplateFile: {0}{1}", self.TemplateFile, System.Environment.NewLine)
		buf.AppendFormat("OutputFile: {0}{1}", self.OutputFile, System.Environment.NewLine)
		buf.AppendFormat("ScriptRequested: {0}{1}", self.ScriptRequested, System.Environment.NewLine)
		buf.AppendFormat("ClassName: {0}{1}", self.ClassName, System.Environment.NewLine)
		buf.AppendFormat("HelpRequested: {0}{1}", self.HelpRequested, System.Environment.NewLine)
		buf.AppendFormat("VersionRequested: {0}{1}", self.VersionRequested, System.Environment.NewLine)
		return buf.ToString()

	private def Initialize():
		_args = [
			CmdArg("--template",
				ShortFlagName: "-t",
				ValueName: "FILE",
				ValueQuantity: CmdArgValueQuantity.One,
				Description: "Specifies the stub template to process",
				ValueChecker: IsExistingFile as callable
			),
			CmdArg("--output",
				ShortFlagName: "-o",
				ValueName: "FILE",
				ValueQuantity: CmdArgValueQuantity.One,
				Description: "Specifies an output file instead of printing results to standard output",
				ValueChecker: IsValidPath as callable
			),
			CmdArg("--script",
				ValueQuantity: CmdArgValueQuantity.Zero,
				Description: "Output the generator script instead of running the template"
			),
			CmdArg("--class",
				ValueQuantity: CmdArgValueQuantity.One,
				ValueName: "NAME",
				Description: "The name of the generated class in the script.  Not very useful without --script option"
			),
			CmdArg("--help",
				ShortFlagName: "-?",
				ValueQuantity: CmdArgValueQuantity.Zero,
				Description: "Display help information for stub.exe"
			),
			CmdArg("--usage",
				ValueQuantity: CmdArgValueQuantity.Zero,
				Description: "Same as --help"
			),
			CmdArg("--version",
				ValueQuantity: CmdArgValueQuantity.Zero,
				Description: "Display version information for stub.exe"
			),
		]

	private def IsExistingFile(file as string):
		if not File.Exists(file):
			msg = String.Format("The file you specified does not exist! : {0}", file)
			raise Exception(msg)
	
	private def IsValidPath(path as string):
		msg = String.Format("The path you specified is invalid! : {0}", path)
		if path == null or path.Trim().Length == 0:
			raise Exception(msg)
		try:
			Path.GetFullPath(path)
		except:
			raise Exception(msg)
