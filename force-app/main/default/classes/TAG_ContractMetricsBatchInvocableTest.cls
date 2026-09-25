@IsTest(SeeAllData=false)
private class TAG_ContractMetricsBatchInvocableTest {
    @testSetup
    private static void setup() {
        TAG_TestDataFactory.createUserWithPermset(
            'ARBEIDSGIVER ADMIN',
            new List<String>{ 'Arbeidsgiver_base', 'Arbeidsgiver_contract', 'Admin_Base' }
        );
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
    }
    @IsTest
    static void shouldEnqueueBatchWhenInvoked() {
        User user = [SELECT id FROM User WHERE LastName = 'ARBEIDSGIVER ADMIN' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            TAG_ContractMetricsBatchInvocable.startBatch();
            Test.stopTest();
        }

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TAG_ContractMetricsBatch'],
            'Invoking the action must enqueue the contract metrics batch'
        );
    }
}
