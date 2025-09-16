/** 
*  @description : Apex class to implement Timesheet Results Listener
**/
global virtual with sharing class TimesheetResultsListenerHandler implements sirenum.TimesheetResultsListener{
    
    /**
    *  @description Method to invoke the handle events
    **/
    global virtual void handleEvent(sirenum.TimesheetResultsEvent timesheetResultsEvent) {
        Set<Id> timesheetIds = new Set<Id>(timesheetResultsEvent.getIds());
        Map<String, Set<Id>> recordIdsByPluginHandlerMap = new Map<String, Set<Id>>();

        List<sirenum__Timesheet__c> timesheetsList = [SELECT Id, sirenum__Contract__r.Plugin__c FROM sirenum__Timesheet__c WHERE Id IN :timesheetIds];
        for (sirenum__Timesheet__c timesheet : timesheetsList) {
            if (sirenum.TimesheetResultsListener.class.isAssignableFrom(Type.forName(timesheet.sirenum__Contract__r.Plugin__c)) && ISirenumPlugin.class.isAssignableFrom(Type.forName(timesheet.sirenum__Contract__r.Plugin__c))) {
                if (recordIdsByPluginHandlerMap.containsKey(timesheet.sirenum__Contract__r.Plugin__c)) {
                    recordIdsByPluginHandlerMap.get(timesheet.sirenum__Contract__r.Plugin__c).add(timesheet.Id);
                } else {
                    recordIdsByPluginHandlerMap.put(timesheet.sirenum__Contract__r.Plugin__c, new Set<Id>{timesheet.Id});
                }
            }
        }

        // invoke the handler with its ids
        if (!recordIdsByPluginHandlerMap.isEmpty()) {
            for (String handlerName : recordIdsByPluginHandlerMap.keySet()) {
                ISirenumPlugin pluginHandler = (ISirenumPlugin)Type.forName(handlerName).newInstance();
                pluginHandler.processRecords(recordIdsByPluginHandlerMap.get(handlerName));
            }
        }
    }
}