/** 
*  @ Description : Rebate interface
**/ 
public interface IRebate {
    
    Map<Id, Decimal> calculateRebate(Set<Id> timesheetIds);
}