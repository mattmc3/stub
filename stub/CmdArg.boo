# $Id: CmdArg.boo 59 2007-04-17 02:18:35Z Matt $

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
import System.Collections
import System.Text

enum CmdArgValueQuantity:
	Zero
	One
	#Many # TODO: I don't currently need the 'Many' quantity, so I'll implement it later

class CmdArg:
"""Defines a command line argument"""
	[property(Description)]
	_description as string

	[property(FlagName)]
	_flagName as string

	[property(ShortFlagName)]
	_shortFlagName as string

	[property(ValueName)]
	_valueName as string

	[property(ValueQuantity)]
	_valueQuantity as CmdArgValueQuantity

	[property(ValueChecker)]
	_valueChecker as callable

	def constructor(flagName as string):
		_description = String.Empty
		_flagName = flagName
		_shortFlagName = String.Empty
		_valueName = String.Empty
		_valueQuantity = CmdArgValueQuantity.Zero
		_valueChecker = DummyCheckValue

	def GetValue(ref params as List) as object:
	"""Takes a full parameter list, locates the argument specified by this object,
	removes the parameter, and returns the specified value."""
		unrecognizedParams = []
		
		theValue as object = null
		
		i = -1
		while ++i < params.Count:
			# if we find the parameter
			param = cast(string, params[i])
			if IsKnown(param):
				# if we've already set the value of this parameter
				if theValue != null:
					msg = String.Format("The parameter was found more than once. : {0}", param)
					raise Exception(msg)
				# if this parameter has no associated value
				elif self.ValueQuantity == CmdArgValueQuantity.Zero:
					theValue = true
				# if this parameter has the value embedded with an equal sign
				elif IsEqualsParam(param):
					parts = param.Split(('=',), StringSplitOptions.None)
					theValue = parts[1]
					ValueChecker(theValue)
				# if this parameter expects a value, but we're at the end of the param list
				elif i == params.Count-1:
					msg = String.Format("The parameter expects a value: {0}", param)
					raise Exception(msg)
				# otherwise, set the value and verify it
				else:
					i++
					theValue = cast(string, params[i])
					ValueChecker(theValue)
			else:
				unrecognizedParams.Add(param)

		# an argument that takes no values is a boolean, and we don't return
		# nulls for bools - we use false
		if self.ValueQuantity == CmdArgValueQuantity.Zero and theValue == null:
			theValue = false

		# reset the params to exclude that param we found
		params = unrecognizedParams
		return theValue

	def ToString():
		flag = StringBuilder()
		buf = StringBuilder()

		# handle the display of the flag
		if self.ShortFlagName != String.Empty:
			flag.AppendFormat("{0}, ", self.ShortFlagName)
		flag.Append(self.FlagName)
		if self.ValueName != String.Empty:
			flag.AppendFormat("={0}", self.ValueName)

		flagCharsPerLine = 16
		padding = String.Empty.PadLeft(flagCharsPerLine)
		if (flag.ToString().Length > flagCharsPerLine):
			buf.AppendLine(flag.ToString())
			buf.Append(padding)
		else:
			buf.AppendFormat("{0,-16}", flag.ToString())
		buf.Append(": ")
		
		# handle the display of the description
		dscrCharsPerLine = 61
		wrapedDscr as (string) = self.Description.WordWrap(dscrCharsPerLine)
		tweener = "{0}{1}  " % (System.Environment.NewLine, padding)
		buf.Append(join(wrapedDscr, tweener))

		return buf.ToString()

	private def IsKnown(param as string) as bool:
		return param == self.FlagName or param == self.ShortFlagName or IsEqualsParam(param)

	private def IsEqualsParam(param as string) as bool:
		return param.StartsWith(self.FlagName + '=') or param.StartsWith(self.ShortFlagName + '=')

	private def DummyCheckValue(val as string):
		pass
