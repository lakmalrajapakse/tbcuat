trigger AttachmentTrigger_FB on Attachment (after insert) {
     if(Boolean.valueOf(Label.Enable_Attachment_Trigger)){
        if(trigger.isAfter && trigger.isInsert){
            AttachmentTriggerHandler_FB.onAfterInsert(trigger.new);
        }
    }

}