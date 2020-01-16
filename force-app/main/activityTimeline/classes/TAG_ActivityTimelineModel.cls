public with sharing class TAG_ActivityTimelineModel {

	@AuraEnabled public TAG_ActivityTimeline__mdt config { get; set; } // TODO remove
	@AuraEnabled public SObject sObj { get; set; } // TODO remove

	@AuraEnabled public theme theme { get; set; }
	@AuraEnabled public record record { get; set; }

	public TAG_ActivityTimelineModel( TAG_ActivityTimeline__mdt config, SObject sObj ) {

		this.config = config;
		this.sObj = sObj;

		theme theme = new theme();
		record record = new record();

		record.recordId = sObj.Id;
		record.sObjectType = config.SObjectChild__c;
		record.title = (String) sObj.get( config.SObjectTitle__c );
		record.person = getOwnerName( (Id) sObj.get( 'CreatedById' ) );
		record.subtitle = record.person + ' created this';
		record.dateValueDb = (Datetime) sObj.get( config.SObjectDateField__c );
		record.sObj = sObj;

		theme.icon = config.Icon__c;
		theme.sldsTimelineItem = config.SLDS_Timeline_Item__c;

		if ( record.sObjectType == 'Task' ) {
			record.type = (String) sObj.get( 'Type' );
			if ( record.type == 'Call' ) {
				theme.icon = 'standard:log_a_call';
				theme.sldsTimelineItem = 'slds-timeline__item_call';
			}
		}

		this.theme = theme;
		this.record = record;
	}

	public class theme {
		@AuraEnabled public String icon;
		@AuraEnabled public String sldsTimelineItem;
	}

	public class record {
		@AuraEnabled public Id recordId;
		@AuraEnabled public String sObjectType;
		@AuraEnabled public String title;
		@AuraEnabled public String type;
		@AuraEnabled public Datetime dateValueDb;
		@AuraEnabled public String dateValue;
		@AuraEnabled public SObject sObj;


		@AuraEnabled public String subtitle;
		@AuraEnabled public String person;
	}

	public static String getOwnerName( Id ownerId ) {
		if ( ownerId == UserInfo.getUserId() ) {
			return Label.ActTime_You;
		} else {
			List<User> u = [SELECT Name FROM User WHERE Id = : ownerId LIMIT 1];
			if ( !u.isEmpty() ) {
				return u[0].Name;
			}
		}

		return 'Unknown';
	}
}




