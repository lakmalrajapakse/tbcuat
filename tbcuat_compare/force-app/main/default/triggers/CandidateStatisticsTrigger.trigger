trigger CandidateStatisticsTrigger on TR1__Candidate_Summary__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //Trigger handler implementation to handle every event
    new CandidateStatisticsTriggerHandler().run();
}