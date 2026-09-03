/**
 * @description Invocable action used by the screen flow "TAG Move or Copy Campaign Members".
 * Moves or copies CustomCampaignMember__c records from one CustomCampaign__c to another.
 * Moved/copied members always get Status__c = 'Ny' and a blank Kommentar__c.
 */
public with sharing class TAG_CustomCampaignMemberTransfer {
    @TestVisible
    private static final String ACTION_MOVE = 'Move';
    @TestVisible
    private static final String ACTION_COPY = 'Copy';
    private static final String NEW_STATUS = 'Ny';
    private static final Integer MAX_RECORDS = 10000;

    // Business fields carried over to a copy. Deliberately explicit: OwnerId, audit fields and
    // the Key__c external id must never be cloned, and a describe based list varies between orgs.
    private static final List<String> COPYABLE_FIELDS = new List<String>{
        'Account__c',
        'AccountSentral__c',
        'Contact__c',
        'IsContacted__c',
        'IsSurvey__c',
        'NAV_Unit__c',
        'Owner__c',
        'Responsible__c'
    };

    public class TransferRequest {
        @InvocableVariable(label='Source Campaign Id' description='Campaign to take members from' required=true)
        public String sourceCampaignId;

        @InvocableVariable(label='Target Campaign Id' description='Campaign to put members into' required=true)
        public String targetCampaignId;

        @InvocableVariable(label='Action' description='Move or Copy' required=true)
        public String action;
    }

    public class TransferResult {
        @InvocableVariable(label='Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Number of Members')
        public Integer numberOfMembers;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Move or Copy Custom Campaign Members'
        description='Moves or copies campaign members to another custom campaign, resetting status to Ny and clearing comments'
        category='Custom Campaign'
    )
    public static List<TransferResult> transferMembers(List<TransferRequest> requests) {
        List<TransferResult> results = new List<TransferResult>();
        for (TransferRequest req : requests) {
            results.add(transferOne(req));
        }
        return results;
    }

    private static TransferResult transferOne(TransferRequest req) {
        TransferResult res = new TransferResult();
        res.isSuccess = false;
        res.numberOfMembers = 0;

        String action = req.action == null ? '' : req.action.trim();
        Boolean isMove = ACTION_MOVE.equalsIgnoreCase(action);
        Boolean isCopy = ACTION_COPY.equalsIgnoreCase(action);

        if (!isMove && !isCopy) {
            res.message = 'Ugyldig handling. Velg "Move" eller "Copy".';
            return res;
        }
        if (String.isBlank(req.sourceCampaignId) || String.isBlank(req.targetCampaignId)) {
            res.message = 'Både opprinnelig og ny kampanje må velges.';
            return res;
        }
        if (req.sourceCampaignId == req.targetCampaignId) {
            res.message = 'Opprinnelig og ny kampanje kan ikke være den samme.';
            return res;
        }

        try {
            List<CustomCampaign__c> targets = [
                SELECT Id, Name, Type__c
                FROM CustomCampaign__c
                WHERE Id = :req.targetCampaignId
                WITH USER_MODE
                LIMIT 1
            ];
            if (targets.isEmpty()) {
                res.message = 'Fant ikke den nye kampanjen.';
                return res;
            }
            CustomCampaign__c target = targets[0];

            List<CustomCampaignMember__c> members = getMembers(req.sourceCampaignId, isCopy);

            if (members.isEmpty()) {
                res.message = 'Fant ingen kampanjemedlemmer på den opprinnelige kampanjen.';
                return res;
            }
            if (members.size() > MAX_RECORDS) {
                res.message = 'For mange medlemmer (' + members.size() + '). Maks ' + MAX_RECORDS + ' per kjøring.';
                return res;
            }

            if (isMove) {
                for (CustomCampaignMember__c member : members) {
                    applyTargetValues(member, target);
                }
                Database.update(members, AccessLevel.USER_MODE);
                res.message = members.size() + ' kampanjemedlemmer ble flyttet til "' + target.Name + '".';
            } else {
                List<CustomCampaignMember__c> copies = new List<CustomCampaignMember__c>();
                for (CustomCampaignMember__c member : members) {
                    CustomCampaignMember__c copyRecord = member.clone(false, true, false, false);
                    applyTargetValues(copyRecord, target);
                    copies.add(copyRecord);
                }
                Database.insert(copies, AccessLevel.USER_MODE);
                res.message = copies.size() + ' kampanjemedlemmer ble kopiert til "' + target.Name + '".';
            }

            res.numberOfMembers = members.size();
            res.isSuccess = true;
        } catch (Exception e) {
            res.message = 'Noe gikk galt: ' + e.getMessage();
        }

        return res;
    }

    // Sets the values that are always overwritten on the target campaign
    private static void applyTargetValues(CustomCampaignMember__c member, CustomCampaign__c target) {
        member.CustomCampaign__c = target.Id;
        member.Campaign_type__c = target.Type__c;
        member.Status__c = NEW_STATUS;
        member.Kommentar__c = null;
    }

    // Move only needs the id, copy needs the business fields that should follow the member
    private static List<CustomCampaignMember__c> getMembers(String sourceCampaignId, Boolean isCopy) {
        String fields = isCopy ? String.join(getCopyableFields(), ', ') : 'Id';
        String soql =
            'SELECT ' +
            fields +
            ' FROM CustomCampaignMember__c WHERE CustomCampaign__c = :sourceId LIMIT ' +
            (MAX_RECORDS + 1);

        return (List<CustomCampaignMember__c>) Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'sourceId' => sourceCampaignId },
            AccessLevel.USER_MODE
        );
    }

    private static List<String> getCopyableFields() {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.CustomCampaignMember__c.fields.getMap();
        List<String> fieldNames = new List<String>{ 'Id' };

        for (String fieldName : COPYABLE_FIELDS) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if (field == null) {
                continue;
            }
            Schema.DescribeFieldResult describe = field.getDescribe();
            if (describe.isCreateable() && describe.isAccessible()) {
                fieldNames.add(fieldName);
            }
        }
        return fieldNames;
    }
}
