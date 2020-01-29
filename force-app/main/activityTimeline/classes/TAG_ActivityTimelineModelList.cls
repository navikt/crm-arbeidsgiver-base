public with sharing class TAG_ActivityTimelineModelList {

	@AuraEnabled public String name { get; set; }
	@AuraEnabled public String id { get; set; }
	@AuraEnabled public List<TAG_ActivityTimelineModel> models { get; set; }
	@AuraEnabled public Boolean allObjectsLoaded { get; set; }

	public TAG_ActivityTimelineModelList( String id, String name, List<TAG_ActivityTimelineModel> models, Boolean allObjectsLoaded ) {
		this.id = id;
		this.name = name;
		this.models = models;
		this.allObjectsLoaded = allObjectsLoaded;
	}
}
