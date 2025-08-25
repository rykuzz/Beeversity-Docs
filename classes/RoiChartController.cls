public with sharing class RoiChartController {


    public Decimal campaignCost { get; private set; }
    public Decimal budgetedCost { get; private set; }
    public Decimal expectedRevenue { get; private set; }
    

    public Decimal roiValue { get; private set; }



    public RoiChartController(ApexPages.StandardController stdController) {
        Campaign camp = (Campaign)stdController.getRecord();


        Campaign currentCampaign = [
            SELECT Id, ROI__c, ActualCost, BudgetedCost, ExpectedRevenue
            FROM Campaign
            WHERE Id = :camp.Id
            LIMIT 1
        ];


        this.roiValue = (currentCampaign.ROI__c != null) ? currentCampaign.ROI__c.setScale(2) : 0;
        this.campaignCost = (currentCampaign.ActualCost != null) ? currentCampaign.ActualCost : 0;
        this.budgetedCost = (currentCampaign.BudgetedCost != null) ? currentCampaign.BudgetedCost : 0;
        this.expectedRevenue = (currentCampaign.ExpectedRevenue != null) ? currentCampaign.ExpectedRevenue : 0;
    }
}