public with sharing class TAG_ActivityTimelineModel {

	@AuraEnabled public TAG_ActivityTimeline__mdt config { get; set; }
	@AuraEnabled public SObject sObj { get; set; }

	public TAG_ActivityTimelineModel( TAG_ActivityTimeline__mdt config, SObject sObj ) {
		this.config = config;
		this.sObj = sObj;
	}
}
