# $Id: Program.boo 59 2007-04-17 02:18:35Z Matt $

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
import System.IO

[STAThread]
def Main(argv as (string)):
	processor = CmdArgProcessor()
	
	if argv.Length < 1:
		print processor.Usage()
		return

	try:
		processor.Process(argv)
	except ex as Exception:
		DisplayError(ex.Message)
		return

	# check meta-options
	if processor.HelpRequested:
		print processor.Usage()
		return
	elif processor.VersionRequested:
		print processor.VersionHeader()
		return
	# check for required options
	elif processor.TemplateFile == null:
		DisplayError("ERROR: A template file must be provided")
		return

	try:
		DoIt(processor)		
	except ex as Exception:
		DisplayError(ex.Message)
		return

def DisplayError(msg as string):
	print msg
	print ''
	print 'run "stub.exe --help" for help'
	return

def DoIt(options as CmdArgProcessor):
	rdr = StreamReader(options.TemplateFile)
	template = rdr.ReadToEnd()
	rdr.Close()

	engine = BooTemplateEngine(template)
	if options.ClassName != null:
		engine.ScriptClassName = options.ClassName

	result as string
	if options.ScriptRequested:
		result = engine.BuildScript()
	else:
		result = engine.Run()
	
	if options.OutputFile != null:
		wtr = StreamWriter(options.OutputFile, false)
		wtr.Write(result)
		wtr.Flush()
		wtr.Close()
	else:
		print result
