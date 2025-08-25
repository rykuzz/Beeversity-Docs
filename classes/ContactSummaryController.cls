public with sharing class ContactSummaryController {


    public Contact contact { get; private set; }
    public List<Case> relatedCases { get; private set; }
    public List<OpportunityContactRole> relatedOpps { get; private set; }
    public Date generatedDate { get; private set; }

    public ContactSummaryController(ApexPages.StandardSetController controller) {

        Id contactId = ApexPages.currentPage().getParameters().get('id');
        this.generatedDate = Date.today();

        this.contact = [SELECT Id, Name, Email, Phone, Title, Department, 
                               MailingStreet, MailingCity, Account.Name 
                        FROM Contact 
                        WHERE Id = :contactId LIMIT 1];

        // Query untuk kasus yang terkait dengan Kontak
        this.relatedCases = [SELECT CaseNumber, Subject, Status, CreatedDate 
                             FROM Case 
                             WHERE ContactId = :contactId 
                             ORDER BY CreatedDate DESC LIMIT 5];
                             
        // Query BARU untuk Opportunity yang terkait dengan Kontak
        this.relatedOpps = [SELECT Opportunity.Name, Opportunity.StageName, 
                                   Opportunity.Amount, Opportunity.CloseDate
                            FROM OpportunityContactRole
                            WHERE ContactId = :contactId
                            ORDER BY Opportunity.CloseDate DESC LIMIT 5];
    }
    

    public Boolean hasCases {
        get {
            return !relatedCases.isEmpty();
        }
    }

    public Boolean hasOpportunities {
        get {
            return !relatedOpps.isEmpty();
        }
    }
}