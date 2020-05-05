public without sharing class Process_SendEmailHelper {

	public static Map<String, Id> getMapOfEmailTemplates( List<Process_SendEmail.Request> requests ) {

		Map<String, Id> templateMap = new Map<String, Id>();
		Set<String> templateNames = new Set<String>();

		for ( Process_SendEmail.Request req : requests ) {
			templateNames.add( req.emailTemplateName );
		}

		List<EmailTemplate> emailTemplates = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : templateNames];
		for ( EmailTemplate et : emailTemplates ) {
			templateMap.put( et.Name, et.Id );
		}

		return templateMap;
	}
}
