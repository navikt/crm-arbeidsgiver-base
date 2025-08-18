public with sharing class POAGDataHandler {
    // Query POAG_Data__c records based on the provided
    @AuraEnabled
    public static Boolean hasVoted(String componentName, String userId) {
        try {
            String voteKey = createVoteKey(componentName);
            String query = 'SELECT count() FROM POAG_Data__c WHERE VoteKey__c = :voteKey';

            return Database.countQuery(query) > 0;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean handleNewRating(String componentName, String userId, Integer vote) {
        try {
            createRecord(componentName, userId, vote);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String createVoteKey(String componentName) {
        /*Blob hash = Blob.valueOf(value);
        Blob hashEncr = Crypto.generateDigest('SHA3-512', hash);
        String voteKey = EncodingUtil.base64Encode(hashEncr);
        return voteKey;*/
        Id userId = UserInfo.getUserId();
        return componentName + userId; // For testing purposes, return the value directly
    }

    private static void createRecord(String componentName, Id userId, Integer vote) {
        TAG_Feedback__e event = new TAG_Feedback__e();
        event.VoteKey__c = createVoteKey(componentName);
        event.Vote__c = vote;
        event.ComponentName__c = componentName;
        //event.Comment__c = '';

        List<Database.SaveResult> results = EventBus.publish(new List<TAG_Feedback__e>{ event });
        System.debug('Event created: ' + event);
    }
}
