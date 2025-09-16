/**
*  @description Helper class for shift
**/
public without sharing class ShiftHelper {
    
    /** 
    *  @description : Method to manage placements
    **/
    public static void managePlacements(List<sirenum__Shift__c> shiftsList) {
        Date minDate;
        Set<id> siteIds = new Set<id>();
        Set<id> jobRoleIds = new Set<id>();
        Set<id> contactIds = new Set<id>();
        Set<id> shiftIds = new Set<id>();

        for (sirenum__Shift__c s : shiftsList) {
            if (s.sirenum__Placement__c != null || s.sirenum__Cancelled__c == true || s.sirenum__Team__c == null 
                || s.sirenum__Contact__c == null) {
                continue;
            }
          
            if (minDate == null || minDate > s.sirenum__Shift_Date__c) {
                minDate = s.sirenum__Shift_Date__c;
            }

            contactIds.add(s.sirenum__Contact__c);
            jobRoleIds.add(s.sirenum__Team__c);

            if (s.sirenum__Site__c != null) { 
                siteIds.add(s.sirenum__Site__c);
            }

            shiftIds.add(s.id);            
        }

        if (shiftIds.isEmpty()) {
            return;
        }

        Map<String, List<sirenum__Shift__c>> toProcess = getShifts(shiftIds);

        Map<String, List<sirenum__Placement__c>> placementMap = getPlacementData(contactIds, jobRoleIds, siteIds, minDate);

        Map<String, sirenum__Placement__c> placementToUpsert = new Map<String, sirenum__Placement__c>();
        
        for (String key : toProcess.keySet()) {
            List<sirenum__Placement__c> pList  = placementMap.get(key);
            List<sirenum__Shift__c> sList = toProcess.get(key);
            sirenum__Placement__c pToCreate= placementToUpsert.get(key);

            for (sirenum__Shift__c s : sList) {
                if (pList != null) { 
                    for (sirenum__Placement__c p : pList) {
                        if (p.sirenum__End_Date__c == null) {
                            if (p.sirenum__Start_Date__c >= s.sirenum__Shift_Date__c) {
                                p.sirenum__Start_Date__c = s.sirenum__Shift_Date__c;
                                p.Name = (s.sirenum__Contact__r.FirstName + ' ' + s.sirenum__Contact__r.LastName +' - '+s.sirenum__Team__r.Name+' - '+Datetime.newInstance(s.sirenum__Shift_Date__c, Time.newInstance(0,0,0,0)).format('dd-MM-yyyy')).left(80);
                                placementToUpsert.put(key, p);
                                pToCreate = p;
                            }
                        }
                      
                        if ((p.sirenum__End_Date__c == null || p.sirenum__End_Date__c >= s.sirenum__Shift_Date__c) && p.sirenum__Start_Date__c <= s.sirenum__Shift_Date__c) {
                            if (p.Job_Role_Name__c != s.Job_Role_Name__c) {
                                p.Job_Role_Name__c = s.Job_Role_Name__c;
                                placementToUpsert.put(key, p);
                            }

                            s.sirenum__Placement__c = p.id;   
                            pToCreate = p;                         
                        }
                    }
                }
                
                if (s.sirenum__Placement__c == null) {                     
                    if (pToCreate == null) {
                        pToCreate = new sirenum__Placement__c(                    
                            sirenum__Contact__c = s.sirenum__Contact__c,
                            sirenum__Contract__c = s.sirenum__Team__r.sirenum__Account__c,
                            sirenum__Job_Role__c = s.sirenum__Team__c,
                            sirenum__Site__c = s.sirenum__Site__c,
                            sirenum__Start_Date__c = s.sirenum__Shift_Date__c,
                            sirenum__Status__c = 'Active',     
                            Job__c = s.s5m__BH4SFJob__c,
                            Job_Role_Name__c = s.Job_Role_Name__c,
                            Name = (s.sirenum__Contact__r.FirstName + ' ' + s.sirenum__Contact__r.LastName +' - '+s.sirenum__Team__r.Name+' - '+Datetime.newInstance(s.sirenum__Shift_Date__c, Time.newInstance(0,0,0,0)).format('dd-MM-yyyy')).left(80)
                        );

                        placementToUpsert.put(key, pToCreate);
                        if (pList == null) {
                            pList = new List<sirenum__Placement__c>();
                        }
                        
                        pList.add(pToCreate);
                        placementMap.put(key, pList);                        
                    }
                }

            }
        }

        if (!placementToUpsert.isEmpty()) {
            upsert placementToUpsert.values();
        }

        List<sirenum__Shift__c> shiftsToUpdate = new List<sirenum__Shift__c>();
        for (String key : toProcess.keySet()) {            
            List<sirenum__Shift__c> sList = toProcess.get(key);

            if (!placementToUpsert.isEmpty()) {
                sirenum__Placement__c p = placementToUpsert.get(key);
                if (p != null) {
                    for (sirenum__Shift__c s : sList) {
                        if (s.sirenum__Placement__c == null) {
                            s.sirenum__Placement__c = p.id;
                        }
                    }
                }
            }

            shiftsToUpdate.addAll(sList);
        }
        
        update shiftsToUpdate;
    }

    private static Map<String, List<sirenum__Shift__c>> getShifts(Set<Id> shiftIds) {
        Map<String, List<sirenum__Shift__c>> shiftData = new Map<String, List<sirenum__Shift__c>>();
        List<sirenum__Shift__c> shifts = [
            select id, sirenum__Contact__c, sirenum__Team__c, sirenum__Site__c, sirenum__Shift_Date__c,
            sirenum__Contact__r.FirstName, sirenum__Placement__c,
            sirenum__Contact__r.LastName, sirenum__Team__r.Name, sirenum__Team__r.sirenum__Account__c, s5m__BH4SFJob__c, Job_Role_Name__c
            from sirenum__Shift__c where id in :shiftIds];
        
        for (sirenum__Shift__c s : shifts) {
            String key = getKey(s);            
            List<sirenum__Shift__c> sList = shiftData.get(key);
            if (sList == null) {
                shiftData.put(key, new List<sirenum__Shift__c> {s});
            } else {
                sList.add(s);
            }            
        }

        return shiftData;        
    }

    private static Map<String, List<sirenum__Placement__c>> getPlacementData(Set<Id> contactIds, Set<Id> jobRoleIds, Set<Id> siteIds, Date minDate) {
        Map<String, List<sirenum__Placement__c>> placementData = new Map<String, List<sirenum__Placement__c>>();
        String pSql = 'select id, sirenum__Job_Role__c, sirenum__Contact__c, sirenum__Site__c, sirenum__Start_Date__c, sirenum__End_Date__c, Job_Role_Name__c ';
        pSql += 'from sirenum__Placement__c where sirenum__Job_Role__c in :jobRoleIds and sirenum__Contact__c in :contactIds and  sirenum__Status__c = \'Active\' and (sirenum__End_Date__c = null or sirenum__End_Date__c >= :minDate) ';

        if (siteIds.isEmpty()) {
            pSql += 'and sirenum__Site__c = null ';
        } else {
            pSql += 'and (sirenum__Site__c = null or sirenum__Site__c in :siteIds)';
        }
        pSql += 'order by sirenum__Job_Role__c, sirenum__Contact__c, sirenum__Site__c, sirenum__Start_Date__c';

        List<sirenum__Placement__c> placements = (List<sirenum__Placement__c>) Database.query(pSQl);
        for (sirenum__Placement__c placement : placements) {
            String key = getKey(placement);            
            List<sirenum__Placement__c> pList = placementData.get(key);
            if (pList == null) {
                placementData.put(key, new List<sirenum__Placement__c>{placement});
            } else {
                pList.add(placement);
            }
        }
    
        return placementData;
    }

    private static String getKey(sirenum__Placement__c placement) {
        return JSON.serialize(new Map<String, Object> {
            'contactId' => placement.sirenum__Contact__c,
            'jobRoleId' => placement.sirenum__Job_Role__c,
            'siteId' => placement.sirenum__Site__c
        });
    }

    private static String getKey(sirenum__Shift__c shift) {
        return JSON.serialize(new Map<String, Object> {
            'contactId' => shift.sirenum__Contact__c,
            'jobRoleId' => shift.sirenum__Team__c,            
            'siteId' => shift.sirenum__Site__c
        });        
    }
}