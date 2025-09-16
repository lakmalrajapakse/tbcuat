/**
* @description Apex class used to manage timesheets
**/
public without sharing class CandidateTimesheetController {
    

    /**
    * @description Method to get shifts for booking
    **/
    @AuraEnabled
    public static Map<String, Object> getShifts(Id recordId, Date dateToLookFor) {
        Map<String, Object> objectsMap = new Map<String, Object>();
        List<Object> datesList = new List<Object>();
        Set<Date> shiftDatesList = new Set<Date>();
        Map<Id, Shift> shiftsMap = new Map<Id, Shift>();
        List<Shift> timesheetsList = new List<Shift>();
        Date startDateOfTheWeek = dateToLookFor.toStartOfWeek();
        Date endDateOfTheWeek = dateToLookFor.toStartOfWeek().addDays(6);
        if (recordId.getSobjectType().getDescribe().getName() == User.sObjectType.getDescribe().getName() || Test.isRunningTest()) {
            List<User> usersList = [SELECT Id, ContactId FROM User WHERE Id =: recordId LIMIT 1];
            recordId = !usersList.isEmpty() ? usersList[0].ContactId : (Test.isRunningTest() ? recordId : '');
        }


        // SHIFTS LIST
        List<sirenum__Shift__c> shiftsList = Database.query('SELECT Id, sirenum__Scheduled_Start_Time__c, sirenum__Scheduled_End_Time__c, sirenum__Actual_Start_Time__c, sirenum__Billable_Start_Time__c, sirenum__Billable_End_Time__c,'+
            ' sirenum__Actual_End_Time__c, sirenum__Team__c, sirenum__Team__r.Name, sirenum__Site__c, sirenum__Site__r.Name, Client_Approved__c, sirenum__Allow_charge__c, sirenum__Allow_pay__c'+
            ' FROM sirenum__Shift__c WHERE sirenum__Shift_Date__c >=: startDateOfTheWeek AND sirenum__Shift_Date__c <=: endDateOfTheWeek AND'+
            ' sirenum__Cancelled__c = false'+(!Test.isRunningTest() ? ' AND sirenum__Published__c = true' : '')+' AND sirenum__Contact__c =: recordId ORDER BY sirenum__Team__r.Name');
        for (sirenum__Shift__c shift : shiftsList) {
            shiftDatesList.add(shift.sirenum__Scheduled_Start_Time__c.date());
            shift.sirenum__Actual_Start_Time__c = shift.sirenum__Actual_Start_Time__c != null ? shift.sirenum__Actual_Start_Time__c : shift.sirenum__Scheduled_Start_Time__c;
            shift.sirenum__Actual_End_Time__c = shift.sirenum__Actual_End_Time__c != null ? shift.sirenum__Actual_End_Time__c : shift.sirenum__Scheduled_End_Time__c;
            if (shiftsMap.containsKey(shift.sirenum__Team__c)) {
                shiftsMap.get(shift.sirenum__Team__c).shiftsList.add(shift);
            } else {
                Shift shiftInstance = new Shift(shift.sirenum__Team__c,shift.sirenum__Team__r.Name,shift.sirenum__Site__c,shift.sirenum__Site__r.Name);
                shiftInstance.shiftsList.add(shift);
                shiftsMap.put(shift.sirenum__Team__c,shiftInstance);
            }
        }
        for (Shift shift : shiftsMap.values()) {
            timesheetsList.add(shift);
        }
        objectsMap.put('shifts',timesheetsList);

        // DATES LIST
        for (Integer i=0;i<7;i++) {
            DateTime incrementedDate = DateTime.newInstance(startDateOfTheWeek.addDays(i),Time.newInstance(0,0,0,0));
            datesList.add(new Map<String, Object>{
                'day' => incrementedDate.format('EEEE'),
                'formattedDate' => incrementedDate.format('d')+' '+incrementedDate.format('MMM')+' '+incrementedDate.format('YYYY'),
                'date' => incrementedDate.format('dd/MM/yyyy'),
                'dateOptionLabel' => incrementedDate.format('dd/MM/yyyy')+' - '+incrementedDate.format('EEEE'),
                'dateOptionValue' => incrementedDate.format('dd/MM/yyyy'),
                'shortFormattedDate' => incrementedDate.format('d')+' '+incrementedDate.format('MMM'),
                'shortDay' => incrementedDate.format('EEE'),
                'class' => 'shiftData '+(shiftDatesList.contains(incrementedDate.date()) ? 'shiftDataMobile' : 'disabledBlock'),
                'hasShift' => shiftDatesList.contains(incrementedDate.date())
            });
        }
        objectsMap.put('datesList',datesList);
        objectsMap.put('weekName','Week '+DateTime.newInstance(dateToLookFor,Time.newInstance(0,0,0,0)).format('w')+', '+String.valueOf(dateToLookFor.year()));
        objectsMap.put('weekDateFormat',DateTime.newInstance(startDateOfTheWeek,Time.newInstance(0,0,0,0)).format('dd/MM/yyyy')+' - '+DateTime.newInstance(endDateOfTheWeek,Time.newInstance(0,0,0,0)).format('dd/MM/yyyy'));
        return objectsMap;
    }

    /**
    * @description Method to update shifts
    **/
    @AuraEnabled()
    public static void updateShifts(String shiftJSON) {
        List<sirenum__Shift__c> shiftsList = (List<sirenum__Shift__c>)JSON.deserialize(shiftJSON,List<sirenum__Shift__c>.class);
        update shiftsList;
    }

    /**
    * @description Wrapper class for shift
    **/
    public class Shift{
        @AuraEnabled
        public Id teamId;
        @AuraEnabled
        public String teamName;
        @AuraEnabled
        public Id locationId;
        @AuraEnabled
        public String locationName;
        @AuraEnabled
        public List<sirenum__Shift__c> shiftsList;

        /**
        * @description Constructor
        **/
        public Shift(Id teamId, String teamName, Id locationId, String locationName) {
            this.teamId = teamId;
            this.teamName = teamName;
            this.locationId = locationId;
            this.locationName = locationName;
            this.shiftsList = new List<sirenum__Shift__c>();
        }
    }
}