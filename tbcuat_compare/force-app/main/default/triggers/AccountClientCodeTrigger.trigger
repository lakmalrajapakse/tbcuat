trigger AccountClientCodeTrigger on Account (before insert) {

    if (Trigger.isBefore && Trigger.isInsert){
        ClientCodeTriggerHandler.setClientCode(Trigger.new);
    }

}