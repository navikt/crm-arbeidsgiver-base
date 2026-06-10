public with sharing class TAG_RelatedListController {
    private static final Integer QUERY_LIMIT = 2000;
    private static final Pattern FILTER_PATTERN = Pattern.compile(
        '(?i)^\\s*' +
            '([A-Za-z][A-Za-z0-9_]*(?:\\.[A-Za-z][A-Za-z0-9_]*)*)' + // 1: felt
            '\\s*(=|!=|<=|>=|<|>|LIKE)\\s*' + // 2: operator
            '(\'(?:[^\']|\\\\\')*\'|-?\\d+(?:\\.\\d+)?|true|false|null)' + // 3: verdi
            '\\s*$'
    );

    /**
     * @description Returns child records related to a given parent record via a single lookup field.
     * @param fieldNames API names of the fields to return. Dot-notation supported (e.g. User.Name).
     * @param parentId Id of the parent record.
     * @param objectApiName API name of the child object to query.
     * @param relationField Lookup field on the child object pointing to the parent record.
     * @param filterConditions Optional single SOQL condition on the form "<field> <operator> <value>".
     *                        Allowed operators: =, !=, <, >, <=, >=, LIKE.
     *                        String values must be wrapped in single quotes.
     * @return List<SObject> matching records, FLS-stripped according to the running user.
     */
    @AuraEnabled
    public static List<sObject> getRelatedList(
        List<String> fieldNames,
        Id parentId,
        String objectApiName,
        String relationField,
        String filterConditions
    ) {
        try {
            validateInput(fieldNames, parentId, objectApiName, relationField, filterConditions);

            String whereClause = String.isNotBlank(filterConditions) ? filterConditions.trim() + ' AND ' : '';
            whereClause += relationField + ' = :parentId';

            String query =
                'SELECT ' +
                String.join(fieldNames, ', ') +
                ' FROM ' +
                objectApiName +
                ' WHERE ' +
                whereClause +
                ' ORDER BY Id DESC LIMIT ' +
                QUERY_LIMIT;

            List<sObject> returnList = Database.query(query);

            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, returnList);
            if (!decision.getModifiedIndexes().isEmpty()) {
                throw new TAG_RelatedListControllerException(
                    'Du mangler tilgang til noen av feltene i relaterte poster. Kontakt administratoren for å få tilgang.'
                );
            }

            return returnList;
        } catch (TAG_RelatedListControllerException e) {
            throw toAuraException(e.getMessage());
        } catch (Exception e) {
            throw toAuraException('Feil ved innhenting av relaterte poster');
        }
    }

    private static void validateInput(
        List<String> fieldNames,
        Id parentId,
        String objectApiName,
        String relationField,
        String filterConditions
    ) {
        if (
            parentId == null ||
            String.isBlank(objectApiName) ||
            String.isBlank(relationField) ||
            fieldNames == null ||
            fieldNames.isEmpty()
        ) {
            throw new TAG_RelatedListControllerException('Manglende påkrevde parametere');
        }
        if (String.isNotBlank(filterConditions)) {
            Matcher m = FILTER_PATTERN.matcher(filterConditions.trim());
            if (!m.matches()) {
                throw new TAG_RelatedListControllerException(
                    'Ugyldig filter-syntaks. Forventet: <felt> <operator> <verdi>'
                );
            }
        }
    }

    private static AuraHandledException toAuraException(String userMessage) {
        AuraHandledException e = new AuraHandledException(userMessage);
        e.setMessage(userMessage);
        return e;
    }

    public class TAG_RelatedListControllerException extends Exception {
    }
}
