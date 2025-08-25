trigger OpportunityTrigger on Opportunity (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}