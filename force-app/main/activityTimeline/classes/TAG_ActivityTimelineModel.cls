public with sharing class TAG_ActivityTimelineModel {

	@AuraEnabled public TAG_ActivityTimeline__mdt config { get; set; } // TODO remove
	@AuraEnabled public SObject sObj { get; set; } // TODO remove

	@AuraEnabled public theme theme { get; set; }
	@AuraEnabled public record record { get; set; }

	public TAG_ActivityTimelineModel( TAG_ActivityTimeline__mdt config, SObject sObj, String lang ) {

		this.config = config; // todo remove
		this.sObj = sObj; // todo remove

		theme theme = new theme();
		record record = new record();

		record.recordId = sObj.Id;

		record.sObjectKind = config.SObjectChild__c;
		record.type = config.SObjectTypeValue__c;
		record.title = (String) sObj.get( config.SObjectTitle__c );
		record.dateValueDb = (Datetime) sObj.get( config.SObjectDateField__c );

		record.sObj = sObj; // todo remove?

		theme.icon = config.SLDS_Icon__c;
		theme.sldsTimelineItem = config.SLDS_Timeline_Item__c;

		if ( config.SObjectAssigneeId__c != null ) {
			record.assigneeId = (Id) sObj.get( config.SObjectAssigneeId__c );
			record.assignee = getOwnerName( record.assigneeId );
		}
		if ( config.SObjectRelatedUserId__c != null ) {
			record.relatedUserId = (Id) sObj.get( config.SObjectRelatedUserId__c );
			record.relatedUser = getContactName( record.relatedUserId );
		}

		record.subtitle = lang == 'Norsk' ? config.SubtitleNorwegian__c : config.SubtitleEnglish__c;

		this.theme = theme;
		this.record = record;
	}

	public class theme {
		@AuraEnabled public String icon;
		@AuraEnabled public String sldsTimelineItem;
	}

	public class record {
		@AuraEnabled public Id recordId;
		@AuraEnabled public String sObjectKind;
		@AuraEnabled public String type;
		@AuraEnabled public String title;
		@AuraEnabled public Datetime dateValueDb;
		@AuraEnabled public String dateValue;
		@AuraEnabled public SObject sObj;

		@AuraEnabled public String assignee;
		@AuraEnabled public Id assigneeId;
		@AuraEnabled public String relatedUser;
		@AuraEnabled public Id relatedUserId;
		@AuraEnabled public String subtitle;
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

		return Label.ActTime_Unknown;
	}

	public static String getContactName( Id contactId ) {

		List<Contact> u = [SELECT Name FROM Contact WHERE Id = : contactId LIMIT 1];
		if ( !u.isEmpty() ) {
			return u[0].Name;
		}


		return Label.ActTime_Unknown.toLowerCase();
	}
}




