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

	public static List<Process_SendEmail.Request> removeInvalidRequests( List<Process_SendEmail.Request> requests ) {

		List<Process_SendEmail.Request> filteredRequests = new List<Process_SendEmail.Request>();

		for ( Process_SendEmail.Request req : requests ) {
			if ( req.recipientContact != null && req.relatedToId != null && req.emailTemplateName != null ) {
				if ( req.recipientContact.Email != null ) {
					filteredRequests.add( req );
				}
			}
		}

		return filteredRequests;
	}

	public static List<Messaging.SingleEmailMessage> requestToSingleEmailMessage( List<Process_SendEmail.Request> requests, Map<String, Id> templateMap, Id orgWideEmailId ) {
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

		for ( Process_SendEmail.Request req : requests ) {
			System.debug( 'for loop' );
			Id templateId = templateMap.containsKey( req.emailTemplateName ) ? templateMap.get( req.emailTemplateName ) : null;

			if ( templateId != null ) {

				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

				if ( orgWideEmailId != null && req.useDoNotReply ) { message.setOrgWideEmailAddressId( orgWideEmailId ); }
				if ( templateId != null ) { message.setTemplateId( templateId ); }
				message.setWhatId( req.relatedToId );
				message.setTargetObjectId( req.recipientContact.Id );
				message.setSaveAsActivity( true );

				messages.add( message );
			}
		}

		return messages;
	}
}
