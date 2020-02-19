global with sharing class TAG_ActivityTimelineModel implements Comparable {

	@AuraEnabled public TAG_ActivityTimelineParent__mdt config { get; set; } // TODO delete

	@AuraEnabled public Theme theme { get; set; }
	@AuraEnabled public Record record { get; set; }

	public Boolean descending = true;

	public class Theme {
		@AuraEnabled public String icon;
		@AuraEnabled public String sldsTimelineItemColor;
	}

	public class Record {
		@AuraEnabled public Id recordId;
		@AuraEnabled public String sObjectKind;
		@AuraEnabled public String type;
		@AuraEnabled public String title;

		@AuraEnabled public Datetime dateValueDb;
		@AuraEnabled public String dateValue;
		@AuraEnabled public Boolean isDate;
		@AuraEnabled public Integer durationInMinute;

		@AuraEnabled public String assignee;
		@AuraEnabled public Id assigneeId;
		@AuraEnabled public String relatedUser;
		@AuraEnabled public Id relatedUserId;
		@AuraEnabled public String subtitle;

		@AuraEnabled public Boolean overdue;
		@AuraEnabled public Boolean lastElement;
	}

	// sorting algorithm
	global Integer compareTo( Object compareTo ) {
		TAG_ActivityTimelineModel compare = (TAG_ActivityTimelineModel) compareTo;
		if ( record.dateValueDb == compare.record.dateValueDb ) { return 0; }
		if ( descending && record.dateValueDb < compare.record.dateValueDb ) { return 1; } // sort descending, newest first
		if ( !descending && record.dateValueDb > compare.record.dateValueDb ) { return 1; } // sort ascending, oldest first (technically, record in 2 days is "older" than one in 4 days)

		return -1;
	}


	public TAG_ActivityTimelineModel( TAG_ActivityTimelineParent__mdt config, SObject sObj, String lang ) {

		this.config =                       config;

		Theme theme =                       new Theme();
		Record record =                     new Record();

		record.recordId =                   sObj.Id;

		record.sObjectKind =                config.SObjectChild__c;
		record.type =                       config.Activity_Timeline_Child__r.SObjectTypeValue__c;
		record.isDate =                     getIsDate( config, sObj, record );
		record.dateValueDb =                getDateValue( config, sObj, record );
		record.overdue =                    getIsOverdue( config, sObj, record );
		record.title =             (String) get( sObj, config.Activity_Timeline_Child__r.SObjectTitle__c );
		record.durationInMinute = (Integer) get( sObj, 'DurationInMinutes' );

		theme.icon =                        config.Activity_Timeline_Child__r.SLDS_Icon__c;
		theme.sldsTimelineItemColor =       config.Activity_Timeline_Child__r.SLDS_Timeline_Color__c;

		record.assigneeId =                 config.SObjectAssigneeId__c != null ? (Id) get( sObj, config.SObjectAssigneeId__c ) : null;
		record.relatedUserId =              config.Activity_Timeline_Child__r.SObjectRelatedUserId__c != null ? (Id) get( sObj, config.Activity_Timeline_Child__r.SObjectRelatedUserId__c ) : null;

		this.theme =                        theme;
		this.record =                       record;
	}

	public static Datetime getDateValue( TAG_ActivityTimelineParent__mdt config, SObject sObj, Record record ) {

		Datetime dateValueDb = (Datetime) get( sObj, config.Activity_Timeline_Child__r.SObjectDateField__c );

		if ( dateValueDb == null && record.sObjectKind == 'Task' ) {        dateValueDb = (Datetime) get( sObj, 'CreatedDate' ); }
		else if ( config.SObjectChild__c == 'Event' &&  !record.isDate ) {  dateValueDb = (Datetime) get( sObj, 'ActivityDateTime' ); }

		return dateValueDb;
	}

	public static Boolean getIsDate( TAG_ActivityTimelineParent__mdt config, SObject sObj, Record record ) {

		Boolean isDate = config.Activity_Timeline_Child__r.SObjectDateFieldIsDate__c;
		if ( config.SObjectChild__c == 'Event' ) { isDate = (Boolean) get( sObj, 'IsAllDayEvent' ); }
		else if ( config.SObjectChild__c == 'Task' && (Datetime) get( sObj, config.Activity_Timeline_Child__r.SObjectDateField__c ) == null ) { isDate = false; }

		return isDate;
	}

	public static Boolean getIsOverdue( TAG_ActivityTimelineParent__mdt config, SObject sObj, Record record ) {

		Boolean isOVerdue = false;

		if ( record.sObjectKind == 'Task' && record.isDate ) {
			if ( get( sObj, 'Status' ) != 'Completed' && record.dateValueDb < Date.today() ) { isOverdue = true; }
		}
		else if ( record.sObjectKind == 'Task' && !record.isDate ) {
			if ( get( sObj, 'Status' ) != 'Completed' && record.dateValueDb < System.now() ) { isOverdue = true; }
		}

		return isOverdue;
	}

	public static Object get( SObject sObj, String field ) {
		try {
			return sObj.get( field );
		} catch ( Exception e ) {
			return null;
		}
	}
}