import { LightningElement, api, wire } from 'lwc';
import getAccountHealthDetails from '@salesforce/apex/AccountHealthController.getAccountHealthDetails';

export default class LwcAccountHealthScorecard extends LightningElement {
    @api recordId;
    healthData;
    error;

    @wire(getAccountHealthDetails, { recordId: '$recordId' })
    wiredHealthDetails({ error, data }) {
        if (data) {
            this.healthData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.healthData = undefined;
        }
    }

    get isLoading() {
        return !this.healthData && !this.error;
    }

    get overallScore() {
        return this.healthData ? this.healthData.overallHealthScore : 0;
    }

    get healthRating() {
        const score = this.overallScore;
        if (score >= 80) return 'EXCELLENT';
        if (score >= 60) return 'HEALTHY';
        if (score >= 40) return 'AT RISK';
        return 'POOR';
    }

    get overallScoreClass() {
        const score = this.overallScore;
        let baseClass = 'score-display ';
        if (score >= 80) return baseClass + 'score-excellent';
        if (score >= 60) return baseClass + 'score-healthy';
        if (score >= 40) return baseClass + 'score-at-risk';
        return baseClass + 'score-poor';
    }

    get ratingBadgeClass() {
        const rating = this.healthRating;
        let baseClass = 'slds-badge slds-badge_inverse ';
        if (rating === 'EXCELLENT') return baseClass + 'badge-excellent';
        if (rating === 'HEALTHY') return baseClass + 'badge-healthy';
        if (rating === 'AT RISK') return baseClass + 'badge-at-risk';
        return baseClass + 'badge-poor';
    }
    
    get formattedOppValue() {
        const value = this.healthData ? this.healthData.openOppsValue : 0;
        return new Intl.NumberFormat('id-ID', { 
            style: 'currency', 
            currency: 'IDR',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    get salesTileClass() {
        const baseClass = 'health-tile ';
        return this.healthData && this.healthData.openOppsCount > 0 ? 
            baseClass + 'tile-success' : baseClass + 'tile-neutral';
    }

    get supportTileClass() {
        const baseClass = 'health-tile ';
        if (!this.healthData) return baseClass + 'tile-neutral';
        const cases = this.healthData.openCasesCount;
        if (cases > 2) return baseClass + 'tile-error';
        if (cases > 0) return baseClass + 'tile-warning';
        return baseClass + 'tile-success';
    }

    get engagementTileClass() {
        const baseClass = 'health-tile ';
        if (!this.healthData) return baseClass + 'tile-neutral';
        const contacts = this.healthData.contactCount;
        return contacts > 5 ? baseClass + 'tile-success' : baseClass + 'tile-neutral';
    }

    get completenesssTileClass() {
        const baseClass = 'health-tile ';
        if (!this.healthData) return baseClass + 'tile-neutral';
        const score = this.healthData.completenessScore;
        if (score >= 16) return baseClass + 'tile-success';
        if (score >= 10) return baseClass + 'tile-warning';
        return baseClass + 'tile-error';
    }

    get hasMissingFields() {
        return this.healthData && this.healthData.missingFields && this.healthData.missingFields.length > 0;
    }

    get missingFieldsCount() {
        return this.healthData && this.healthData.missingFields ? this.healthData.missingFields.length : 0;
    }

    get progressBarStyle() {
        const score = this.healthData ? this.healthData.completenessScore : 0;
        const percentage = (score / 20) * 100;
        return `width: ${percentage}%`;
    }

    get showCaseStatus() {
        return this.healthData && this.healthData.openCasesCount !== undefined;
    }

    get caseStatusText() {
        if (!this.healthData) return '';
        const cases = this.healthData.openCasesCount;
        if (cases === 0) return 'All Good';
        if (cases <= 2) return 'Under Control';
        return 'Needs Attention';
    }

    get caseStatusClass() {
        if (!this.healthData) return '';
        const cases = this.healthData.openCasesCount;
        if (cases === 0) return 'status-good';
        if (cases <= 2) return 'status-warning';
        return 'status-error';
    }

    handleRefresh() {
        // Refresh the wire adapter
        eval("$A.get('e.force:refreshView').fire();");
    }

    handleViewDetails() {
        // Navigate to account record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}