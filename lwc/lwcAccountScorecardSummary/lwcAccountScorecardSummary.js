import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountScorecard from '@salesforce/apex/AccountSummaryController.getAccountScorecard';
import getAccountCompletionSuggestions from '@salesforce/apex/AccountSummaryController.getAccountCompletionSuggestions';

const COLUMNS = [
    { 
        label: 'Nama Akun', 
        fieldName: 'accountUrl', 
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        },
        sortable: true,
        initialWidth: 250
    },
    { 
        label: 'Pemilik', 
        fieldName: 'OwnerName', 
        type: 'text',
        sortable: true,
        initialWidth: 150
    },
    { 
        label: 'Skor Kelengkapan', 
        fieldName: 'completenessScore', 
        type: 'number',
        cellAttributes: {
            class: { fieldName: 'scoreClass' },
            alignment: 'center'
        },
        typeAttributes: {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        },
        sortable: true,
        initialWidth: 140
    },
    {
        label: 'Level',
        fieldName: 'completenessLevel',
        type: 'text',
        cellAttributes: {
            class: { fieldName: 'levelClass' },
            alignment: 'center'
        },
        sortable: true,
        initialWidth: 100
    },
    {
        label: 'Field yang Kurang',
        fieldName: 'missingFields',
        type: 'text',
        wrapText: true,
        initialWidth: 300
    }
];

export default class LwcAccountScorecardSummary extends LightningElement {
    @track summaryData = [];
    @track paginatedData = [];
    @track error;
    @track isLoading = true;
    
    columns = COLUMNS;
    wiredResult;
    
    // Data storage
    _fullCriticalAccounts = [];
    _fullAtRiskAccounts = [];
    _fullHealthyAccounts = [];
    
    // Pagination
    currentPage = 1;
    pageSize = 10;
    totalPages = 0;
    totalRecords = 0;
    
    // Current active tab
    activeCategory = 'Data Minim';
    
    // Last updated
    lastUpdated = new Date().toLocaleString('id-ID');

    @wire(getAccountScorecard)
    wiredScorecardData(result) {
        this.wiredResult = result;
        const { error, data } = result;
        
        this.isLoading = true;
        
        if (data) {
            try {
                this.processSuccessData(data);
                this.error = undefined;
            } catch (processingError) {
                this.handleError('Error processing data', processingError);
            }
        } else if (error) {
            this.handleError('Error fetching data', error);
        }
        
        this.isLoading = false;
    }

    processSuccessData(data) {
        // Process summary data with enhanced styling
        this.summaryData = data.summaryData.map(item => {
            let cardClass = 'slds-box slds-box_link slds-p-around_medium slds-box_shadow';
            let iconName = 'standard:account';
            let iconVariant = 'base';
            let borderStyle = '';
            
            switch (item.label) {
                case 'Data Minim':
                    iconName = 'utility:error';
                    iconVariant = 'error';
                    borderStyle = 'border-left: 4px solid #c23934;';
                    break;
                case 'Data Kurang':
                    iconName = 'utility:warning';
                    iconVariant = 'warning';
                    borderStyle = 'border-left: 4px solid #dd7a01;';
                    break;
                case 'Data Lengkap':
                    iconName = 'utility:success';
                    iconVariant = 'success';
                    borderStyle = 'border-left: 4px solid #2e844a;';
                    break;
            }
            
            return {
                ...item,
                cardClass,
                iconName,
                iconVariant,
                borderStyle
            };
        });

        // Process and enhance account data
        this._fullCriticalAccounts = this.enhanceAccountData(data.criticalAccounts, 'Data Minim');
        this._fullAtRiskAccounts = this.enhanceAccountData(data.atRiskAccounts, 'Data Kurang');
        this._fullHealthyAccounts = this.enhanceAccountData(data.healthyAccounts, 'Data Lengkap');
        
        // Setup initial pagination for critical accounts
        this.setupPagination(this._fullCriticalAccounts);
        this.lastUpdated = new Date().toLocaleString('id-ID');
    }

    enhanceAccountData(accounts, category) {
        return accounts.map(acc => {
            // Add visual indicators based on completeness
            let scoreClass = '';
            let levelClass = '';
            
            switch (category) {
                case 'Data Minim':
                    scoreClass = 'slds-text-color_error slds-text-title_bold';
                    levelClass = 'slds-badge slds-badge_lightest';
                    break;
                case 'Data Kurang':
                    scoreClass = 'slds-text-color_default slds-text-title_bold';
                    levelClass = 'slds-badge slds-badge_lightest';
                    break;
                case 'Data Lengkap':
                    scoreClass = 'slds-text-color_success slds-text-title_bold';
                    levelClass = 'slds-badge slds-badge_lightest';
                    break;
            }
            
            return {
                ...acc,
                accountUrl: `/lightning/r/Account/${acc.Id}/view`,
                scoreClass,
                levelClass
            };
        });
    }

    handleError(message, error) {
        this.error = error;
        this.errorMessage = error?.body?.message || error?.message || 'Unknown error occurred';
        console.error(message, error);
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: this.errorMessage,
                variant: 'error'
            })
        );
    }

    // Fixed tab switching handler
    handleTabSwitch(event) {
        // Get the active tab value
        const activeTabValue = event.target.activeTabValue;
        this.activeCategory = activeTabValue;
        
        let fullData;
        switch (this.activeCategory) {
            case 'Data Minim':
                fullData = this._fullCriticalAccounts;
                break;
            case 'Data Kurang':
                fullData = this._fullAtRiskAccounts;
                break;
            case 'Data Lengkap':
                fullData = this._fullHealthyAccounts;
                break;
            default:
                fullData = [];
        }
        
        console.log('Active Category:', this.activeCategory);
        console.log('Data to display:', fullData.length);
        
        this.setupPagination(fullData);
    }

    setupPagination(data) {
        this.totalRecords = data?.length || 0;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.currentPage = 1;
        this.refreshPaginatedData(data);
    }

    refreshPaginatedData(data) {
        if (!data || data.length === 0) {
            this.paginatedData = [];
            return;
        }
        
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.paginatedData = data.slice(startIndex, endIndex);
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.refreshCurrentData();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.refreshCurrentData();
        }
    }

    refreshCurrentData() {
        let dataToPaginate;
        switch (this.activeCategory) {
            case 'Data Minim':
                dataToPaginate = this._fullCriticalAccounts;
                break;
            case 'Data Kurang':
                dataToPaginate = this._fullAtRiskAccounts;
                break;
            case 'Data Lengkap':
                dataToPaginate = this._fullHealthyAccounts;
                break;
            default:
                dataToPaginate = [];
        }
        this.refreshPaginatedData(dataToPaginate);
    }

    // Method to get completion suggestions for selected account
    async handleAccountSuggestions(event) {
        const accountId = event.detail.selectedRows?.[0]?.Id;
        if (!accountId) return;

        try {
            const suggestions = await getAccountCompletionSuggestions({ accountId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Saran Kelengkapan Data',
                    message: suggestions.missingFields,
                    variant: 'info',
                    mode: 'sticky'
                })
            );
        } catch (error) {
            console.error('Error getting suggestions:', error);
        }
    }

    // Computed properties for better UX
    get hasData() {
        return this.paginatedData && this.paginatedData.length > 0;
    }

    get showPagination() {
        return this.totalPages > 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    get startRecord() {
        return this.totalRecords === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
    }

    get endRecord() {
        const end = this.currentPage * this.pageSize;
        return end > this.totalRecords ? this.totalRecords : end;
    }

    get criticalCount() {
        return this._fullCriticalAccounts.length;
    }

    get atRiskCount() {
        return this._fullAtRiskAccounts.length;
    }

    get healthyCount() {
        return this._fullHealthyAccounts.length;
    }

    get totalAccounts() {
        return this.criticalCount + this.atRiskCount + this.healthyCount;
    }

    get averageCompletenessScore() {
        if (this.totalAccounts === 0) return 0;
        
        let totalScore = 0;
        [...this._fullCriticalAccounts, ...this._fullAtRiskAccounts, ...this._fullHealthyAccounts]
            .forEach(acc => totalScore += acc.completenessScore);
        
        return Math.round(totalScore / this.totalAccounts);
    }

    // Public method to refresh data
    refreshData() {
        this.isLoading = true;
        return refreshApex(this.wiredResult);
    }
}