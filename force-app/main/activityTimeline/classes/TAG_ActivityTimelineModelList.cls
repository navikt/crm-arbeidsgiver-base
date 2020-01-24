public with sharing class TAG_ActivityTimelineModelList {

	@AuraEnabled public String name { get; set; }
	@AuraEnabled public String id { get; set; }
	@AuraEnabled public List<TAG_ActivityTimelineModel> models { get; set; }

	public TAG_ActivityTimelineModelList( String name, String id, List<TAG_ActivityTimelineModel> models ) {
		this.name = name;
		this.id = id;
		this.models = models;
	}
}
