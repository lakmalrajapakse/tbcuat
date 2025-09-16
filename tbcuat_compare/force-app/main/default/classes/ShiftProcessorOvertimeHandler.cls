/** 
*  @description : Apex class to implement Shift Processor overtime
**/
global with sharing class ShiftProcessorOvertimeHandler implements sirenum.ShiftProcessorOvertime{
    static final String DefaultHandler = 'ShiftProcessorOvertimeService';    
    private static Map<String, sirenum.ShiftProcessorOvertime> pluginHandlers;

    static {
        pluginHandlers = getPluginHandlers();
    }
    
    /** 
    *  @description : Method to get overtime baseline
    **/
    global Integer getOvertimeBaselineFor(sirenum__Shift__c shift, Datetime startDatetime, sirenum.ShiftProcessor.OvertimePeriodType periodType, sirenum.ShiftProcessorOvertimeContext context) {
        sirenum.ShiftProcessorOvertime pluginHandler = getPluginHandler(shift);
        return pluginHandler.getOvertimeBaselineFor(shift, startDatetime, periodType, context);
    }

    /** 
    *  @description : Method to get related data
    **/
    global Object getRelatedData(Datetime startDatetime, Datetime endDatetime, sirenum.ShiftProcessorOvertimeContext context) {
        return null;
    }

    /** 
    *  @description : Method to get required fields
    **/
    global Set<String> getRequiredFieldPaths(sirenum.ShiftProcessorOvertimeContext context) {
        Set<String> fieldsList = new Set<String>{            
            'sirenum__Contract__r.Plugin__c'
        };
        for (sirenum.ShiftProcessorOvertime plugin : pluginHandlers.values()) {
            fieldsList.addAll(plugin.getRequiredFieldPaths(context));            
        }
        return fieldsList;
    }

    

    /** 
    *  @description : Method to get start of day for
    **/
    global Datetime getStartOfDayFor(sirenum__Shift__c shift, sirenum.ShiftProcessorOvertimeContext context) {
        sirenum.ShiftProcessorOvertime pluginHandler = getPluginHandler(shift);
        return pluginHandler.getStartOfDayFor(shift, context);
    }
    
    /** 
    *  @description : Method to get start of week for
    **/
    global Datetime getStartOfWeekFor(sirenum__Shift__c shift, sirenum.ShiftProcessorOvertimeContext context) {
        sirenum.ShiftProcessorOvertime pluginHandler = getPluginHandler(shift);
        return pluginHandler.getStartOfWeekFor(shift, context);
    }

    /** 
    *  @description : Method to get if nominee relevant as past work
    **/
    global Boolean isNomineeRelevantAsPastWork(sirenum__Shift__c shift, sirenum__Shift__c nominee, sirenum.ShiftProcessor.OvertimePeriodType periodType, sirenum.ShiftProcessorOvertimeContext context){  
        sirenum.ShiftProcessorOvertime pluginHandler = getPluginHandler(shift);
        return pluginHandler.isNomineeRelevantAsPastWork(shift, nominee, periodType, context);
    }

    /** 
    *  @description : Method to get all plugin names from the contract
    **/
    public static Set<String> getPluginNames() {
        Set<String> pluginsList = new Set<String>();
        for (Schema.PicklistEntry picklistEntry : sirenum__ProActiveContract__c.Plugin__c.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) pluginsList.add(picklistEntry.getValue());
        }
        return pluginsList;
    }

    /** 
    *  @description : Method to get overtime plugin handler
    **/
    public static Map<String, sirenum.ShiftProcessorOvertime> getPluginHandlers() {
        Map<String, sirenum.ShiftProcessorOvertime> pluginHandlersList = new Map<String, sirenum.ShiftProcessorOvertime> {
            DefaultHandler => (sirenum.ShiftProcessorOvertime)Type.forName(ShiftProcessorOvertimeService.class.getName()).newInstance()
        };

        List<ApexTypeImplementor> apexTypeImplementorsList = [SELECT ClassName FROM ApexTypeImplementor WHERE InterfaceName = 'ShiftProcessorOvertime' 
            AND InterfaceNamespacePrefix = 'sirenum' and IsConcrete = true AND ApexClass.Name !=: ShiftProcessorOvertimeHandler.class.getName()
                AND ClassName IN: getPluginNames()];
        for (ApexTypeImplementor apexTypeImplementor : apexTypeImplementorsList) {            
            pluginHandlersList.put(apexTypeImplementor.ClassName, (sirenum.ShiftProcessorOvertime)Type.forName(apexTypeImplementor.ClassName).newInstance());
            
        }
        return pluginHandlersList;
    }

    /** 
    *  @description : Method to get overtime plugin handler
    **/
    private sirenum.ShiftProcessorOvertime getPluginHandler(sirenum__Shift__c shift) {
        sirenum.ShiftProcessorOvertime pluginHandler = null;
        if (shift.sirenum__Contract__r?.Plugin__c != null && pluginHandlers.containsKey(shift.sirenum__Contract__r?.Plugin__c)) {
            pluginHandler = pluginHandlers.get(shift.sirenum__Contract__r?.Plugin__c);
        } else {
            pluginHandler = pluginHandlers.get(DefaultHandler);
        }
        return pluginHandler;
    }
}