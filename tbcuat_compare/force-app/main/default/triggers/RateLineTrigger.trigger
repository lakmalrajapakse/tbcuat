trigger RateLineTrigger on sirenum__Rate_Line__c(before insert, after insert, before update, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            RateLineTriggerHandler.onBeforeInsertAll(Trigger.new);
        }
        when BEFORE_UPDATE {
            RateLineTriggerHandler.onBeforeUpdateAll(Trigger.oldMap, Trigger.newMap);
        }
        when AFTER_INSERT {
            RateLineTriggerHandler.onAfterInsertAll(Trigger.new);
        }
        when AFTER_UPDATE {
            RateLineTriggerHandler.onAfterUpdateAll(Trigger.oldMap, Trigger.newMap);
        }
    }
}