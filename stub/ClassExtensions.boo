﻿# $Id: ClassExtensions.boo 59 2007-04-17 02:18:35Z Matt $

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

[Extension] # Add this method to the System.String class
def WordWrap(str as string, maxLen as int) as (string):
"""Take a string and split it into an array of shorter strings that don't exceed the value of 'maxLen'"""
	if (str == null or str == String.Empty):
		return array(string, 0)

	result = []
	startIndex = 0
	while (startIndex + maxLen < str.Length):
		workingPortion as string = str.Substring(startIndex, maxLen)
		splitPos as int = workingPortion.LastIndexOf(" ") + 1
		splitLen as int = (splitPos < 0 and maxLen or splitPos)
		result.Add(str.Substring(startIndex, splitLen))
		startIndex += splitLen
	result.Add(str.Substring(startIndex)) # add the rest of the string
	return result.ToArray(typeof(System.String))
