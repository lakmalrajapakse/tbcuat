public with sharing class SIM_ManualTimesheetGenerationBatch implements Database.Batchable<Object>, Database.AllowsCallouts, Database.Stateful {
    String jsonString;
    SIM_ManualTimesheetGeneration uploader;

    public SIM_ManualTimesheetGenerationBatch(SIM_ManualTimesheetGeneration uploader, String jsonString) {
       this.jsonString = jsonString;
       this.uploader = uploader;
    }

    public Iterable<Object> start(Database.BatchableContext bc) {
        return new SIM_JSONIterable(new SIM_ShiftUploadIterator(jsonString));
    }    
    
    public void execute(Database.BatchableContext bc, List<Object> scope) {
        SIM_Response.Response resp = uploader.loadSheetRows(scope);  
    }

    // Description: Batch finish method
    public void finish(Database.BatchableContext bc) {        
        uploader.finalizeLoadBatch(bc.getJobId());
    }
}