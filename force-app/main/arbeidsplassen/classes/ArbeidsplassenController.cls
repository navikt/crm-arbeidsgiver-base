public with sharing class ArbeidsplassenController {

	@AuraEnabled(cacheable = true)
	public static ArbeidsplassenWrapperModel getData( String recordId ) {

		List<Account> acc = [SELECT INT_OrganizationNumber__c FROM Account WHERE Id = : recordId LIMIT 1];
		if ( acc.size() == 0 )  {
			return null;
		}

		HttpResponse response = ArbeidsplassenController.doCallout( acc[0].INT_OrganizationNumber__c );
		ArbeidsplassenRawModel model = ArbeidsplassenRawModel.parse( response.getBody() );

		List<ArbeidsplassenViewModel> viewModels = new List<ArbeidsplassenViewModel>();
		for ( ArbeidsplassenRawModel.Content content : model.content ) {
			viewModels.add( new ArbeidsplassenViewModel( content ) );
		}

		ArbeidsplassenWrapperModel wrapper = new ArbeidsplassenWrapperModel( model.totalElements, viewModels );

		return wrapper;
	}

	public static HttpResponse doCallout( String orgNumber ) {

		List<AccessToken__c> accessTokens = [SELECT Token__c FROM AccessToken__c WHERE Name__c = 'arbeidsplassen' LIMIT 1];
		String accesToken = accessTokens.size() == 1 ? accessTokens[0].Token__c : '';

		HttpRequest req = new HttpRequest();
		req.setEndpoint( 'https://arbeidsplassen.nav.no/public-feed/api/v1/ads?orgnr=' + orgNumber );
		req.setMethod( 'GET' );
		req.setHeader( 'Content-Type', 'application/json' );
		req.setHeader( 'Authorization', accesToken );
		Http h = new Http();
		HttpResponse res = h.send( req );

		return res;
	}
}
