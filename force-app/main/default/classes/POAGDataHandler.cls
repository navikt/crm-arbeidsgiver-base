public with sharing class POAGDataHandler {
    /*

Problem: CreatedBy and LastModifiedBy on stored vote records disclose who voted what, which is a privacy issue. For instance, a user who have voted dislike on everything can be perceived as a negative person. 
Solutions for privacy: 
Option 1: Create one record to store that a user has voted (userId - component key compo). Create one record for each component and update like/unlike counter. Separates who voted from what they voted.
This approach allows for tracking the number of likes and dislikes without revealing individual user votes.
Drawback: Not possible to change vote.
Alternative approach: Sharing model is set to 'Private' to ensure that only the user who created the record can see it. Clicking like/dislike updates count on the component record. Users with View all data permission can still see all votes.
Option 2: Create one record pr vote (each userId and component key), but only store likes (only the like button is available). 
This approach minimizes the risk of negative perceptions since we can't distinguish between neutral, dislike, and unseen.

* */
    // Query POAG_Data__c records based on the provided
    @AuraEnabled
    public static Boolean hasRecords(String voteKey, String userId) {
        try {
            String hashedKey = createHash(voteKey, userId);
            String query = 'SELECT count() FROM POAG_Data__c WHERE TAG_Key__c = :hashedKey';

            return Database.countQuery(query) > 0;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean handleNewRating(String voteKey, String userId, Boolean liked) {
        try {
            String hashedKey = createHash(voteKey, userId);
            createRecord(hashedKey, liked, voteKey);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean handleDeleteRating(String voteKey, String userId) {
        try {
            String hashedKey = createHash(voteKey, userId);
            deleteRecord(hashedKey);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String createHash(String voteKey, String userId) {
        // Blob hash = Crypto.generateDigest('SHA3-512', Blob.valueOf(voteKey + userId));
        Blob hash = Blob.valueOf(voteKey + userId);
        String hashStr = EncodingUtil.base64Encode(hash);
        return hashStr;
    }

    private static void createRecord(String key, Boolean liked, String componentName) {
        POAG_Data__c record = new POAG_Data__c();
        record.TAG_Key__c = key;
        record.TAG_Like__c = liked;
        record.TAG_Component_Name__c = componentName;
        insert record;
    }

    private static void deleteRecord(String key) {
        List<POAG_Data__c> recordsToDelete = [SELECT Id FROM POAG_Data__c WHERE TAG_Key__c = :key];
        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }
}
