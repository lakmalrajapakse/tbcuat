/**
* @description: Contains methods for serializing Apex objects into XML format and deserializing XML to Apex object.
**/
public class XMLSerializer{


    //Private Members
    private boolean serializeNulls = true;  				// Serializes XML nodes even if the content is null
    private string rootElement;              				// Root element to wrap around the serialized string.
    private Set<string> deSerializeAsArrayNodes = new Set<string>();	// Collection of node names to be deserialized as array.
    private String namespacePrefix;


    /**
    * @description: Constructor
    **/
    public XMLSerializer() {
        this.namespacePrefix = '';
    }

    /**
    * @description: Constructor
    **/
    public XMLSerializer(String namespacePrefix) {
        this.namespacePrefix = namespacePrefix;
    }
    
    /*
    @Description    : Serializes the object passed to XML string
    @Parameter      : objectToSerialize = Apex object to serialize into XML
    @Returns        : XML String
    */
    public string serialize(object objectToSerialize){        
        object deSerialized = JSON.deserializeUntyped(JSON.serialize(objectToSerialize));               
        return !string.isEmpty(rootElement) ? Wrap(rootElement,serialize((Map<string,object>)deSerialized)) : serialize((Map<string,object>)deSerialized);     
    }
    
    /*
    @Description    : Serializes the object to XML string.
    @Parameter      : objectToSerialize = Apex object to serialize into XML
    @Parameter      : suppressApexObjectNulls = if true, it will not serialize empty elements to XML.
    @Parameter	: Name of the root element to wrap serialized string with.
    @Returns        : XML String
    */
    public string serialize(object objectToSerialize,boolean suppressApexObjectNulls,string addRootElementName){
        this.serializeNulls = !suppressApexObjectNulls;
        this.rootElement = addRootElementName;
        return serialize(objectToSerialize);
    }
    
    /*
    @Description    : Converts JSON string to XML String.
    @Parameter      : jsonString = jsonString
    @Returns        : XML String
    */
    public string jsonToXML(string jsonString){
        object deSerialized = JSON.deserializeUntyped(jsonString);               
        return !string.isEmpty(rootElement) ? Wrap(rootElement,serialize((Map<string,object>)deSerialized)) : serialize((Map<string,object>)deSerialized);
    }
    
    /*
    @Description    : Converts JSON string to XML String.
    @Parameter      : jsonString = jsonString
    @Parameter	: suppressNulls = ignores empty Json elements, if true
    @Returns        : XML String
    */
    public string jsonToXML(string jsonString,boolean suppressNulls){
        this.serializeNulls = !suppressNulls;       
        return jsonToXML(jsonString);
    }
    
    /*
    @Description    : deSerializes the xml into the object of apextype
    @Parameter      : xmlString = xml String to deSerialize
    @Parameter      : apexType  = type of object to deSerialize to
    @Returns        : object of type apexType
    */
    public object deSerialize(string xmlString, System.Type apexType){   
        string json = XMLToJson(xmlString); 
        return System.JSON.deserialize(json,apexType);  		
    }
    
    /*
    @Description    : deSerializes the xml into the object of the type passed
    @Parameter      : xmlString = xml String to deSerialize
    @Parameter      : apexType  = type of object to deSerialize to
    @Parameter      : deSerializeNodesAsArray  = collection of node names to deserialize as array (Even if xml representation is not an array)
    @Returns        : object of type apexType
    */
    public object deSerialize(string xmlString, System.Type apexType,Set<String> deSerializeNodesAsArray){   
        this.deSerializeAsArrayNodes = toLower(deSerializeNodesAsArray);
        return deSerialize(xmlString,apexType);		
    }    
    
    /*
    @Description    : deSerializes the xml string into collection of primitive data types.
    @Parameter      : xmlString = xml String to deSerialize
    @Returns        : collection of primitive data types
    */  
    public object deSerializeUnTyped(string xmlString){  
        return xmlToUnTyped(xmlString);  		
    }
    
    /*
    @Description    : deSerializes the xml string into collection of primitive data types.
    @Parameter      : xmlString = xml String to deSerialize
    @Parameter      : deSerializeNodesAsArray  = collection of node names to deserialize as array (Even if xml representation is not an array)
    @Returns        : collection of primitive data types
    */
    public object deSerializeUnTyped(string xmlString,Set<string> deSerializeNodesAsArray){  
        this.deSerializeAsArrayNodes = toLower(deSerializeNodesAsArray);
        return xmlToUnTyped(xmlString);  		
    }
    
    /*
    @Description    : Converts XML string to json string
    @Parameter      : xmlString = XML String to convert
    @Returns        : JSON String
    */
    public  string XMLToJSON(string xmlString){
        return System.JSON.serialize(XMLToUnTyped(xmlString));
    } 
    
    /*
    @Description    : Converts XML string to json string
    @Parameter      : xmlString = XML String to convert
    @Parameter      : deSerializeNodesAsArray  = collection of node names to deserialize as array (Even if xml representation is not an array)
    @Returns        : JSON String
    */
    public  string xmlToJSON(string xmlString,Set<string> deSerializeNodesAsArray){  
        this.deSerializeAsArrayNodes = toLower(deSerializeNodesAsArray);
        return System.JSON.serialize(XMLToUnTyped(xmlString));
    }   
    
	/*
    @Description    : resets serialize and deserialize options to default
    */
    public void resetDefaults(){
        this.serializeNulls = true;
        this.rootElement = null;
        this.deSerializeAsArrayNodes.clear();
    }
    
    //Helpers
    
    /*
    @Description    : Serialize method
    @Parameter      : objectMap = Map of String and objects
    @Returns        : XML String
    */
    private string serialize(Map<string,object> objectMap){
        string xmlString = '';    
        for(string key:objectMap.keySet()){  
            object o = objectMap.get(key);
            if(o == null) { if(this.SerializeNulls)     xmlString += wrap(key,null); }                       
            else if(o InstanceOf List<object> )         xmlString += serialize((List<object>) o,key);
            else if(o InstanceOf Map<string,object> )   xmlString += wrap(key,serialize((Map<string,object>) o));
            else                                        xmlString += wrap(key,string.valueOf(o).escapeXml());                               
        }
        return xmlString;
    }
    
    /*
    @Description    : Serialize method
    @Parameter      : objectList = List of objects
    @Parameter      : key = key to wrap all elements of the list with 
    @Returns        : XML String
    */
    private string serialize(List<object> objectList, string key){
        string xmlString = '';      
        for(object o:objectList){    
            if (o InstanceOf string)				xmlString += wrap(key,string.valueOf(o).escapeXml()); 	
            else if(o InstanceOf List<object> )  	xmlString += wrap(key,serialize((List<object>) o, key));
            else                            		xmlString += wrap(key,serialize((Map<string,object>) o));                
        }     
        return xmlString;
    }
    
    /*
    @Description    : Wraps value with key xml element
    @Parameter      : key = Xml node name
    @parameter	: value = xml node value
    @Returns        : XML String
    */
    private string wrap(string key, string value){
        return (string.isNotBlank(value) || serializeNulls) ? ((!String.isBlank(this.namespacePrefix) ? '<'+this.namespacePrefix+':' : '<') + key + '>' + (string.isBlank(value) ? '' : value) + (!String.isBlank(this.namespacePrefix) ? '</'+this.namespacePrefix+':' : '</') + key + '>') : value;
    }
    
    /*
    @Description    : deSerializes the xml string into collection of primitive data types.
    @Parameter      : xmlString = xml String to deSerialize
    @Parameter      : deSerializeNodesAsArray  = collection of node names to deserialize as array (Even if xml representation is not an array)
    @Returns        : collection of primitive data types
    */   
    private  Map<string,object> XMLToUnTyped(string xmlString){
        xmldom xd = new xmldom(xmlString);
        xmldom.Element document = xd.ownerDocument();
        return (Map<string,object>)parseNode(document);
    }  
    
    /*
    @Description    : parses an XML node
    @Parameter      : e = xml node (of type xmldom.Element)
    @Returns        : object
    */
    private object parseNode(xmldom.Element e){
        if(e.childNodes.size()>0) return complexNodeToMap(e); 
        else  return e.nodeValue;  
    }
    
    /*
    @Description    : Converts a complex xml node to collection of primitive types.
    @Parameter      : e = xml node (of type xmldom.Element)
    @Returns        : Map representation of the node.
    */
    private Map<string,object> complexNodeToMap(xmldom.Element e){       
        Map<string,object> cNodeMap = new Map<string,object>();
        for(xmldom.Element cNode : e.childNodes){                 
            if(cNodeMap.containsKey(cNode.nodeName)){                    
                object o = cNodeMap.get(cNode.nodeName);                    
                if(o InstanceOf List<object>) ((List<object>) o).add(parseNode(cNode));
                else cNodeMap.put(cNode.nodeName,new List<object>{o,parseNode(cNode)});                    
            }
            else cNodeMap.put(cNode.nodeName, deSerializeAsArrayNodes.contains(cNode.nodeName.toLowerCase())? new List<object>{parseNode(cNode)} : parseNode(cNode));
        }
        return cNodeMap;
    } 
    
    /*
    @Description    : Converts all elements of the set to lower case
    @Parameter      : stringSet = Set of strings to convert to lower case.
    @Returns        : Converted set of strings.
    */
    private Set<string> toLower(Set<string> stringSet){
        Set<string> lowerStringSet = new Set<string>();
        for(string s:stringSet) lowerStringSet.add(s.toLowerCase());
        return lowerStringSet;
    }
}