public inherited sharing class ReportCalloutService {
  private final string API_CONFIG_NAME = 'SF_API';

  public ReportCalloutService.Response moveReport(Id reportId, Id folderId) {
    ApiController apiCtrl = new ApiController();

    apiCtrl.initRequest(API_CONFIG_NAME, 'PATCH_MOVE_REPORT');
    apiCtrl.setEndpoint(apiCtrl.getRequestEndpoint() + reportId);
    apiCtrl.addHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
    apiCtrl.addHeader('Content-Type', 'application/json');
    apiCtrl.setBody('{"reportMetadata" : {"folderId":"' + folderId + '"}}');
    apiCtrl.doCallout();

    Response resp = new response();

    if (apiCtrl.getResponse().getStatusCode() == 200) {
      resp.success = true;
    } else {
      String errorRef = logError(apiCtrl.getResponse(), 'Error from ReportCalloutService.moveReport');
      resp.errorMessage = 'Flytting av rapport feilet. Referanse til feil: ' + errorRef;
      resp.success = false;
    }
    return resp;
  }

  private String logError(HttpResponse resp, String message) {
    String errorRef = '';

    LoggerUtility logger = new LoggerUtility();
    logger.error(message + '\n ' + 'Status: ' + resp.getStatus() + '\n' + 'Body: ' + resp.getBody(), null);
    errorRef = logger.peek().UUID__c;
    logger.publish();

    return errorRef;
  }

  public class Response {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String errorMessage;
  }
}
