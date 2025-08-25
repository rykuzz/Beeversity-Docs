import { LightningElement, wire } from 'lwc';
import getLeadQualitySummary from '@salesforce/apex/LeadQualitySummaryController.getLeadQualitySummary';

const COLUMNS = [
    { label: 'Nama Lead', fieldName: 'name', type: 'text' },
    { label: 'Skor', fieldName: 'score', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Pemilik', fieldName: 'ownerName', type: 'text' }
];

export default class LwcQualitySummaryManager extends LightningElement {
    summaryData;
    error;
    columns = COLUMNS;

    allPoorLeads = [];
    currentPage = 1;
    pageSize = 3; 
    totalPages = 0;

    @wire(getLeadQualitySummary)
    wiredSummary({ error, data }) {
        if (data) {
            this.summaryData = data;
            this.error = undefined;
            

            this.allPoorLeads = data.poorLeads;
            this.totalPages = Math.ceil(data.poorLeads.length / this.pageSize);
            this.currentPage = 1; 
        } else if (error) {
            this.error = error;
            this.summaryData = undefined;
            console.error("Error fetching lead summary:", error);
        }
    }

    get paginatedPoorLeads() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        return this.allPoorLeads.slice(startIndex, endIndex);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    get paginationLabel() {
        return `Halaman ${this.currentPage} dari ${this.totalPages}`;
    }



    handlePrevious() {
        if (!this.isFirstPage) {
            this.currentPage -= 1;
        }
    }

    handleNext() {
        if (!this.isLastPage) {
            this.currentPage += 1;
        }
    }

    
    get isLoading() {
        return !this.summaryData && !this.error;
    }
    
    get rating() {
        if (!this.summaryData) return '';
        const score = this.summaryData.averageScore;
        if (score >= 90) return 'Luar Biasa';
        if (score >= 70) return 'Baik';
        if (score >= 50) return 'Cukup';
        return 'Perlu Perhatian';
    }
}