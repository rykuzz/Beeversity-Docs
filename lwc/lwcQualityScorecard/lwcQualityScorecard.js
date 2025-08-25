import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';


const FIELDS_TO_CHECK = [
    { apiName: 'Lead.Name',     label: 'Nama',       icon: 'utility:user' },
    { apiName: 'Lead.Company',  label: 'Perusahaan', icon: 'utility:company' },
    { apiName: 'Lead.Email',    label: 'Email',      icon: 'utility:email' },
    { apiName: 'Lead.Phone',    label: 'Telepon',    icon: 'utility:call' },
    { apiName: 'Lead.Industry', label: 'Industri',   icon: 'utility:apps' }
];

const API_NAMES = FIELDS_TO_CHECK.map(field => field.apiName);

export default class LwcQualityScorecard extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: API_NAMES })
    lead;


    get qualityScore() {
        if (!this.lead.data) return 0;
        let filledFields = 0;
        API_NAMES.forEach(fieldName => {
            const fieldValue = this.lead.data.fields[fieldName.split('.')[1]].value;
            if (fieldValue) filledFields++;
        });
        return Math.round((filledFields / API_NAMES.length) * 100);
    }

    get rating() {
        const score = this.qualityScore;
        if (score >= 90) return 'Luar Biasa';
        if (score >= 70) return 'Baik';
        if (score >= 50) return 'Cukup';
        return 'Perlu Perhatian';
    }


    get cardClass() {

        return 'slds-card_boundary';
    }
    
    get ratingClass() {
        const score = this.qualityScore;
        let baseClass = 'slds-badge slds-text-heading_small ';
        if (score >= 90) return baseClass + 'rating-great';
        if (score >= 70) return baseClass + 'rating-good';
        return baseClass + 'rating-poor';
    }


    get fieldChecks() {
        if (!this.lead.data) return [];
        
        return FIELDS_TO_CHECK.map(fieldInfo => {
            const fieldApiName = fieldInfo.apiName.split('.')[1];
            const fieldValue = this.lead.data.fields[fieldApiName].value;
            const isFilled = !!fieldValue;

            return {
                label: fieldInfo.label,
                value: isFilled ? fieldValue : '[Kosong]',
                icon: fieldInfo.icon,
                tileClass: `slds-box slds-box_link slds-theme_default slds-p-around_small ${isFilled ? 'tile-success' : 'tile-error'}`
            };
        });
    }

    get recommendations() {
        if (!this.lead.data) return [];
        return this.fieldChecks
            .filter(check => check.value === '[Kosong]')
            .map(check => check.label);
    }

    get hasRecommendations() {
        return this.recommendations.length > 0;
    }

    get recommendationText() {
        const recommendations = this.recommendations;
        if (recommendations.length === 1) {
            return `Lengkapi field ${recommendations[0]}.`;
        }
        return `Lengkapi field: ${recommendations.join(', ')}.`;
    }
}