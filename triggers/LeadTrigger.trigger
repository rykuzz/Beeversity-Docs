trigger LeadTrigger on Lead (before insert, after update) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        LeadTriggerHandler.setInitialStatusAndRating(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.processLeads(Trigger.new, Trigger.oldMap);
    }
}