@isTest
private without sharing class CampaignMemberControllerTest {
    @isTest
    private static void CampaignMemberControllerTest() {
        List<Account> accounts = TAG_TestDataFactory.createAccounts(2);

        CustomCampaign__c cc = new CustomCampaign__c(Name = 'Test');
        insert cc;

        List<CustomCampaignMember__c> ccms = new List<CustomCampaignMember__c>();
        CustomCampaignMember__c ccm = new CustomCampaignMember__c(
            Account__c = accounts[0].Id,
            CustomCampaign__c = cc.Id
        );
        ccms.add(ccm);
        CustomCampaignMember__c ccm2 = new CustomCampaignMember__c(
            Account__c = accounts[1].Id,
            CustomCampaign__c = cc.Id
        );
        ccms.add(ccm2);

        insert ccms;

        Test.StartTest();
        List<CustomCampaignMember__c> result = CampaignMemberController.getData(cc.Id);
        CampaignMemberController.deleteCampaignMember(ccm.Id);
        List<CustomCampaignMember__c> deletedResult = CampaignMemberController.getData(ccm.Id);
        Test.StopTest();

        System.assertEquals(ccms.size(), result.size());
        System.assertEquals(0, deletedResult.size());
    }
}
