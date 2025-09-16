public abstract class SIM_JSONIterator implements Iterator<Object> {
    protected System.Type parseType;
    protected JSONParser parser;
    protected Object nextObject;
    protected Boolean nextTokenExist;
    protected List<SIM_JsonData> jsonData;
    protected SIM_JsonData currentJsonData;
    protected Integer curDataPos;

    /*
        parser - a JSON parser pointing to an array of objects
        parseType - parse JSON string to arrary of parseType objects (this object must implement SIM_ClassToSObject)
    */
    public SIM_JSONIterator(List<SIM_JsonData> pJsonData, System.Type pParseType) {
         this.jsonData = pJsonData;
         this.parseType = pParseType;
         this.nextTokenExist = true;
         this.curDataPos = 0;
    }

    public boolean hasNext() {
       getNextObject();

       return (nextObject != null);       
    }

    public virtual Object next() {
        getNextObject();
        if (nextObject != null) {
           Object retObj = nextObject;
           if (nextObject instanceOf SIM_ClassToSObject) {
              retObj = ((SIM_ClassToSObject) nextObject).getSObject(currentJsonData);
           }

           nextObject = null;
           return retObj;
        } else 
           return null;
        
    }

    protected virtual void getNextJSON() {
       if (curDataPos < jsonData.size()) {
           currentJsonData = jsonData[curDataPos];
           parser = JSON.createParser(currentJsonData.getJsonString());           
           curDataPos++;

           //set parser to array object if fails - parse next JSON
           if (!setParserPos(parser, currentJsonData)) 
              getNextJSON();
       } else 
          parser = null;

    }

    protected abstract boolean setParserPos(JSONParser parser, SIM_JsonData jData);

    protected virtual void getNextObject() {        
        if (nextTokenExist) {
            if (parser == null) 
                getNextJSON();
            
            if (parser == null) {
                nextObject = null;
                nextTokenExist = false;
                return;
            }
                
            if (nextObject != null)
                return;
            else 
                if (parser != null)
                    if (parser.nextToken() == JSONToken.START_OBJECT) 
                        if (parseType != null)
                           nextObject = parser.readValueAs(parseType);
                        else 
                           nextObject = readObjectAsMap();
                    else {
                        parser = null;
                        getNextObject();
                    }        
        }          
    }

    private Map<String,Object> readObjectAsMap() {
        Map<String, Object> obj = new Map<String, Object>();
        JSONToken t;
        while (true) {
            t = parser.nextToken();
            if (t != JSONToken.FIELD_NAME)
               break;
            String fieldname = parser.getCurrentName();     
            t = parser.nextToken();
            String fieldvalue = parser.getText();
            obj.put(fieldname, fieldvalue);
        }        

        return obj;
    }
}