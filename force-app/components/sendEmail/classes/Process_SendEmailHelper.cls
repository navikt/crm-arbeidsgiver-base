public without sharing class Process_SendEmailHelper {
    public static Map<String, Id> getMapOfEmailTemplates(List<Process_SendEmail.Request> requests) {
        Map<String, Id> templateMap = new Map<String, Id>();
        Set<String> templateNames = new Set<String>();

        for (Process_SendEmail.Request req : requests) {
            templateNames.add(req.emailTemplateName);
        }

        List<EmailTemplate> emailTemplates = [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName IN :templateNames
        ];
        for (EmailTemplate et : emailTemplates) {
            templateMap.put(et.DeveloperName, et.Id);
        }

        return templateMap;
    }

    public static List<Messaging.SingleEmailMessage> requestToSingleEmailMessage(
        List<Process_SendEmail.Request> requests,
        Map<String, Id> templateMap,
        Id orgWideEmailId
    ) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

        for (Process_SendEmail.Request req : requests) {
            Id templateId = templateMap.containsKey(req.emailTemplateName)
                ? templateMap.get(req.emailTemplateName)
                : null;

            if (templateId != null) {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

                Id contactId = req.recipientContact != null ? req.recipientContact.Id : req.recipientContactId;

                if (orgWideEmailId != null && req.useDoNotReply) {
                    message.setOrgWideEmailAddressId(orgWideEmailId);
                }
                if (templateId != null) {
                    message.setTemplateId(templateId);
                }
                message.setWhatId(req.relatedToId);
                message.setTargetObjectId(contactId);
                message.setSaveAsActivity(req.saveAsActivity);

                messages.add(message);
            }
        }

        return messages;
    }
}
