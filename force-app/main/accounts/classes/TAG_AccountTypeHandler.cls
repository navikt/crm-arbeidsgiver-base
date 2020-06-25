global class TAG_AccountTypeHandler extends MyTriggers {

	global override void onBeforeInsert() {
		setAccountType();
	}

	private void setAccountType() {
		Map<String, String> organizationalStructureMap = getOrganizationalStructureMaps();
		for ( Account account:(List<Account>) records ) {
			if ( organizationalStructureMap.keySet().contains( account.INT_OrganizationalStructure__c ) ) {
				account.CRM_AccountType__c = organizationalStructureMap.get( account.INT_OrganizationalStructure__c );
			}
			else{
				//set default account type
				account.CRM_AccountType__c = organizationalStructureMap.get( 'Default' );
			}
		}
	}


	private Map<String, String> getOrganizationalStructureMaps() {

		Map<String, String> organizationalStructureMap = new Map<String, String>();
		for ( OrganizationalStructureMap__mdt structure:[SELECT DeveloperName, AccountType__c FROM OrganizationalStructureMap__mdt] ) {
			String structureCode = structure.DeveloperName;
			if ( structureCode == 'null' ) {
				structureCode = null;
			}
			organizationalStructureMap.put( structureCode, structure.AccountType__c );
		}

		return organizationalStructureMap;

	}
}
