import { LightningElement, api } from 'lwc';

export default class FormattedField extends LightningElement {

    @api value;
    @api type;

    get isText(){
        return this.type?.toLowerCase() === 'text';
    }
    get isRichText(){
        return this.type?.toLowerCase() === 'rich-text';
    }
    get isUndefined(){
        return this.type === null;
    }

    get isEmail() {
        return this.type?.toLowerCase() === 'email';
    }

    get isPhone() {
        return this.type?.toLowerCase() === 'phone';
    }

    get isUrl() {
        return this.type === 'url';
    }

    get isDate() {
        return this.type?.toLowerCase() === 'date';
    }

    get isDateTime() {
        return this.type?.toLowerCase() === 'datetime';
    }

    get isNumber() {
        return this.type?.toLowerCase() === 'double' || this.type?.toLowerCase() === 'integer';
    }

    get isBoolean() {
        return this.type?.toLowerCase() === 'boolean';
    }

    get isAddress() {
        console.log(this.type);
        return this.type?.toLowerCase() === 'address' && this.value && typeof this.value === 'object';
    }

    get addressParts() {
        try {return {
            street: this.value?.street || '',
            city: this.value?.city || '',
            province: this.value?.state || this.value?.province || '',
            country: this.value?.country || '',
            postalCode: this.value?.postalCode || this.value?.['postal-code'] || ''
        };}
        catch(error) {console.error('feil i adresseparsing...' + error);
            return null;
        }
        
    }

}
