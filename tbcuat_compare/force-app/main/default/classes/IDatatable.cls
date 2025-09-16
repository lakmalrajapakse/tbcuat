/** 
*  @ Description : datatable interface
**/ 
public interface IDatatable {
    //Define the method signature to be implemented in classes that implements the interface
    Map<String, Object> getDatatableAttributes(Map<String, Object> dataTableParams);
    List<Map<String,Object>> getColumns();
    List<Object> getData(Map<String, Object> dataTableParams);
    Object saveRecords(Map<String, Object> datatableParams);
}