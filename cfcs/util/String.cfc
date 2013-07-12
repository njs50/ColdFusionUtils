<cfcomponent>

	<cffunction name="ReSubMatch" returntype="array" hint="returns sub group matches from a regexp">
	<!--- Returns the sub groups from a regexp match --->

		<cfargument name="regexp" type="string">
		<cfargument name="str" type="string">
		<cfargument name="bCaseSensitive" default="false">

		<cfset var aMatch = arrayNew(1)>
		<cfset var stMatch = "">
		<cfset var i = "0">

		<cfif arguments.bCaseSensitive>
			<cfset stMatch = REFind(arguments.regexp,arguments.str,1,true)>
		<cfelse>
			<cfset stMatch = REFindNoCase(arguments.regexp,arguments.str,1,true)>
		</cfif>

		<cfloop from="1" to="#arrayLen(stMatch.pos)#" index="i">
			<cfif stMatch.len[i]>
				<cfset arrayAppend(aMatch,mid(str,stMatch.pos[i],stMatch.len[i]))>
			<cfelse>
				<cfset arrayAppend(aMatch,'')>
			</cfif>
		</cfloop>

		<cfreturn aMatch>

	</cffunction>


	<cffunction name="ReSubMatchMultiple" returntype="array" hint="returns multiple sub group matches from a regexp">
	<!--- Returns the sub groups from a regexp match --->

		<cfargument name="regexp" type="string">
		<cfargument name="str" type="string">
		<cfargument name="bCaseSensitive" default="false">

		<cfset var aMatch = arrayNew(1)>
		<cfset var stMatch = "">
		<cfset var i = "0">
		<cfset var aMultiple = []>

		<cfset var bFound = true>
		<cfset var startPos = 1>
		<cfset var endPos = len(str)>

		<cfloop condition="bFound">

			<cfif arguments.bCaseSensitive>
				<cfset stMatch = REFind(arguments.regexp,arguments.str,startPos,true)>
			<cfelse>
				<cfset stMatch = REFindNoCase(arguments.regexp,arguments.str,startPos,true)>
			</cfif>

			<cfif stMatch.len[1] eq 0>
				<cfset bFound = false>
			</cfif>

			<cfif bFound>

				<cfset aMatch = []>
				<cfloop from="1" to="#arrayLen(stMatch.pos)#" index="i">
					<cfif stMatch.len[i]>
						<cfset arrayAppend(aMatch,mid(str,stMatch.pos[i],stMatch.len[i]))>
					<cfelse>
						<cfset arrayAppend(aMatch,'')>
					</cfif>
				</cfloop>

				<cfset startPos = stMatch.pos[1] + stMatch.len[1]>

				<cfif startPos gte endPos>
					<cfset bFound = false>
				</cfif>

				<cfset arrayAppend(aMultiple,{ 'aMatch'=aMatch, 'start'= stMatch.pos[1], 'length'= stMatch.len[1]} )>

			</cfif>

		</cfloop>

		<cfreturn aMultiple>

	</cffunction>


	<cffunction name="ReSubReplaceMultiple"  hint="returns string, runs a function to replace each matched section">

		<cfargument name="regexp" type="string">
		<cfargument name="str" type="string">
		<cfargument name="fnReplace">
		<cfargument name="bCaseSensitive" default="false">

		<cfset var aMatchMulti = ReSubMatchMultiple(arguments.regexp, arguments.str, arguments.bCaseSensitive)>
		<cfset var i = 0>
		<cfset var pos = '1'>
		<cfset var sRet = ''>

		<cfloop from="1" to="#arrayLen(aMatchMulti)#" index="i">
			<cfset sRet &= mid(arguments.str, pos, aMatchMulti[i].start - pos)>
			<cfset pos = aMatchMulti[i].start + aMatchMulti[i].length>
			<cfset sRet &= arguments.fnReplace(aMatchMulti[i].aMatch) >
		</cfloop>

		<cfset i = len(arguments.str) - pos + 1>
		<cfif i>
			<cfset sRet &= right(arguments.str, i)>
		</cfif>

		<cfreturn sRet>

	</cffunction>


	<cfscript>
		// parses an attribute string into an struct of attributes. overly complex because it needs to handle nasty html.
		// i,e <test novalue novalue2= value=unquoted value2="quoted" value3='quoted w. "embedded" qotes' etc... />
		public function attributeStringToStruct(strAttributes) {

			var stAttribs = structNew();
			var aBytes = trim(arguments.strAttributes).getBytes("UTF-8");
			var thisKey = '';
			var thisVal = '';
			var thisDelim = '';
			var state = 'key';
			var lastByte = '';
			var thisByte = '';

			// turns string into a byte array then loops over string one character at a time
			for (var idx = 1; idx <= arrayLen(aBytes); idx++) {

				thisByte = aBytes[idx];

				// figure out what this key is
				if (state == 'key') {

					switch(thisByte) {
						// space or tab
						case 32: {}
						case 9: {
							state = 'transition';
							break;
						}

						// equals
						case 61: {
							thisDelim = '';
							state = 'delim';
							break;
						}

						default : {
							thisKey = thisKey & chr(thisByte);
							break;
						}

					}


				// dump white space, if we find = then change state to checking for delim,
				// if we find something other than a space then we just found a key with no value and are now working on a new key
				} else if (state == 'transition') {

					switch(thisByte) {
						// space or tab
						case 32: {}
						case 9: {
							// do nothing
							break;
						}

						// equals
						case 61: {
							thisDelim = '';
							state = 'delim';
							break;
						}

						// previous key had no value, next key...
						default : {
							stAttribs[thisKey] = '';
							thisKey = chr(thisByte);
							state = 'key';
							break;
						}

					}


				// value (we are either discovering the delim, or processing the value)
				} else if (state == 'delim') {

					switch(thisByte) {
						// space or tab
						case 9: {}
						case 32: {
							// do nothing
							break;
						}

						// ' or "
						case 39: {}
						case 34: {
							thisDelim = thisByte;
							state = 'value';
							// writeDump('[' & thisByte  & ':' & chr(thisByte) & ']');
							break;
						}

						// no delims
						default : {
							thisVal = chr(thisByte);
							thisDelim = ' ';
							state = 'valueNoDelim';
							break;
						}

					}

				// processing value until we find the terminating delimiter (this is where we would add in support for escaping delimiters if it was required)
				} else if (state == 'value') {

					if (thisByte == thisDelim) {
						state = 'trim';
					} else {
						thisVal = thisVal & chr(thisByte);
					}


				} else if (state == 'valueNoDelim') {

					switch(thisByte) {
						// space or tab
						case 32: {}
						case 9: {
							// do nothing
							if (thisDelim == '') state = 'trim';
							break;
						}

						// equals (uh oh) <foo x= y=3> i.e "=" with nothing after it, the current val is actually the key for the next thing
						case 61: {
							stAttribs[thisKey] = '';
							thisKey = thisVal;
							thisVal = '';
							thisDelim = '';
							state = 'delim';
							break;
						}

						// reset state
						default : {
							thisVal = thisVal & chr(thisByte);
							thisDelim = '';
							break;
						}

					}


				// killing whitespace until we start the next key/value pair
				} else if (state == 'trim') {

					switch(thisByte) {
						// space or tab
						case 32: {}
						case 9: {
							// do nothing
							break;
						}

						// reset state
						default : {
							stAttribs[thisKey] = thisVal;
							thisVal = '';
							thisKey = chr(thisByte);
							thisDelim = '';
							state = 'key';
							break;
						}

					}



				}

				lastByte = thisByte;

			}

			// if we reach the end of the byte array we need to add whatever is in our buffers to the struct (if anything)
			if (len(trim(thisVal))) stAttribs[thisKey] = thisVal;
			else if (len(trim(thisKey))) stAttribs[thisKey] = '';

			return stAttribs;


		}
	</cfscript>

</cfcomponent>