public with sharing class SIM_SObjResults {
    List<String> keyFields;
    Map<String, List<sObject>> resultMap = new Map<String, List<sObject>>();    

    public SIM_SObjResults(List<String> keyFields, List<sObject> results) {
        this.keyFields = keyFields;
        mapResults(results);
    }

    public Set<Id> getIds() {
        List<List<SObject>> values = resultMap.values();
        Set<id> ids = new Set<id>();
        
        for (List<SObject> objs : values) {
            for (SObject obj : objs) {
                ids.add((Id) obj.get('id'));
            }
        }

        return ids;
    }

    public List<sObject> getResultRow(String key) {
        return resultMap.get(key);
    }
    
    private void mapResults(List<SObject> objs) {
        for (SObject obj : objs) {
            String key = getKey(obj);
            List<sObject> row = resultMap.get(key);
            if (row == null) {
                resultMap.put(key, new List<SObject>{obj});
            } else {
                row.add(obj); 
            }
        }        
    }

    public String getKey(List<Object> values) {
        String key = '';

        for (Object value: values) {
            key = key + '_' + ((value == null) ? '' : value.toString().toUpperCase());
        }

        return key;
    }

    private String getKey(SObject obj) {        
        String key = '';
        for (String keyField: keyFields) {
            key = key + '_' + getPathValue(obj, keyField).toUpperCase();
        }

        return key;
    }

    private String getPathValue(sObject obj, String fieldPath) {
        SObject currentSObject = obj;
        String currentPath = fieldPath;

        while (currentPath.contains('.')){
            List<String> pathPartList = currentPath.split ('[.]', 2);
            currentSObject = (SObject)currentSObject.getSobject(pathPartList[0]);
            
            if (currentSObject == null) { return ''; }
            currentPath = pathPartList[1];
        }
        
        return (currentSObject.get(currentPath) != null) ? currentSObject.get(currentPath).toString() : '' ;
    } 
}