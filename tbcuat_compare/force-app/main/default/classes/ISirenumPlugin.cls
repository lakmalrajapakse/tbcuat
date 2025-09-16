/** 
*  @ Description : datatable interface
**/ 
public interface ISirenumPlugin {
    
    //Define the method signature to be implemented in classes that implements the interface
    void processRecords(Set<Id> recordIds);
}