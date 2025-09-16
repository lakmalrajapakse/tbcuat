public with sharing class SIM_ShiftUploadIterator extends SIM_JSONIterator {
    public SIM_ShiftUploadIterator(String jsonString) {
        super(new List<SIM_JsonData> {new ShiftData(jsonString)}, (System.Type) null);
    }

    protected override boolean setParserPos(JSONParser parser, SIM_JsonData jData) {
        JSONToken t = parser.nextToken();
        while (t == null || t != JSONToken.START_ARRAY)
            t = parser.nextToken();        

        return (t == JSONToken.START_ARRAY);
    }

    public class ShiftData implements SIM_JsonData {
        String jsonString;

        public ShiftData(String jsonString) {
            this.jsonString = jsonString;
        }

        public String getJsonString() {
            return jsonString;
        }
    }
}