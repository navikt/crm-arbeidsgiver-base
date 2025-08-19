public with sharing class TAG_FeedbackHandler {
    @AuraEnabled
    public static Boolean handleNewRating(String componentName, String page, String question, Integer vote) {
        try {
            publishNewFeedbackEvent(componentName, page, question, vote);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void publishNewFeedbackEvent(String componentName, String page, String question, Integer vote) {
        InAppFeedbackEvent__e event = new InAppFeedbackEvent__e();

        event.Vote__c = vote;
        event.ComponentName__c = componentName;
        event.Page__c = page;
        event.Question__c = question;

        List<Database.SaveResult> results = EventBus.publish(new List<InAppFeedbackEvent__e>{ event });
        System.debug('Event created: ' + event);
    }
}
