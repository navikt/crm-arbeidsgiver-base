@IsTest
private class TAG_AccountTypeHandlerTest {
    @TestSetup
    static void makeData() {
        TAG_TestDataFactory.assignPermissionSet('accountTypeHandler@nav.test', 'ManageAccounts');
    }

    @IsTest
    private static void insertAccounts() {
        myTriggers.disable(PopulateNavUnitOnAccountHandler.class);
        User integrationUser = [SELECT Id FROM User WHERE Username = 'accountTypeHandler@nav.test'];
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

        List<Account> savedAccounts = [SELECT CRM_AccountType__c FROM Account ORDER BY INT_OrganizationNumber__c];
        System.assertEquals('B', savedAccounts[0].CRM_AccountType__c, 'AAFY accountype should be B');
        System.assertEquals('J', savedAccounts[1].CRM_AccountType__c, 'ADOS accountype should be J');
        System.assertEquals('J', savedAccounts[2].CRM_AccountType__c, 'AS accountype should be J');
        System.assertEquals('J', savedAccounts[3].CRM_AccountType__c, 'ASA accountype should be J');
        System.assertEquals('B', savedAccounts[4].CRM_AccountType__c, 'BEDR accountype should be B');
        System.assertEquals('B', savedAccounts[5].CRM_AccountType__c, 'FKF accountype should be B');
        System.assertEquals('B', savedAccounts[6].CRM_AccountType__c, 'KF accountype should be B');
        System.assertEquals('O', savedAccounts[7].CRM_AccountType__c, 'ORGL accountype should be O');
        System.assertEquals('J', savedAccounts[8].CRM_AccountType__c, 'UTLA accountype should be J');
        System.assertEquals(
            null,
            savedAccounts[9].CRM_AccountType__c,
            'Accounts without org structure should have account type null'
        );
    }
    @IsTest
    private static void updateAccounts() {
        myTriggers.disable(PopulateNavUnitOnAccountHandler.class);
        User integrationUser = [SELECT Id FROM User WHERE Username = 'accountTypeHandler@nav.test'];
        System.runAs(integrationUser) {
            List<Account> accounts = TAG_TestDataFactory.createAccounts(100);

            Test.startTest();

            //AAFY
            for (integer i = 0; i < 10; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'AAFY';
            }

            //ADOS
            for (integer i = 10; i < 20; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'ADOS';
            }

            //AS
            for (integer i = 20; i < 30; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'AS';
            }

            //ASA
            for (integer i = 30; i < 40; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'ASA';
            }

            //BEDR
            for (integer i = 40; i < 50; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'BEDR';
            }

            //FKF
            for (integer i = 50; i < 60; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'FKF';
            }

            //KF
            for (integer i = 60; i < 70; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'KF';
            }

            //ORGL
            for (integer i = 70; i < 80; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'ORGL';
            }

            //UTLA
            for (integer i = 80; i < 90; i++) {
                accounts[i].INT_OrganizationalStructure__c = 'UTLA';
            }

            //null
            for (integer i = 90; i < 95; i++) {
                accounts[i].INT_OrganizationalStructure__c = null;
            }

            update accounts;
            Test.stopTest();
        }

        List<Account> savedAccounts = [SELECT CRM_AccountType__c FROM Account];
        System.assertEquals('B', savedAccounts[0].CRM_AccountType__c, 'AAFY accountype should be B');
        System.assertEquals('B', savedAccounts[7].CRM_AccountType__c, 'AAFY accountype should be B');
        System.assertEquals('J', savedAccounts[10].CRM_AccountType__c, 'ADOS accountype should be J');
        System.assertEquals('J', savedAccounts[18].CRM_AccountType__c, 'ADOS accountype should be J');
        System.assertEquals('J', savedAccounts[20].CRM_AccountType__c, 'AS accountype should be J');
        System.assertEquals('J', savedAccounts[29].CRM_AccountType__c, 'AS accountype should be J');
        System.assertEquals('J', savedAccounts[30].CRM_AccountType__c, 'ASA accountype should be J');
        System.assertEquals('J', savedAccounts[35].CRM_AccountType__c, 'ASA accountype should be J');
        System.assertEquals('B', savedAccounts[40].CRM_AccountType__c, 'BEDR accountype should be B');
        System.assertEquals('B', savedAccounts[49].CRM_AccountType__c, 'BEDR accountype should be B');
        System.assertEquals('B', savedAccounts[50].CRM_AccountType__c, 'FKF accountype should be B');
        System.assertEquals('B', savedAccounts[57].CRM_AccountType__c, 'FKF accountype should be B');
        System.assertEquals('B', savedAccounts[60].CRM_AccountType__c, 'KF accountype should be B');
        System.assertEquals('B', savedAccounts[69].CRM_AccountType__c, 'KF accountype should be B');
        System.assertEquals('O', savedAccounts[70].CRM_AccountType__c, 'ORGL accountype should be O');
        System.assertEquals('O', savedAccounts[79].CRM_AccountType__c, 'ORGL accountype should be O');
        System.assertEquals('J', savedAccounts[80].CRM_AccountType__c, 'UTLA accountype should be J');
        System.assertEquals('J', savedAccounts[89].CRM_AccountType__c, 'UTLA accountype should be J');
        System.assertEquals(
            null,
            savedAccounts[90].CRM_AccountType__c,
            'Accounts without org structure should have account type null'
        );
        System.assertEquals(
            null,
            savedAccounts[99].CRM_AccountType__c,
            'Accounts without org structure should have account type null'
        );
    }
}
