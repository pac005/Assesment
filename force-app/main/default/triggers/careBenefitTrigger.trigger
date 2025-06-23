trigger careBenefitTrigger on CareBenefitVerifyRequest (after insert) {
    //enqueue job when a carebenefit record/records are created
    if(trigger.isAfter && trigger.isInsert)
    {
        System.enqueueJob(new CareBenefitCallout(trigger.new));
    }
}