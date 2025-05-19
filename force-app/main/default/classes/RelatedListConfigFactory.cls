public class RelatedListConfigFactory {


    @TestVisible private static final Map<String, String> CONFIGS = new Map<String, String>{
        'Contact' => 'Name,Title,Email,MobilePhone',
        'AccountTeamMember'    => 'User.Name,TeamMemberRole,User.CompanyName,User.MobilePhone',
        'Contract__c'    => 'TAG_Link__c,Region__c,TAG_StartDate__c,TAG_EndDate__c,TAG_Status__c',
        'JobPosting__c' => 'Name',
        'CustomOpportunity__c' => 'Name,Source__c,TAG_Is_my_NAV_region__c,TAG_IA_Service_End__c,Createddate'
        
        // ...more
    };
    
    @TestVisible private static final Map<String, String> ICONS = new Map<String, String>{
        'Contact' => 'standard:contact',
        'AccountTeamMember'    => 'standard:team_member',
        'Contract__c'    => 'standard:form',
        'JobPosting__c' => 'custom:custom27',
        'CustomOpportunity__c' => 'custom:custom14'
        
        // ...more
    };


    @TestVisible private static final Map<String, String> TITLE = new Map<String, String>{
        'Contact' => 'standard:contact',
        'AccountTeamMember'    => 'standard:team_member',
        'Contract__c'    => 'standard:form',
        'JobPosting__c' => 'custom:custom27',
        'CustomOpportunity__c' => 'custom:custom14'
        
        // ...more
    };


    @AuraEnabled
    public static string getConfig(String objectApiName){
        try {
            if (!CONFIGS.containsKey(objectApiName)) {
                throw new AuraHandledException('Unknown object name: ' + objectApiName);
            }
            return CONFIGS.get(objectApiName);            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getObjectIcon(String objectApiName){
        try {
            if (!ICONS.containsKey(objectApiName)) {
                throw new AuraHandledException('Unknown object name: ' + objectApiName);
            }
            return ICONS.get(objectApiName);            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getTitle(String objectApiName){
        try {
            if (!TITLE.containsKey(objectApiName)) {
                throw new AuraHandledException('Unknown object name: ' + objectApiName);
            }
            return TITLE.get(objectApiName);            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}