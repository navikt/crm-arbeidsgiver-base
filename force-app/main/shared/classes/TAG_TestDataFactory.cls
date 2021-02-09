public without sharing class TAG_TestDataFactory {
    public static Id getOwnerForAccounts() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
            LIMIT 1
        ];
        User testUser = [
            SELECT Id
            FROM User
            WHERE ProfileId = :p.Id AND IsActive = TRUE
            LIMIT 1
        ];
        User u = new user();
        System.runAs(testUser) {
            // UserRole ur = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1];
            u.LastName = 'Test Code';
            u.Email = 'this_is_a_fake_email@test.com';
            String d =
                String.valueOf(DateTime.now().millisecond()) +
                String.valueOf(DateTime.now().second()) +
                String.valueOf(DateTime.now().minute());
            u.Alias = 'Tcode';
            u.Username = d + 'testddsasd@test.com';
            // u.UserRoleId = ur.id;
            u.CommunityNickname = d + 'st12';
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'GMT';
            u.ProfileID = p.Id;
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            insert u;
        }

        return u.Id;
    }

    public static List<Account> createAccounts(Integer amount) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < amount; i++) {
            Account acc = new Account();
            acc.Name = 'test';
            acc.INT_OrganizationNumber__c = '9000000000';
            acc.INT_MunicipalityNumber__c = '3005';

            accounts.add(acc);
        }

        insert accounts;

        return accounts;
    }

    public static List<Contact> createContacts(
        List<Account> accounts,
        Integer amountPerAccount
    ) {
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            for (Integer i = 1; i <= amountPerAccount; i++) {
                contacts.add(
                    new Contact(
                        FirstName = 'Contact',
                        LastName = String.valueOf(i),
                        AccountId = acc.Id,
                        TAG_Informed__c = true
                    )
                );
            }
        }
        insert contacts;

        return contacts;
    }

    public static User createStandardUser(String lastName) {
        User user = new User();
        String d =
            String.valueOf(DateTime.now().millisecond()) +
            String.valueOf(DateTime.now().second()) +
            String.valueOf(DateTime.now().minute());
        user.Username = d + 'test@nav.no';
        user.Email = d + 'test@nav.no';
        user.Alias = 'tsamp';
        user.ProfileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User' OR Name = 'Standardbruker'
            LIMIT 1
        ]
        .Id;
        user.isActive = true;
        user.FirstName = 'First';
        user.LastName = lastName;
        user.TimeZoneSidKey = 'Europe/Paris';
        user.LocaleSidKey = 'no_NO';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'no';
        user.CommunityNickname = 'testUser' + d;
        insert user;

        return user;
    }

    public static void createUserWithPermset(
        String lastName,
        List<String> permsetNames
    ) {
        User u = TAG_TestDataFactory.createStandardUser(lastName);

        List<PermissionSet> permsets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN :permsetNames
        ];
        List<PermissionSetAssignment> assignemnts = new List<PermissionSetAssignment>();
        for (PermissionSet ps : permsets) {
            assignemnts.add(
                new PermissionSetAssignment(
                    AssigneeId = U.id,
                    PermissionSetId = ps.Id
                )
            );
        }
        insert assignemnts;
    }

    public static void createUserWithPermset(String lastName, String permset) {
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permset
            LIMIT 1
        ];
        User u = TAG_TestDataFactory.createStandardUser(lastName);
        insert new PermissionSetAssignment(
            AssigneeId = U.id,
            PermissionSetId = ps.Id
        );
    }

    public static List<CustomOpportunity__c> getCustomOpportunities(
        Integer amount,
        Boolean doInsert
    ) {
        List<CustomOpportunity__c> customOpportunities = new List<CustomOpportunity__c>();

        for (Integer i = 0; i < amount; i++) {
            customOpportunities.add(
                new CustomOpportunity__c(
                    INT_MunicipalityNumber__c = '0101',
                    Source__c = 'Kontaktskjema',
                    InclusionStage__c = 'Ny henvendelse'
                )
            );
        }

        if (doInsert)
            insert customOpportunities;

        return customOpportunities;
    }

    public static List<TemporaryLayoff__c> getTemporaryLayoffs(
        Integer amount,
        Account account,
        Boolean doInsert
    ) {
        List<TemporaryLayoff__c> temporaryLayoffs = new List<TemporaryLayoff__c>();

        for (Integer i = 0; i < amount; i++) {
            temporaryLayoffs.add(
                new TemporaryLayoff__c(
                    Account__c = account.Id,
                    Type__c = 'Masseoppsigelse',
                    StartDate__c = Date.today(),
                    EndDate__c = Date.today().addDays(30),
                    KafkaId__c = 'a32423423' + String.valueOf(i)
                )
            );
        }

        if (doInsert)
            insert temporaryLayoffs;

        return temporaryLayoffs;
    }

    public static void assignPermissionSet(
        String username,
        String permissionSetName
    ) {
        String d =
            String.valueOf(DateTime.now().millisecond()) +
            String.valueOf(DateTime.now().second()) +
            String.valueOf(DateTime.now().minute());
        User user = new User();
        user.Username = username;
        user.Email = username;
        user.Alias = 'tsamp';
        user.ProfileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User' OR Name = 'Standardbruker'
            LIMIT 1
        ]
        .Id;
        user.isActive = true;
        user.FirstName = 'First';
        user.LastName = 'Last UNIQUE NAME';
        user.TimeZoneSidKey = 'Europe/Paris';
        user.LocaleSidKey = 'no_NO';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'no';
        user.CommunityNickname = 'testUser' + d;
        insert user;

        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permissionSetName
        ];

        if (permissionSets.size() > 0) {
            PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
            permissionSetAssignment.AssigneeId = user.Id;
            permissionSetAssignment.PermissionSetId = permissionSets[0].Id;
            insert permissionSetAssignment;
        }
    }
}
