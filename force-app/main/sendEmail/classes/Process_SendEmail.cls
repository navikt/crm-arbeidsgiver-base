global without sharing class Process_SendEmail {

	@InvocableMethod(label = 'Log email sent as EmailMessage')
	public static void sendEmail( List<Request> requests ) {

		List<OrgWideEmailAddress> orgWideAdresses = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'do-not-reply@nav.no' LIMIT 1];
		Id orgWideEmailId = orgWideAdresses.size() == 1 ? orgWideAdresses[0].Id : null;
		Map<String, Id> templateMap = Process_SendEmailHelper.fetMapOfEmailTemplates( requests );

		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

		for ( Request req : requests ) {

			Id templateId = templateMap.containsKey( req.emailTemplateName ) ? templateMap.get( req.emailTemplateName ) : null;
			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

			if ( orgWideEmailId != null ) { message.setOrgWideEmailAddressId( orgWideEmailId ); }
			if ( templateId != null ) { message.setTemplateId( templateId ); }
			message.setWhatId( req.relatedTo );
			message.setTargetObjectId( req.recipientContactId );
			messages.add( message );
		}

		Messaging.SendEmailResult[] results = Messaging.sendEmail( messages );
	}

	global class Request {

		@InvocableVariable(required = true)
		global ID recipientContactId;

		@InvocableVariable(required = true)
		global String relatedTo;

		@InvocableVariable(required = true)
		global String emailTemplateName;
	}
}
