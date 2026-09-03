/**
 * @description Test class for TAG_CustomCampaignMemberTransfer.
 *
 * @see TAG_CustomCampaignMemberTransfer
 *
 * @group TAG Custom Campaign
 */
@IsTest
private class TAG_CustomCampaignMemberTransferTest {
    private static final String RUNNER_LAST_NAME = 'CcmTransferRunner';

    @TestSetup
    static void makeData() {
        // The action runs in user mode, so the test user needs the campaign permission set
        System.runAs(new User(Id = UserInfo.getUserId())) {
            TAG_TestDataFactory.createUserWithPermset(RUNNER_LAST_NAME, 'Arbeidsgiver_Kampanje');
        }

        List<Account> accounts = TAG_TestDataFactory.createAccounts(2);

        CustomCampaign__c source = new CustomCampaign__c(
            Name = 'Kildekampanje',
            Type__c = 'Sommerjobbkampanje',
            Status__c = 'Åpen',
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(30)
        );
        CustomCampaign__c target = new CustomCampaign__c(
            Name = 'Målkampanje',
            Type__c = 'Inkluderingskampanje',
            Status__c = 'Åpen',
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(30)
        );
        insert new List<CustomCampaign__c>{ source, target };

        List<CustomCampaignMember__c> members = new List<CustomCampaignMember__c>();
        for (Account acc : accounts) {
            members.add(
                new CustomCampaignMember__c(
                    Account__c = acc.Id,
                    CustomCampaign__c = source.Id,
                    Status__c = 'Interessert',
                    Kommentar__c = 'Gammel kommentar'
                )
            );
        }
        insert members;
    }

    private static Id getCampaignId(String name) {
        return [SELECT Id FROM CustomCampaign__c WHERE Name = :name LIMIT 1].Id;
    }

    private static User getRunner() {
        return [SELECT Id FROM User WHERE LastName = :RUNNER_LAST_NAME LIMIT 1];
    }

    private static TAG_CustomCampaignMemberTransfer.TransferResult runAsCampaignUser(
        TAG_CustomCampaignMemberTransfer.TransferRequest req
    ) {
        List<TAG_CustomCampaignMemberTransfer.TransferResult> results;
        System.runAs(getRunner()) {
            results = TAG_CustomCampaignMemberTransfer.transferMembers(
                new List<TAG_CustomCampaignMemberTransfer.TransferRequest>{ req }
            );
        }
        return results[0];
    }

    private static TAG_CustomCampaignMemberTransfer.TransferRequest buildRequest(String action) {
        TAG_CustomCampaignMemberTransfer.TransferRequest req = new TAG_CustomCampaignMemberTransfer.TransferRequest();
        req.sourceCampaignId = getCampaignId('Kildekampanje');
        req.targetCampaignId = getCampaignId('Målkampanje');
        req.action = action;
        return req;
    }

    @IsTest
    static void moveMembersPositiveTest() {
        TAG_CustomCampaignMemberTransfer.TransferRequest req = buildRequest('Move');

        Test.startTest();
        TAG_CustomCampaignMemberTransfer.TransferResult result = runAsCampaignUser(req);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Move should succeed: ' + result.message);
        System.assertEquals(2, result.numberOfMembers, 'Both members should be moved');

        List<CustomCampaignMember__c> moved = [
            SELECT Id, Status__c, Kommentar__c
            FROM CustomCampaignMember__c
            WHERE CustomCampaign__c = :req.targetCampaignId
        ];
        System.assertEquals(2, moved.size(), 'Target campaign should hold both members');
        System.assertEquals(
            0,
            [SELECT COUNT() FROM CustomCampaignMember__c WHERE CustomCampaign__c = :req.sourceCampaignId],
            'Source campaign should be empty after a move'
        );
        for (CustomCampaignMember__c member : moved) {
            System.assertEquals('Ny', member.Status__c, 'Status should be reset to Ny');
            System.assertEquals(null, member.Kommentar__c, 'Comment should be cleared');
        }
    }

    @IsTest
    static void copyMembersPositiveTest() {
        TAG_CustomCampaignMemberTransfer.TransferRequest req = buildRequest('Copy');

        Test.startTest();
        TAG_CustomCampaignMemberTransfer.TransferResult result = runAsCampaignUser(req);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Copy should succeed: ' + result.message);
        System.assertEquals(2, result.numberOfMembers, 'Both members should be copied');

        System.assertEquals(
            2,
            [SELECT COUNT() FROM CustomCampaignMember__c WHERE CustomCampaign__c = :req.sourceCampaignId],
            'Source campaign should keep its members after a copy'
        );

        List<CustomCampaignMember__c> copies = [
            SELECT Id, Account__c, Status__c, Kommentar__c
            FROM CustomCampaignMember__c
            WHERE CustomCampaign__c = :req.targetCampaignId
        ];
        System.assertEquals(2, copies.size(), 'Target campaign should hold two new members');
        for (CustomCampaignMember__c member : copies) {
            System.assertNotEquals(null, member.Account__c, 'Account should be carried over to the copy');
            System.assertEquals('Ny', member.Status__c, 'Status should be reset to Ny');
            System.assertEquals(null, member.Kommentar__c, 'Comment should be cleared');
        }
    }

    @IsTest
    static void invalidActionNegativeTest() {
        TAG_CustomCampaignMemberTransfer.TransferRequest req = buildRequest('Delete');

        Test.startTest();
        TAG_CustomCampaignMemberTransfer.TransferResult result = runAsCampaignUser(req);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Unknown action should fail');
        System.assertEquals(0, result.numberOfMembers, 'Nothing should be processed');
    }

    @IsTest
    static void sameCampaignNegativeTest() {
        TAG_CustomCampaignMemberTransfer.TransferRequest req = buildRequest('Move');
        req.targetCampaignId = req.sourceCampaignId;

        Test.startTest();
        TAG_CustomCampaignMemberTransfer.TransferResult result = runAsCampaignUser(req);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Same source and target should fail');
    }

    @IsTest
    static void missingInputNegativeTest() {
        TAG_CustomCampaignMemberTransfer.TransferRequest req = buildRequest('Move');
        req.sourceCampaignId = null;

        Test.startTest();
        TAG_CustomCampaignMemberTransfer.TransferResult result = runAsCampaignUser(req);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Missing campaign id should fail');
    }

    @IsTest
    static void noMembersNegativeTest() {
        CustomCampaign__c empty = new CustomCampaign__c(
            Name = 'Tom kampanje',
            Type__c = 'Fylkeskampanje',
            Status__c = 'Åpen',
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(30)
        );
        insert empty;

        TAG_CustomCampaignMemberTransfer.TransferRequest req = buildRequest('Move');
        req.sourceCampaignId = empty.Id;

        Test.startTest();
        TAG_CustomCampaignMemberTransfer.TransferResult result = runAsCampaignUser(req);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'A campaign without members should fail');
        System.assertEquals(0, result.numberOfMembers, 'Nothing should be processed');
    }
}
