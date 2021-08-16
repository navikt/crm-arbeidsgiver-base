public with sharing class BankAccountController {
    // ---------------------------------------------------------------------------------------------- //
    // -------------------------------------------- AURA -------------------------------------------- //
    // ---------------------------------------------------------------------------------------------- //

    @AuraEnabled(cacheable=true)
    public static BankAccountModel getBankAccountNumber(Id recordId) {
        String orgNo = BankAccountHelper.getOrgNo(recordId);
        return queryKontonummer(orgNo);
    }

    // ---------------------------------------------------------------------------------------------- //
    // ------------------------------------------ CALLOUT ------------------------------------------- //
    // ---------------------------------------------------------------------------------------------- //

    private static final String API_BASE_CONFIG_NAME = 'KONTOREGISTER_BASE';
    private static final String API_SERVICE_CONFIG_NAME = 'KONTOREGISTER_SERVICE';
    private static final string SERVICE_AUTH_HEADER = 'Kontoregister';

    public static BankAccountModel queryKontonummer(String orgNo) {
        Map<String, String> params = new Map<String, String>{ 'orgnr' => orgNo };
        Map<String, String> headers = new Map<String, String>{ 'accept' => 'application/json' };

        ApiController apiCtrl = new ApiController();
        apiCtrl.setSystemContext(); // ! should probably be user context
        apiCtrl.initRequest(API_BASE_CONFIG_NAME, API_SERVICE_CONFIG_NAME, params);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.setHeaders(headers); // TODO fix 10:58:46:147 USER_DEBUG [52]|DEBUG|getResponse: System.HttpResponse[Status=Bad Request: malformed Host header, StatusCode=400]
        apiCtrl.doCallout();

        BankAccountModel queryResult = BankAccountHelper.saveResults(apiCtrl);

        return queryResult;
    }
}
