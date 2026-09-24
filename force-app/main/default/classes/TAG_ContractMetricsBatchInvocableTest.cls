@IsTest(SeeAllData=false)
private class TAG_ContractMetricsBatchInvocableTest {
    @IsTest
    static void shouldEnqueueBatchWhenInvoked() {
        Test.startTest();
        TAG_ContractMetricsBatchInvocable.startBatch();
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'TAG_ContractMetricsBatch'],
            'Invoking the action must enqueue the contract metrics batch'
        );
    }
}
