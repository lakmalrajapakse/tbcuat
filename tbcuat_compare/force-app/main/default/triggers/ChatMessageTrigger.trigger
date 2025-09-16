trigger ChatMessageTrigger on b3o__Chat_Message__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new ChatMessageTriggerHandler().run();
}