trigger BreakDefinitionTrigger on sirenum__Break_definition__c (after insert, after update, after delete) {
    //Trigger handler implementation to handle every event
    new BreakDefinitionTriggerHandler().run();
}