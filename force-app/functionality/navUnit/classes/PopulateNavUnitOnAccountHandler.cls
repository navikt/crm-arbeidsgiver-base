global without sharing class PopulateNavUnitOnAccountHandler extends MyTriggers {
  global override void onBeforeInsert() {
    List<Account> businessAccounts = new List<Account>();
    for (Account acc : (List<Account>) records) {
      if (acc.IsPersonAccount == false) {
        businessAccounts.add(acc);
      }
    }

    if (businessAccounts.size() > 0) {
      NavUnitAccountRoutingService.getNavUnits(businessAccounts);
    }
  }

  global override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
    //check if municipality number or postal code is changed
    List<String> fieldNamesToCheck = new List<String>{
      'INT_MunicipalityNumber__c',
      'ShippingPostalCode',
      'TAG_Force_Update__c'
    };
    List<Account> accountsToUpdate = new List<Account>();
    for (Account account : (List<Account>) records) {
      if (
        !account.IsPersonAccount &&
        MyTriggers.hasChangedFields(fieldNamesToCheck, account, triggerOldMap.get(account.Id))
      ) {
        accountsToUpdate.add(account);
      }
    }
    if (accountsToUpdate.size() > 0) {
      NavUnitAccountRoutingService.getNavUnits(accountsToUpdate);
    }
  }
}
