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

</cfcomponent>