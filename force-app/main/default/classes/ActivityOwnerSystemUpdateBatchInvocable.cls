/**
 * Starts the activity owner refresh batch from a Screen Flow.
 */
public with sharing class ActivityOwnerSystemUpdateBatchInvocable {
    private static final Integer MAX_BATCH_SIZE = 2000;

    /**
     * Validates Flow inputs and starts one batch for one activity type.
     * @param requests Flow action requests. Exactly one request is supported.
     * @return One result containing the asynchronous job ID or an error.
     */
    @InvocableMethod(
        label='TAG: Start activity owner refresh batch'
        description='Sets the system-update marker on matching Tasks or Events.'
        category='Activities'
    )
    public static List<Response> startBatch(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }
        if (requests.size() != 1) {
            for (Request ignoredRequest : requests) {
                responses.add(createFailure('InputValidation', 'Start only one activity type per batch invocation.'));
            }
            return responses;
        }

        Request request = requests[0];
        String validationMessage = validateRequest(request);
        if (validationMessage != null) {
            responses.add(createFailure('InputValidation', validationMessage));
            return responses;
        }

        try {
            Integer batchSize = request.batchSize.intValue();
            Integer recordLimit = request.recordLimit == null ? null : request.recordLimit.intValue();
            Id jobId = Database.executeBatch(
                new ActivityOwnerSystemUpdateBatch(request.activityType, recordLimit),
                batchSize
            );
            Response response = new Response();
            response.isSuccess = true;
            response.jobId = String.valueOf(jobId);
            responses.add(response);
        } catch (Exception error) {
            responses.add(createFailure(error.getTypeName(), error.getMessage()));
        }

        return responses;
    }

    /**
     * Flow input for the batch action.
     */
    public class Request {
        @InvocableVariable(label='Batch size' required=true)
        public Decimal batchSize;

        @InvocableVariable(label='Type' required=true)
        public String activityType;

        @InvocableVariable(label='Limit' required=false)
        public Decimal recordLimit;
    }

    /**
     * Result returned to Flow after the batch is submitted.
     */
    public class Response {
        @InvocableVariable(label='Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error message')
        public String errorMessage;

        @InvocableVariable(label='Error type')
        public String errorType;

        @InvocableVariable(label='Batch job ID')
        public String jobId;
    }

    private static String validateRequest(Request request) {
        if (request == null) {
            return 'Batch parameters are required.';
        }
        if (!isWholeNumber(request.batchSize) || request.batchSize < 1 || request.batchSize > MAX_BATCH_SIZE) {
            return 'Batch size must be a whole number from 1 to 2000.';
        }
        if (request.recordLimit != null && (!isWholeNumber(request.recordLimit) || request.recordLimit < 1)) {
            return 'Limit must be a positive whole number or blank.';
        }
        if (String.isBlank(request.activityType)) {
            return 'Type is required.';
        }
        return null;
    }

    private static Boolean isWholeNumber(Decimal value) {
        return value != null && value == value.setScale(0, RoundingMode.DOWN);
    }

    private static Response createFailure(String errorType, String errorMessage) {
        Response response = new Response();
        response.isSuccess = false;
        response.errorType = errorType;
        response.errorMessage = errorMessage;
        return response;
    }
}
