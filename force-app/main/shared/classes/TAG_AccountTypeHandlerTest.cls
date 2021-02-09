@IsTest
private class TAG_AccountTypeHandlerTest {
    @TestSetup
    static void makeData() {
        TAG_TestDataFactory.assignPermissionSet(
            'accountTypeHandler@nav.test',
            'ManageAccounts'
        );
    }

    @IsTest
    private static void insertAccounts() {
        myTriggers.disable(PopulateNavUnitOnAccountHandler.class);
        User integrationUser = [
            SELECT Id
            FROM User
            WHERE Username = 'accountTypeHandler@nav.test'
        ];
        System.runAs(integrationUser) {
            List<Account> accounts = new List<Account>();
            accounts.add(
                new Account(
                    Name = 'AAFY',
                    INT_OrganizationNumber__c = '9000000001',
                    INT_OrganizationalStructure__c = 'AAFY'
                )
            );
            accounts.add(
                new Account(
                    Name = 'ADOS',
                    INT_OrganizationNumber__c = '9000000002',
                    INT_OrganizationalStructure__c = 'ADOS'
                )
            );
            accounts.add(
                new Account(
                    Name = 'AS',
                    INT_OrganizationNumber__c = '9000000003',
                    INT_OrganizationalStructure__c = 'AS'
                )
            );
            accounts.add(
                new Account(
                    Name = 'ASA',
                    INT_OrganizationNumber__c = '9000000004',
                    INT_OrganizationalStructure__c = 'ASA'
                )
            );
            accounts.add(
                new Account(
                    Name = 'BEDR',
                    INT_OrganizationNumber__c = '9000000005',
                    INT_OrganizationalStructure__c = 'BEDR'
                )
            );
            accounts.add(
                new Account(
                    Name = 'FKF',
                    INT_OrganizationNumber__c = '9000000006',
                    INT_OrganizationalStructure__c = 'FKF'
                )
            );
            accounts.add(
                new Account(
                    Name = 'KF',
                    INT_OrganizationNumber__c = '9000000007',
                    INT_OrganizationalStructure__c = 'KF'
                )
            );
            accounts.add(
                new Account(
                    Name = 'ORGL',
                    INT_OrganizationNumber__c = '9000000008',
                    INT_OrganizationalStructure__c = 'ORGL'
                )
            );
            accounts.add(
                new Account(
                    Name = 'UTLA',
                    INT_OrganizationNumber__c = '9000000009',
                    INT_OrganizationalStructure__c = 'UTLA'
                )
            );
            accounts.add(
                new Account(
                    Name = 'ZZZ',
                    INT_OrganizationNumber__c = '9000000010',
                    INT_OrganizationalStructure__c = null
                )
            );
            insert accounts;
        }

        List<Account> savedAccounts = [
            SELECT CRM_AccountType__c
            FROM Account
            ORDER BY Name
        ];
        System.assertEquals(
            'B',
            savedAccounts[0].CRM_AccountType__c,
            'AAFY accountype should be B'
        );
        System.assertEquals(
            'J',
            savedAccounts[1].CRM_AccountType__c,
            'ADOS accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[2].CRM_AccountType__c,
            'AS accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[3].CRM_AccountType__c,
            'ASA accountype should be J'
        );
        System.assertEquals(
            'B',
            savedAccounts[4].CRM_AccountType__c,
            'BEDR accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[5].CRM_AccountType__c,
            'FKF accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[6].CRM_AccountType__c,
            'KF accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[7].CRM_AccountType__c,
            'ORGL accountype should be B'
        );
        System.assertEquals(
            'J',
            savedAccounts[8].CRM_AccountType__c,
            'UTLA accountype should be J'
        );
        System.assertEquals(
            null,
            savedAccounts[9].CRM_AccountType__c,
            'Accounts without org structure should have account type null'
        );
    }

    @IsTest
    private static void updateAccounts() {
        myTriggers.disable(PopulateNavUnitOnAccountHandler.class);
        User integrationUser = [
            SELECT Id
            FROM User
            WHERE Username = 'accountTypeHandler@nav.test'
        ];
        System.runAs(integrationUser) {
            List<Account> accounts = TAG_TestDataFactory.createAccounts(1000);

            Test.startTest();

            //AAFY
            for (integer i = 0; i < 100; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'AAFY';
            }

            //ADOS
            for (integer i = 100; i < 200; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'ADOS';
            }

            //AS
            for (integer i = 200; i < 300; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'AS';
            }

            //ASA
            for (integer i = 300; i < 400; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'ASA';
            }

            //BEDR
            for (integer i = 400; i < 500; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'BEDR';
            }

            //FKF
            for (integer i = 500; i < 600; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'FKF';
            }

            //KF
            for (integer i = 600; i < 700; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'KF';
            }

            //ORGL
            for (integer i = 700; i < 800; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'ORGL';
            }

            //UTLA
            for (integer i = 800; i < 900; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'UTLA';
            }

            //null
            for (integer i = 900; i < 950; i++) {
                accounts[i].INT_OrganizationalStructure__c = null;
            }

            update accounts;
            Test.stopTest();
        }

        List<Account> savedAccounts = [SELECT CRM_AccountType__c FROM Account];
        System.assertEquals(
            'B',
            savedAccounts[0].CRM_AccountType__c,
            'AAFY accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[77].CRM_AccountType__c,
            'AAFY accountype should be B'
        );
        System.assertEquals(
            'J',
            savedAccounts[100].CRM_AccountType__c,
            'ADOS accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[180].CRM_AccountType__c,
            'ADOS accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[200].CRM_AccountType__c,
            'AS accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[299].CRM_AccountType__c,
            'AS accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[300].CRM_AccountType__c,
            'ASA accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[353].CRM_AccountType__c,
            'ASA accountype should be J'
        );
        System.assertEquals(
            'B',
            savedAccounts[400].CRM_AccountType__c,
            'BEDR accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[499].CRM_AccountType__c,
            'BEDR accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[500].CRM_AccountType__c,
            'FKF accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[570].CRM_AccountType__c,
            'FKF accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[600].CRM_AccountType__c,
            'KF accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[699].CRM_AccountType__c,
            'KF accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[700].CRM_AccountType__c,
            'ORGL accountype should be B'
        );
        System.assertEquals(
            'B',
            savedAccounts[799].CRM_AccountType__c,
            'ORGL accountype should be B'
        );
        System.assertEquals(
            'J',
            savedAccounts[800].CRM_AccountType__c,
            'UTLA accountype should be J'
        );
        System.assertEquals(
            'J',
            savedAccounts[899].CRM_AccountType__c,
            'UTLA accountype should be J'
        );
        System.assertEquals(
            null,
            savedAccounts[900].CRM_AccountType__c,
            'Accounts without org structure should have account type null'
        );
        System.assertEquals(
            null,
            savedAccounts[999].CRM_AccountType__c,
            'Accounts without org structure should have account type null'
        );
    }
}
