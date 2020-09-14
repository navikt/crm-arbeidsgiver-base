export { getFieldValues };

const getFieldValues = (row, recordId) => {
    console.log('row: ' + JSON.stringify(row));
    let fields = new Array();

    let relationship = getKeyAndValueIfValid(row.SObjectRelationshipField__c, recordId);
    if (relationship !== null) { fields.push(relationship); }

    let type = getKeyAndValueIfValid(row.Activity_Timeline_Child__r.SObjectTypeField__c, row.Activity_Timeline_Child__r.SObjectTypeValue__c);
    if (type !== null) { fields.push(type); }

    let val1 = getKeyAndValueIfValid(row.Activity_Timeline_Child__r.CreateableObject_Field1__c, row.Activity_Timeline_Child__r.CreateableObject_Value1__c);
    if (val1 !== null) { fields.push(val1); }

    let val2 = getKeyAndValueIfValid(row.Activity_Timeline_Child__r.CreateableObject_Field2__c, row.Activity_Timeline_Child__r.CreateableObject_Value2__c);
    if (val2 !== null) { fields.push(val2); }

    let val3 = getKeyAndValueIfValid(row.Activity_Timeline_Child__r.CreateableObject_Field3__c, row.Activity_Timeline_Child__r.CreateableObject_Value3__c);
    if (val3 !== null) { fields.push(val3); }

    // combine them all
    let fieldsCombined = '';
    for (let i = 0; i < fields.length; i++) {
        fieldsCombined += fields[i] + ',';
    }

    var d = new Date();
    fieldsCombined = fieldsCombined.replace('{today}', d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate());
    return fieldsCombined.substring(0, fieldsCombined.length - 1);
}

const getKeyAndValueIfValid = (key, value) => {
    let keyInvalid = isInvalid(key);
    let valueInvalid = isInvalid(value);
    if (!(keyInvalid || valueInvalid)) {
        return key + "=" + value;
    } else {
        return null;
    }
}

const isInvalid = (input) => {

    let checkNull = input === null;
    let checkUndefined = input === undefined;
    let checkStringNull = input === 'null';
    let checkListInvalid = false;

    if (!(checkNull || checkUndefined || checkStringNull)) {
        checkListInvalid = input.includes(';');
    }
    return checkNull || checkUndefined || checkStringNull || checkListInvalid;
}