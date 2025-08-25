public with sharing class InvoiceComponentController {

    public Id opportunityId {
        get;
        set {

            opportunityId = value; 
            if (opportunityId != null) {
                loadOpportunityData();
            }
        }
    }

    public Opportunity opp { get; private set; }
    public Contact primaryContact { get; private set; }

    public InvoiceComponentController() {}



    private void loadOpportunityData() {

        if (this.opp != null && this.opp.Id == this.opportunityId) {
            return;
        }

        try {
            this.opp = [SELECT Id, Name, Amount, CloseDate, AccountId, Account.Name,
                               (SELECT Quantity, UnitPrice, TotalPrice, PricebookEntry.Product2.Name
                                FROM OpportunityLineItems)
                        FROM Opportunity
                        WHERE Id = :this.opportunityId
                        LIMIT 1];
            
            if (this.opp != null) {
                List<OpportunityContactRole> roles = [SELECT ContactId
                                                      FROM OpportunityContactRole
                                                      WHERE OpportunityId = :this.opportunityId AND IsPrimary = TRUE
                                                      LIMIT 1];
                
                if (!roles.isEmpty()) {
                    this.primaryContact = [SELECT Id, Name, Email, MailingStreet, MailingCity, MailingState, MailingPostalCode
                                           FROM Contact
                                           WHERE Id = :roles[0].ContactId
                                           LIMIT 1];
                }
            }
        } catch (Exception e) {
 
            System.debug('Error loading opportunity data: ' + e.getMessage());
            this.opp = null;
            this.primaryContact = null;
        }
    }
}