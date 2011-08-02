component{

	//Common variables
	variables.oXMLTransformer = {};


	public function init() {
		// SETUP XML TRANSFORMER
		variables.oXMLTransformer = new SaxonXSL('#GetDirectoryFromPath(getcurrenttemplatepath())#xml-to-json-xsl2.xsl');
		variables.oXMLTransformer.setParam("use-rabbitfish",javacast("boolean",true));
		variables.oXMLTransformer.setParam("skip-root",javacast("boolean",true));
		return this;
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