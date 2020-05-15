trigger ArenaActivityTrigger on ArenaActivity__c ( before insert, before update, before delete, after insert, after update, after delete, after undelete ) {
	MyTriggers.run();
}
