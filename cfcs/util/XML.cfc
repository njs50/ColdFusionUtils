component{

	//Common variables
	variables.oXMLTransformer = {};

	variables.oStringUtil = new String();

	public function init() {
		// SETUP XML TRANSFORMER
		variables.oXMLTransformer = new SaxonXSL('#GetDirectoryFromPath(getcurrenttemplatepath())#xml-to-json-xsl2.xsl');
		variables.oXMLTransformer.setParam("use-rabbitfish",javacast("boolean",true));
		variables.oXMLTransformer.setParam("skip-root",javacast("boolean",true));
		return this;
	}


	/* merges XML files togeather. each must have a rootnode and there cant be namespace conflicts */
	public string function merge(required string rootnode) output="no" {
		
		var root = arguments.rootNode;
		
		structDelete(arguments,'rootNode');
		
		var stAttributes = {};
		
		var xml_def = '';
		
		var sXML = '';
		
		for (var new_root in arguments) {
			
			aXMLParts = oStringUtil.reSubMatch('(<\?[^>]+>)\s*(<([^ ]+)[^>]*>)(.*)</\3\s*>',arguments[new_root]);
						
			/*
			 * Split into:
			 * 
			 * 2 : xmlHeader
			 * 3 : root Node
			 * 4 : root Node name
			 * 5 : remainder of XML
			 * 
			 **/
			 
			 if (xml_def == '') xml_def = aXMLParts[2];
			 
			 if (xml_def != aXMLParts[2]) throw('conflicting XML headers (#xml_def#) (#aXMLParts[2]#)');

			sXML &= '<#new_root#>#aXMLParts[5]#</#new_root#>';

			/* get attribute key/value pairs from root node */
			aXMLNS = reMatch('\s+\S+\s*=\s*\S+"', aXMLParts[3]);

			for (var sNS in aXMLNS) {
				var lPos = find('=',sNS);
				var key = trim(left(sNS,lPos -1));
				var value = trim(right(sNS, len(sNS) - lPos));		
				
				if (!structKeyExists(stAttributes,key)) {
					stAttributes[key] = value;			
				} else if (stAttributes[key] != value) {
					throw('conflicting attributes in root nodes (#key#)');
				}
				
			}
			
		}
			
		var sRootNode = '<#root#';
		
		for (var key in stAttributes) sRootNode &= ' #key#=#stAttributes[key]#';
		
		sRootNode &= '>';
			
		var sXML = xml_def & sRootNode & sXML & '</#root#>';
				
		return sXML;		
		
	}
			

	/* uses the xslt transform we setup in init to turn xml into json (ignores attributes) */
	public string function xmlToJSON(string xmlSource) output="no" {
		return variables.oXMLTransformer.transform(arguments.xmlSource);
	}


	// remove root node if there is a single one. and recurse over
	public function fixArrays(data) {
		if (isStruct(data)) {
			if (structCount(data) eq 1) {
				if (structKeyExists(data,"@nil") and data["@nil"]) return "";
				return recursiveFixArrays(data[structKeylist(data)]);
			} else {
				for (var key in data) data[key] = recursiveFixArrays(data[key]);
				return data;
			}
		} else if (isArray(data)) {
			for (var i = 1; i <= arrayLen(data); i++) {
				data[i] = recursiveFixArrays(data[i]);
			}
			return data;
		} else return recursiveFixArrays(data);
	}


	// replace structs with one member with arrays of one item
	private function recursiveFixArrays(data) {
		if (isStruct(data)) {
			if (structCount(data) eq 1) {
				if (structKeyExists(data,"@nil") and data["@nil"]) return "";
				if (isArray(data[structKeylist(data)])) return recursiveFixArrays(data[structKeylist(data)]);
				return [recursiveFixArrays(data[structKeylist(data)])];
			} else {
				for (var key in data) data[key] = recursiveFixArrays(data[key]);
				return data;
			}
		} else if (isArray(data)) {
			for (var i = 1; i <= arrayLen(data); i++) {
				data[i] = recursiveFixArrays(data[i]);
			}
			return data;
		} else if (reFind("^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d",data)) {
			// fix timestamps
			return replace(data,"T"," ");
		} else return data;
	}

}