public with sharing class BankAccountHelper {
    // ------------------------------------------
    private static final string DEFAULT_ERROR_MESSAGE = 'Feil! Vennligst kontakt en administrator.';

    // ------------------------------------------
    public static BankAccountModel saveResults(ApiController apiCtrl) {
        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();

        System.debug('statusCode: ' + statusCode);
        System.debug('bodyString: ' + bodyString);
        System.debug('apiCtrl.getRequest(): ' + apiCtrl.getRequest());
        System.debug('apiCtrl.getResponse(): ' + apiCtrl.getResponse());

        BankAccountModel queryResult = new BankAccountModel();

        if (validStatusCode(statusCode)) {
            queryResult.parse(bodyString);
        }

        queryResult.isSuccess = statusCode == 200;

        if (!queryResult.isSuccess && String.isBlank(queryResult.feilmelding)) {
            queryResult.feilmelding = DEFAULT_ERROR_MESSAGE;
        }
        return queryResult;
    }

    // ------------------------------------------
    public static Boolean validStatusCode(Integer statusCode) {
        return statusCode == 200 || statusCode == 404 || statusCode == 405 || statusCode == 500;
    }

    // ------------------------------------------
    public static String getOrgNo(Id recordId) {
        List<Account> accounts = [SELECT Id, INT_OrganizationNumber__c FROM Account WHERE Id = :recordId LIMIT 1];

        if (accounts.isEmpty()) {
            throw new AuraException('Feil! Vennligst kontakt en administrator.');
        }
        if (String.isBlank(accounts[0].INT_OrganizationNumber__c)) {
            throw new AuraException('Feil med virksomhetsnummeret, vennligst kontakt en administrator.');
        }

        return accounts[0].INT_OrganizationNumber__c;
    }
}
