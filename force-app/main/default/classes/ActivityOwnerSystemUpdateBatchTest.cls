@IsTest(SeeAllData=false)
private class ActivityOwnerSystemUpdateBatchTest {
    @IsTest
    static void shouldReturnNoResponsesForNullRequests() {
        Assert.areEqual(
            0,
            ActivityOwnerSystemUpdateBatchInvocable.startBatch(null).size(),
            'Null input should return no responses'
        );
    }

    @IsTest
    static void shouldReturnNoResponsesForEmptyRequests() {
        Assert.areEqual(
            0,
            ActivityOwnerSystemUpdateBatchInvocable.startBatch(
                    new List<ActivityOwnerSystemUpdateBatchInvocable.Request>()
                )
                .size(),
            'Empty input should return no responses'
        );
    }

    @IsTest
    static void shouldRejectMultipleRequests() {
        List<ActivityOwnerSystemUpdateBatchInvocable.Response> responses = ActivityOwnerSystemUpdateBatchInvocable.startBatch(
            new List<ActivityOwnerSystemUpdateBatchInvocable.Request>{
                createRequest('ArbeidsgiverTask'),
                createRequest('IA_task')
            }
        );

        Assert.areEqual(2, responses.size(), 'Each request should receive a response');
        Assert.isFalse(responses[0].isSuccess, 'Multiple requests should not start a batch');
        Assert.areEqual('InputValidation', responses[0].errorType, 'The error should identify invalid input');
    }

    @IsTest
    static void shouldRejectUnsupportedActivityType() {
        List<ActivityOwnerSystemUpdateBatchInvocable.Response> responses = ActivityOwnerSystemUpdateBatchInvocable.startBatch(
            new List<ActivityOwnerSystemUpdateBatchInvocable.Request>{ createRequest('Unsupported') }
        );

        Assert.isFalse(responses[0].isSuccess, 'Unsupported types should not start a batch');
        Assert.isTrue(
            responses[0].errorMessage.contains('Unsupported activity type'),
            'The response should explain that the type is unsupported'
        );
    }

    @IsTest
    static void shouldBuildQueriesForSupportedActivityTypes() {
        List<String> activityTypes = new List<String>{ 'ArbeidsgiverTask', 'IA_task', 'ArbeidsgiverEvent', 'IA_event' };

        for (String activityType : activityTypes) {
            Database.QueryLocator queryLocator = new ActivityOwnerSystemUpdateBatch(activityType, null).start(null);
            Assert.isNotNull(queryLocator, 'A query should be returned for ' + activityType);
        }
    }

    @IsTest
    static void shouldIgnoreEmptyBatchScope() {
        ActivityOwnerSystemUpdateBatch batch = new ActivityOwnerSystemUpdateBatch('ArbeidsgiverTask', null);

        batch.execute(null, new List<SObject>());
    }

    @IsTest
    static void shouldStartBatchForValidRequest() {
        Test.startTest();
        List<ActivityOwnerSystemUpdateBatchInvocable.Response> responses = ActivityOwnerSystemUpdateBatchInvocable.startBatch(
            new List<ActivityOwnerSystemUpdateBatchInvocable.Request>{ createRequest('ArbeidsgiverTask') }
        );
        Test.stopTest();

        Assert.isTrue(responses[0].isSuccess, 'A supported type should start the batch');
        Assert.isNotNull(responses[0].jobId, 'The response should include the batch job ID');
    }

    @IsTest
    static void shouldRejectUnsupportedTypeInBatchConstructor() {
        try {
            new ActivityOwnerSystemUpdateBatch('Unsupported', null);
            Assert.fail('Unsupported activity types should be rejected');
        } catch (IllegalArgumentException error) {
            Assert.areEqual('Unsupported activity type.', error.getMessage(), 'The error should explain the issue');
        }
    }

    private static ActivityOwnerSystemUpdateBatchInvocable.Request createRequest(String activityType) {
        ActivityOwnerSystemUpdateBatchInvocable.Request request = new ActivityOwnerSystemUpdateBatchInvocable.Request();
        request.batchSize = 200;
        request.activityType = activityType;
        return request;
    }
}
