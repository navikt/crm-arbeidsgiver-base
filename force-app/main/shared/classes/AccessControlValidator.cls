global with sharing class AccessControlValidator {
    // Check if current user can read the SObject (doesn't check access to data)
    public static Boolean sObjectIsAccessible(String sObjectTypeStr) {
        return Schema.getGlobalDescribe().get(sObjectTypeStr).getDescribe().isAccessible();
    }

    // Check if current user can create the SObject
    public static Boolean sObjectIsCreateable(String sObjectTypeStr) {
        return Schema.getGlobalDescribe().get(sObjectTypeStr).getDescribe().isCreateable();
    }

    // Check if current user can read the content in the field
    public static Boolean fieldIsAccessible(String sObjectTypeStr, String sObjectFieldStr) {
        Schema.sObjectType sObjType = Schema.getGlobalDescribe().get(sObjectTypeStr);
        Schema.DescribeFieldResult sObjField = sObjType.getDescribe()
            .fields.getMap()
            .get(sObjectFieldStr)
            .getDescribe();

        return sObjField.isAccessible();
    }

    // Check if current user can write data to the field
    public static Boolean fieldIsCreateable(String sObjectTypeStr, String sObjectFieldStr) {
        Schema.sObjectType sObjType = Schema.getGlobalDescribe().get(sObjectTypeStr);
        Schema.DescribeFieldResult sObjField = sObjType.getDescribe()
            .fields.getMap()
            .get(sObjectFieldStr)
            .getDescribe();

        return sObjField.isCreateable();
    }
}
