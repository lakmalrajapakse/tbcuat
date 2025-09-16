/**
* @description Apex class to calculate week based on the given date
**/
public with sharing class IntimeWeekCalculationService {
    
    /**
    * @description Method to calculate week for a given date
    **/
    public static String getWeek(Date weekToCalculateFrom) {
        String week = '';
        Integer year = weekToCalculateFrom.year();
        Date startDate = Date.newInstance(year, 04, 1).toStartOfWeek();
        if (weekToCalculateFrom < startDate) startDate = Date.newInstance((year - 1), 04, 1).toStartOfWeek();
        Integer weekNumber = Integer.valueOf(Decimal.valueOf((startDate.daysBetween(weekToCalculateFrom) / 7)).round(System.RoundingMode.FLOOR)) + 1;
        week = String.valueOf((weekToCalculateFrom.month() > 3 ? (weekToCalculateFrom.year() + 1) : weekToCalculateFrom.year()))+(weekNumber < 10 ? '0' : '')+String.valueOf(weekNumber);
        return week;
    }
}