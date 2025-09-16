/**
* @description : Apex class to share records
**/
public without sharing class SharingHelper {
    
    public enum TriggerContext {RECORDCREATE, RECORDUPDATE, RECORDDELETE, RECORDCREATEDELETE}

    /**
    * @description Method to create sharing records
    **/
    public static void manageSharing(String sObjectName, List<sObject> recordsList, Map<Id, sObject> oldRecordsMap, TriggerContext triggerContext) {
        List<sObject> shareRecordsToInsert = new List<sObject>();
        List<sObject> shareRecordsToDelete = new List<sObject>();
        Set<Id> recordIds = new Set<Id>();
        Set<Id> planCodeIds = new Set<Id>();
        Set<String> branchNamesList = new Set<String>();
        SharingSetting__mdt sharingSetting = getSharingSetting(sObjectName);
        
        if (sharingSetting != null) {
            for (sObject record : recordsList) {
                if(!String.isBlank(sharingSetting.PlanCodeField__c) && record.get(sharingSetting.PlanCodeField__c) != null) {
                    recordIds.add((Id)record.get('Id'));
                    planCodeIds.add((Id)record.get(sharingSetting.PlanCodeField__c));
                } 
                if (!String.isBlank(sharingSetting.BranchNameField__c) && record.get(sharingSetting.BranchNameField__c) != null) {
                    recordIds.add((Id)record.get('Id'));
                    branchNamesList.add(String.valueOf(record.get(sharingSetting.BranchNameField__c)).replace(' ','_'));
                    branchNamesList.add('Branch_'+String.valueOf(record.get(sharingSetting.BranchNameField__c)).replace(' ','_'));
                }
                if (triggerContext == SharingHelper.TriggerContext.RECORDUPDATE && !String.isBlank(sharingSetting.PlanCodeField__c) && (sharingSetting.Recalculate__c || record.get(sharingSetting.PlanCodeField__c) != oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.PlanCodeField__c))) {
                    recordIds.add((Id)record.get('Id'));
                    planCodeIds.add((Id)oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.PlanCodeField__c));
                }
                if (triggerContext == SharingHelper.TriggerContext.RECORDUPDATE && !String.isBlank(sharingSetting.BranchNameField__c) && (sharingSetting.Recalculate__c || record.get(sharingSetting.BranchNameField__c) != oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c))) {
                    recordIds.add((Id)record.get('Id'));
                    if (oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c) != null) {
                        branchNamesList.add(String.valueOf(oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c)).replace(' ','_'));
                        branchNamesList.add('Branch_'+String.valueOf(oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c)).replace(' ','_'));
                    } 
                }
            }

            if (!recordIds.isEmpty()) {
                List<sObject> sObjectRecordsList = (List<sObject>)Database.query(getSoqlQuery(sharingSetting));
                List<Picklist_Library__c> pickListLibrariesList = [SELECT Id, Name, Branch__c, Branch__r.Name FROM Picklist_Library__c WHERE Id IN: planCodeIds];
                branchNamesList.addAll(getBranchNames(pickListLibrariesList));
                Map<String, Id> publicGroupNameByIdMap = getPublicGroupsMap(branchNamesList);
                Map<Id, PlanCode> planCodesMap = getPlanCodesMap(pickListLibrariesList, publicGroupNameByIdMap);
                Map<String, Branch> branchesMap = getBranchesMap(branchNamesList, publicGroupNameByIdMap);
                Map<Id, Map<Id, sObject>> sharedUserIdsByRecordIdMap = getSharedUserIdsByRecordIdMap(sObjectRecordsList);
    
                for (sObject record : recordsList) {
                    // PLAN CODE
                    if (!String.isBlank(sharingSetting.PlanCodeField__c) && planCodesMap.containsKey((Id)record.get(sharingSetting.PlanCodeField__c))) {
                        PlanCode planCode = planCodesMap.get((Id)record.get(sharingSetting.PlanCodeField__c));
                        // create share record
                        if(record.get(sharingSetting.PlanCodeField__c) != null 
                            && triggerContext != SharingHelper.TriggerContext.RECORDDELETE 
                            && sharedUserIdsByRecordIdMap.containsKey((Id)record.get('Id'))){
                            // PUBLIC GROUP CHECK
                            if (planCode.planCodeGroupId != null && !sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(planCode.planCodeGroupId)) {
                                sObject shareRecord = createShareRecord(
                                    sharingSetting,
                                    planCode.planCodeGroupId,
                                    (Id)record.get('Id')
                                );
                                shareRecordsToInsert.add(shareRecord);
                                sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).put(planCode.planCodeGroupId, shareRecord);
                            }
                            // ROLE CHECK
                            if (planCode.planCodeBranchRoleId != null && !sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(planCode.planCodeBranchRoleId)) {
                                sObject shareRecord = createShareRecord(
                                    sharingSetting,
                                    planCode.planCodeBranchRoleId,
                                    (Id)record.get('Id')
                                );
                                shareRecordsToInsert.add(shareRecord);
                                sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).put(planCode.planCodeBranchRoleId,shareRecord);
                            }
                        }
                    }

                    System.debug('Map is '+JSON.serialize(branchesMap));
                    // BRANCHES
                    if (!String.isBlank(sharingSetting.BranchNameField__c) && record.get(sharingSetting.BranchNameField__c) != null && branchesMap.containsKey(String.valueOf(record.get(sharingSetting.BranchNameField__c)).replace(' ','_'))) {
                        Branch branch = branchesMap.get(String.valueOf(record.get(sharingSetting.BranchNameField__c)).replace(' ','_'));
                        if (triggerContext != SharingHelper.TriggerContext.RECORDDELETE && sharedUserIdsByRecordIdMap.containsKey((Id)record.get('Id'))) {
                            System.debug('Branch is '+branch);
                            System.debug('Boolean is '+!sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(branch.branchGroupId));
                            System.debug('Test is '+JSON.serialize(sharedUserIdsByRecordIdMap));
                            // PUBLIC GROUP CHECK
                            if (branch.branchGroupId != null && !sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(branch.branchGroupId)) {
                                sObject shareRecord = createShareRecord(
                                    sharingSetting,
                                    branch.branchGroupId,
                                    (Id)record.get('Id')
                                );
                                shareRecordsToInsert.add(shareRecord);
                                sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).put(branch.branchGroupId, shareRecord);
                            }
                            // ROLE CHECK
                            if (branch.banchRoleId != null && !sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(branch.banchRoleId)) {
                                sObject shareRecord = createShareRecord(
                                    sharingSetting,
                                    branch.banchRoleId,
                                    (Id)record.get('Id')
                                );
                                shareRecordsToInsert.add(shareRecord);
                                sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).put(branch.banchRoleId, shareRecord);
                            }
                        }
                    }
                }
                    
                // delete share record if there any changes
                if (triggerContext == SharingHelper.TriggerContext.RECORDUPDATE) {
                    for (sObject record : recordsList) {

                        // PLAN CODES
                        if (!String.isBlank(sharingSetting.PlanCodeField__c) && planCodesMap.containsKey((Id)oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.PlanCodeField__c))) {
                            PlanCode newPlanCode = planCodesMap.get((Id)record.get(sharingSetting.PlanCodeField__c));
                            PlanCode oldPlanCode = planCodesMap.get((Id)oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.PlanCodeField__c));
                            if ((record.get(sharingSetting.PlanCodeField__c) != oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.PlanCodeField__c))
                                && sharedUserIdsByRecordIdMap.containsKey((Id)record.get('Id'))) {
                                // PUBLIC GROUP CHECK
                                if (newPlanCode != null && oldPlanCode != null && newPlanCode.planCodeGroupId != oldPlanCode.planCodeGroupId && sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(oldPlanCode.planCodeGroupId)) {
                                    shareRecordsToDelete.add(sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).get(oldPlanCode.planCodeGroupId));
                                }
                                // ROLE CHECK
                                if (newPlanCode != null && oldPlanCode != null && newPlanCode.planCodeBranchRoleId != oldPlanCode.planCodeBranchRoleId && sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(oldPlanCode.planCodeBranchRoleId)) {
                                    shareRecordsToDelete.add(sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).get(oldPlanCode.planCodeBranchRoleId));
                                }
                            }
                        }
                        
                        // BRANCHES
                        if (!String.isBlank(sharingSetting.BranchNameField__c) && oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c) != null && branchesMap.containsKey(String.valueOf(oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c)).replace(' ','_'))) {
                            Branch newBranchCode = record.get(sharingSetting.BranchNameField__c) != null && branchesMap.containsKey(String.valueOf(record.get(sharingSetting.BranchNameField__c)).replace(' ','_')) ? branchesMap.get(String.valueOf(record.get(sharingSetting.BranchNameField__c)).replace(' ','_')) : null;
                            Branch oldBranchCode = branchesMap.get(String.valueOf(oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c)).replace(' ','_'));
                            if ((record.get(sharingSetting.BranchNameField__c) != oldRecordsMap.get((Id)record.get('Id')).get(sharingSetting.BranchNameField__c))
                                && sharedUserIdsByRecordIdMap.containsKey((Id)record.get('Id'))) {
                                // PUBLIC GROUP CHECK
                                if (oldBranchCode.branchGroupId != null&& sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(oldBranchCode.branchGroupId)) {
                                    shareRecordsToDelete.add(sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).get(oldBranchCode.branchGroupId));
                                }
                                // ROLE CHECK
                                if (oldBranchCode.banchRoleId != null && sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).containsKey(oldBranchCode.banchRoleId)) {
                                    shareRecordsToDelete.add(sharedUserIdsByRecordIdMap.get((Id)record.get('Id')).get(oldBranchCode.banchRoleId));
                                }
                            }
                        }
                    }
                }
                if (!shareRecordsToInsert.isEmpty()) insert shareRecordsToInsert;
                if (!shareRecordsToDelete.isEmpty()) delete shareRecordsToDelete;
            }
        }
    }

    /**
    * @description Method to get sharing setting
    **/
    public static SharingSetting__mdt getSharingSetting(String sObjectName) {
        List<SharingSetting__mdt> sharingSettingsList = [SELECT Id, AccessLevel__c, ObjectName__c, ParentRecordField__c, SharingReason__c, 
            PlanCodeField__c, Recalculate__c, BranchNameField__c  FROM SharingSetting__mdt WHERE ObjectName__c =: sObjectName];
        return !sharingSettingsList.isEmpty() ? sharingSettingsList[0] : null;
    }

    /**
    * @description Method to get branch names
    **/
    public static Set<String> getBranchNames(List<Picklist_Library__c> pickListLibrariesList) {
        Set<String> branchNamesList = new Set<String>();
        for (Picklist_Library__c picklistLibrary : pickListLibrariesList) {
            if (picklistLibrary.Branch__c != null) {
                branchNamesList.add(picklistLibrary.Branch__r.Name.replace(' ','_'));
                branchNamesList.add('Branch_'+picklistLibrary.Branch__r.Name.replace(' ','_'));
            }
        }
        return branchNamesList;
    }

    /**
    * @description Method to get plan codes map
    **/
    public static Map<Id, PlanCode> getPlanCodesMap(List<Picklist_Library__c> pickListLibrariesList, Map<String, Id> publicGroupNameByIdMap) {
        Map<Id, PlanCode> planCodesMap = new Map<Id, PlanCode>();
        for (Picklist_Library__c picklistLibrary : pickListLibrariesList) {
            PlanCode plancode = new PlanCode(picklistLibrary.Id);
            if (picklistLibrary.Branch__c != null && publicGroupNameByIdMap.containsKey(picklistLibrary.Branch__r.Name.replace(' ','_'))) {
                plancode.setPlanCodeGroupId(publicGroupNameByIdMap.get(picklistLibrary.Branch__r.Name.replace(' ','_')));
            }
            if (picklistLibrary.Branch__c != null && publicGroupNameByIdMap.containsKey('Branch_'+picklistLibrary.Branch__r.Name.replace(' ','_'))) {
                plancode.setPlanCodeBranchRoleId(publicGroupNameByIdMap.get('Branch_'+picklistLibrary.Branch__r.Name.replace(' ','_')));
            }
            planCodesMap.put(picklistLibrary.Id, plancode);
        }
        return planCodesMap;
    }

    /**
    * @description Method to get branch map
    **/
    public static Map<String, Branch> getBranchesMap(Set<String> branchNamesList, Map<String, Id> publicGroupNameByIdMap) {
        Map<String, Branch> branchesMap = new Map<String, Branch>();
        for (String branchName : branchNamesList) {
            Branch branch = new Branch(branchName);
            if (publicGroupNameByIdMap.containsKey(branchName.replace(' ','_'))) {
                branch.setBranchGroupId(publicGroupNameByIdMap.get(branchName.replace(' ','_')));
            }
            if (publicGroupNameByIdMap.containsKey('Branch_'+branchName.replace(' ','_'))) {
                branch.setBranchRoleId(publicGroupNameByIdMap.get('Branch_'+branchName.replace(' ','_')));
            }
            branchesMap.put(branchName, branch);
        }
        return branchesMap;
    }

    /**
    * @description Method to get soql query
    **/
    public static Map<String, Id> getPublicGroupsMap(Set<String> branchNames) {
        Map<String, Id> publicGroupNameByIdMap = new Map<String, Id>();
        List<Group> publicGroupsList = [SELECT Id, DeveloperName FROM Group WHERE (DeveloperName IN: branchNames AND Type = 'Regular') OR (DeveloperName IN: branchNames AND Type = 'Role')];
        for (Group publicGroup : publicGroupsList) {
            publicGroupNameByIdMap.put(publicGroup.DeveloperName, publicGroup.Id);
        }
        return publicGroupNameByIdMap;
    }

    /**
    * @description Method to get soql query
    **/
    public static String getSoqlQuery(SharingSetting__mdt sharingSetting) {
        return 'SELECT Id, (SELECT Id, UserOrGroupId FROM Shares WHERE RowCause = \''+sharingSetting.SharingReason__c+'\') FROM '+sharingSetting.ObjectName__c+' WHERE Id IN: recordIds';
    }

    /**
    * @description Method to get map of current share record ids
    **/
    public static Map<Id, Map<Id, sObject>> getSharedUserIdsByRecordIdMap(List<sObject> recordsList) {
        Map<Id, Map<Id, sObject>> sharedUserIdsByRecordIdMap = new Map<Id, Map<Id, sObject>>();
        for (sObject record : recordsList) {
            Id recordId = (Id)record.get('Id');
            sharedUserIdsByRecordIdMap.put(recordId, new Map<Id, sObject>());
            if (record.getSObjects('Shares') != null) {
                for (sObject shareRecord : record.getSObjects('Shares')) {
                    Id userId = (Id)shareRecord.get('UserOrGroupId');
                    sharedUserIdsByRecordIdMap.get(recordId).put(userId,shareRecord);
                }
            }
        }
        return sharedUserIdsByRecordIdMap;
    }

    /**
    * @description Method to create sharing
    **/
    public static sObject createShareRecord(SharingSetting__mdt sharingSetting,Id userId,Id recordId) {
        String shareObjectName = !sharingSetting.ObjectName__c.endsWith('__c') ? sharingSetting.ObjectName__c+'Share' : sharingSetting.ObjectName__c.replace('__c','__Share');
        sObject shareRecord = Schema.getGlobalDescribe().get(shareObjectName).newSObject();
        shareRecord.put((!String.isBlank(sharingSetting.ParentRecordField__c) ? sharingSetting.ParentRecordField__c : 'ParentId'),recordId);
        shareRecord.put('UserOrGroupId',userId);
        shareRecord.put((shareObjectName.endsWith('__Share') ? 'AccessLevel' : sharingSetting.ObjectName__c+'AccessLevel'),sharingSetting.AccessLevel__c);
        shareRecord.put('RowCause',sharingSetting.SharingReason__c);
        if (sharingSetting.ObjectName__c == Account.sObjectType.getDescribe().getName()) {
            shareRecord.put('CaseAccessLevel','None');
            shareRecord.put('ContactAccessLevel','None');
            shareRecord.put('OpportunityAccessLevel','None');
        }
        return shareRecord;
    }

    /**
    * @description Wrapper class for plan code
    **/
    public class PlanCode {
        public Id planCodeId;
        public Id planCodeGroupId;
        public Id planCodeBranchRoleId;

        /**
        * @description Constructor
        **/
        public PlanCode(Id planCodeId) {
            this.planCodeId = planCodeId;
            this.planCodeGroupId = null;
            this.planCodeBranchRoleId = null;
        }

        /**
        * @description Method to set group id
        **/
        public void setPlanCodeGroupId(Id planCodeGroupId) {
            this.planCodeGroupId = planCodeGroupId;
        }

        /**
        * @description Method to set branch role id
        **/
        public void setPlanCodeBranchRoleId(Id planCodeBranchRoleId) {
            this.planCodeBranchRoleId = planCodeBranchRoleId;
        }
    }

    /**
    * @description Wrapper class for Branch
    **/
    public class Branch {
        public String branchName;
        public Id branchGroupId;
        public Id banchRoleId;

        /**
        * @description Constructor
        **/
        public Branch(String branchName) {
            this.branchName = branchName;
            this.branchGroupId = null;
            this.banchRoleId = null;
        }

        /**
        * @description Method to set branch group id
        **/
        public void setBranchGroupId(Id branchGroupId) {
            this.branchGroupId = branchGroupId;
        }

        /**
        * @description Method to set branch role id
        **/
        public void setBranchRoleId(Id banchRoleId) {
            this.banchRoleId = banchRoleId;
        }
    }
}