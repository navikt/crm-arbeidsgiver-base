import { LightningElement, api } from 'lwc';

export default class FormattedField extends LightningElement {
    @api value;
    @api type;

    get isUrl() {
        return this.activeTemplate === 'c_reference';
    }
    get isText() {
        return this.activeTemplate === 'text';
    }
    get isRichText() {
        return this.activeTemplate === 'customrichtext';
    }
    get isEmail() {
        return this.activeTemplate === 'email';
    }
    get isPhone() {
        return this.activeTemplate === 'phone';
    }

    get isDate() {
        return this.activeTemplate === 'date';
    }
    get isNumber() {
        return this.activeTemplate === 'number';
    }
    get isBoolean() {
        return this.activeTemplate === 'boolean';
    }
    get isAddress() {
        return this.activeTemplate === 'address';
    }
    get url() {
        try {
            return {
                link: this.value?.link || '',
                name: this.value?.name || ''
            };
        } catch (error) {
            console.error('feil i url...' + error);
            return null;
        }
    }
    get addressParts() {
        try {
            return {
                street: this.value?.street || '',
                city: this.value?.city || '',
                province: this.value?.state || this.value?.province || '',
                country: this.value?.country || '',
                postalCode: this.value?.postalCode || this.value?.['postal-code'] || ''
            };
        } catch (error) {
            console.error('feil i adresseparsing...' + error);
            return null;
        }
    }

    isTemplate(typeKey) {
        return this.activeTemplate === typeKey;
    }

    get activeTemplate() {
        return this.type?.toLowerCase() || 'text';
    }
    /*
    customRichText
    switch on type {
            when Email       { return 'email'; }
            when Phone       { return 'phone'; }
            when Date        { return 'date'; }
            when DateTime    { return 'date'; }
            when Double      { return 'number'; }
            when Integer     { return 'number'; }
            when Boolean     { return 'boolean'; }
            when Picklist    { return 'text'; }
            when Address     { return 'address'; }
            when String      { return 'text'; }
            when else        { return 'text'; }
    */
}
