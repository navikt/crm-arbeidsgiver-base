/*
   Can use either this class in a process or Trigger_SendEmail as a trigger
 */

global  class Trigger_SendEmailTmpLayoff extends MyTriggers {

	global override void onAfterInsert() {

		Set<Id> contactIds = new Set<Id>();
		for ( TemporaryLayoff__c tl : (List<TemporaryLayoff__c>) records ) {
			contactIds.add( tl.Contact__c );
		}

		Map<Id, Contact> contacts = new Map<Id, Contact> ( [SELECT Id, Email FROM Contact WHERE Id IN: contactIds] );

		List<Process_SendEmail.Request> requests = new List<Process_SendEmail.Request>();
		for ( TemporaryLayoff__c tl : (List<TemporaryLayoff__c>) records ) {
			Process_SendEmail.Request request = new Process_SendEmail.Request();
			request.emailTemplateName = 'tempLayoffReceiptSubsidiary';
			request.recipientContact = contacts.containsKey( tl.Contact__c ) ? contacts.get( tl.Contact__c ) : null;
			request.useDoNotReply = true;
			request.relatedToId = tl.Id;
			requests.add( request );
		}

		Process_SendEmail.sendEmail( requests );
	}
}