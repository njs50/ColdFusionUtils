component{

	/*
		Expects Saxon-B in your java class path. might also work with Saxon-HE 
	*/

	variables.oProcessor = createObject("java","net.sf.saxon.s9api.Processor").init(false);
	variables.oTransformer = {};

	// sets up the transformer. 
	public function init(string xsl_path) {
		// setup the xslt
		var xslt_source = createObject("java", "javax.xml.transform.stream.StreamSource").init("file:///#arguments.xsl_path#");
		variables.oTransformer = variables.oProcessor.newXsltCompiler().compile(xslt_source).load();	
		return this;
	}


   // set XSLT params. you probably need to javacast the value before passing it in
	public void function setParam(name, value) {
	   var pName = createObject("java","net.sf.saxon.s9api.QName").init(arguments.name);
	   var pValue = createObject("java","net.sf.saxon.s9api.XdmAtomicValue").init(arguments.value);
	   variables.oTransformer.setParameter(pName,pValue);	 		
	}

	
	// transform an XML string and returns the transformed string
	// this is not a thread safe function. be warned!!!
	public string function transform(string xmlString) {

		var xmlReader = createObject("java", "java.io.StringReader").init(arguments.xmlString);
		var xml_source = variables.oProcessor.newDocumentBuilder().build(createObject("java", "javax.xml.transform.stream.StreamSource").init(xmlReader));

		var out = createObject("java","net.sf.saxon.s9api.Serializer").init();
	    var stringWriter = createObject("java", "java.io.StringWriter").init();
	    		    	
	    out.setOutputWriter(stringWriter);
	
		variables.oTransformer.setInitialContextNode(xml_source);
	    variables.oTransformer.setDestination(out);
	    
	    variables.oTransformer.transform();
	    
	    return stringWriter.toString();
		
	}

}