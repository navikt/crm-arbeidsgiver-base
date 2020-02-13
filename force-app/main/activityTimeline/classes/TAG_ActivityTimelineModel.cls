global with sharing class TAG_ActivityTimelineModel implements Comparable {

	@AuraEnabled public TAG_ActivityTimeline__mdt config { get; set; } // TODO delete

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


	public TAG_ActivityTimelineModel( TAG_ActivityTimeline__mdt config, SObject sObj, String lang ) {

		this.config = config;

		Theme theme = new Theme();
		Record record = new Record();

		record.recordId = sObj.Id;

		record.sObjectKind = config.SObjectChild__c;
		record.type = config.SObjectTypeValue__c;
		record.title = (String) sObj.get( config.SObjectTitle__c );
		record.dateValueDb = (Datetime) sObj.get( config.SObjectDateField__c );
		record.isDate = config.SObjectDateFieldIsDate__c;

		if ( config.SObjectChild__c == 'Event' ) {
			record.isDate = (Boolean) sObj.get( 'IsAllDayEvent' );
			record.durationInMinute = (Integer) sObj.get( 'DurationInMinutes' );

			if ( !record.isDate ) {
				record.dateValueDb = (Datetime) sObj.get( 'ActivityDateTime' );
			}
		}

		theme.icon = config.SLDS_Icon__c;
		theme.sldsTimelineItemColor = config.SLDS_Timeline_Color__c;

		record.overdue = false;
		if ( record.sObjectKind == 'Task' ) {

			if ( sObj.get( 'Status' ) != 'Completed' && record.dateValueDb < Date.today() ) {
				record.overdue = true;
			}
		}

		if ( config.SObjectAssigneeId__c != null ) {
			record.assigneeId = (Id) sObj.get( config.SObjectAssigneeId__c );
		} if ( config.SObjectRelatedUserId__c != null ) {
			record.relatedUserId = (Id) sObj.get( config.SObjectRelatedUserId__c );
		}

		this.theme = theme;
		this.record = record;
	}
}