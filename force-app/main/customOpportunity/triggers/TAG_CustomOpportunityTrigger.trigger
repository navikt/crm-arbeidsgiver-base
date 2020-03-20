/**
 * Created by hoen on 19.03.2020.
 */

trigger TAG_CustomOpportunityTrigger on CustomOpportunity__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    MyTriggers.run();
}