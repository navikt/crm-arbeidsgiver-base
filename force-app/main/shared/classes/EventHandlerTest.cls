@isTest
private without sharing class EventHandlerTest {

	@testSetup
	private static void setup() {
        TAG_TestDataFactory.assignPermissionSet( 'accountTypeHandler@nav.test', 'ManageAccounts' );
        }
    
    @isTest
	private static void testOnAfterInsert() {

        List<Account> acc = TAG_TestDataFactory.createAccounts( 1 );
        Contact c = new Contact( TAG_Informed__c = true, LastName = 'test' );
        
        Test.StartTest();
        List<Event> eventShadowsData = new List<Event>();

        for(Integer i=0; i < 200; i++) {
            eventShadowsData.add( new Event(WhatId = acc[0].Id, WhoId = c.Id, TAG_NoPersonInformation__c = true, Subject = 'testSubject', TAG_ActivityType__c = 'Rekruttere og inkludere', StartDateTime = System.Now(), EndDateTime = System.Now().addHours(1)));
        }        
        insert eventShadowsData;
        Test.StopTest();

        List<EventShadow__c> es = [SELECT Id, SH_EventId__c FROM EventShadow__c];
        Integer EventShadowCount = es.size() ;

		System.assertEquals( 200, EventShadowCount );

    }
    
    @isTest
	private static void testOnAfterUpdate() {

        List<Account> acc = TAG_TestDataFactory.createAccounts( 1 );
        Contact c = new Contact( TAG_Informed__c = true, LastName = 'test' );
        Event e = new Event( WhatId = acc[0].Id, WhoId = c.Id, TAG_NoPersonInformation__c = true, Subject = 'testSubject', TAG_ActivityType__c = 'Rekruttere og inkludere', StartDateTime = System.Now(), EndDateTime = System.Now().addHours(1) );
        insert e;
        
        Test.StartTest();
        e.Subject = 'Subject Updated';
        update e;
        Test.StopTest();

        List<EventShadow__c> es = [SELECT Id, SH_EventId__c, SH_Subject__c FROM EventShadow__c];
        Integer EventShadowCount = es.size() ;

		System.assertEquals( 1, EventShadowCount );
        System.assertEquals( e.Id, es[0].SH_EventId__c );
        System.assertEquals( 'Subject Updated', es[0].SH_Subject__c );

    }
    
    @isTest
	private static void testOnAfterDelete() {

        List<Account> acc = TAG_TestDataFactory.createAccounts( 1 );
        Contact c = new Contact( TAG_Informed__c = true, LastName = 'test' );
        Event e = new Event( WhatId = acc[0].Id, WhoId = c.Id, TAG_NoPersonInformation__c = true, Subject = 'testSubject', TAG_ActivityType__c = 'Rekruttere og inkludere', StartDateTime = System.Now(), EndDateTime = System.Now().addHours(1) );
        insert e;

        EventShadow__c eu = new EventShadow__c( SH_EventId__c = e.id );
        upsert eu SH_EventId__c;

        List<EventShadow__c> es = [SELECT Id FROM EventShadow__c];
        Integer EventShadowCount = es.size() ;
        
        System.assertEquals( 1, EventShadowCount );

        Test.StartTest();
            delete e;
        Test.StopTest();

        List<EventShadow__c> esUpd = [SELECT Id FROM EventShadow__c];
        Integer EventShadowCountUpd = esUpd.size() ;

		System.assertEquals( 0, EventShadowCountUpd );

    }
    
    @isTest
	private static void testOnAfterUndelete() {

        List<Account> acc = TAG_TestDataFactory.createAccounts( 1 );
        Contact c = new Contact( TAG_Informed__c = true, LastName = 'test' );
        Event e = new Event( WhatId = acc[0].Id, WhoId = c.Id, TAG_NoPersonInformation__c = true, Subject = 'testSubject', TAG_ActivityType__c = 'Rekruttere og inkludere', StartDateTime = System.Now(), EndDateTime = System.Now().addHours(1) );
        insert e;
        Id eventId = e.Id;

        List<EventShadow__c> es = [SELECT Id FROM EventShadow__c];
        Integer EventShadowCount = es.size();
        System.assertEquals( 1, EventShadowCount );

        Test.StartTest();
        delete e;
        Event eu = [SELECT Id FROM Event WHERE Id = :eventId ALL ROWS];
        undelete eu;
        Test.StopTest();
        
        List<EventShadow__c> esUnd = [SELECT Id FROM EventShadow__c];
        Integer EventShadowCountUnd = esUnd.size() ;

		System.assertEquals( 1, EventShadowCountUnd );

	}
}