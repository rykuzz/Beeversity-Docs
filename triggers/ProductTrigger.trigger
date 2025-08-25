trigger ProductTrigger on Product2 (before insert, before update, after insert, after update) {
    ProductTriggerHandler.handleTrigger();
}