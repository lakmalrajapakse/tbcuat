/**
* @description Apex class to manage the calculation of the rebate
**/
public with sharing class RebateCalculationHandler implements IRebate{
    
    /**
    * @description Method to calculate rebates
    **/
    public Map<Id, Decimal> calculateRebate(Set<Id> timesheetIds){
        Map<Id, Decimal> rebateValueByTimesheetIdMap = new Map<Id, Decimal>();
        for (Id timesheetId : timesheetIds) {
            rebateValueByTimesheetIdMap.put(timesheetId, 0.00);
        }
        return rebateValueByTimesheetIdMap;
    }
}