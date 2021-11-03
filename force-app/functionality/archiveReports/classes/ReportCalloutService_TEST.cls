@isTest
public class ReportCalloutService_TEST {
    @IsTest
    private static void moveReport() {
        ApiMock.setTestMock('PATCH_MOVE_REPORT', 200, 'OK');

        Test.startTest();
        ReportCalloutService.Response resp = new ReportCalloutService()
            .moveReport(getFakeId(Report.SObjectType), getFakeId(Folder.SObjectType));
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
    }

    @IsTest
    private static void moveReportError() {
        ApiMock.setTestMock('PATCH_MOVE_REPORT', 500, 'Unable to move report');

        Test.startTest();
        ReportCalloutService.Response resp = new ReportCalloutService()
            .moveReport(getFakeId(Report.SObjectType), getFakeId(Folder.SObjectType));
        Test.stopTest();

        System.assertEquals(false, resp.success, 'Expect error');
        System.assert(resp.errorMessage.contains('Flytting av rapport feilet.'), 'Expect error message');
    }

    private static Integer s_num = 1;

    private static String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
    }
}
