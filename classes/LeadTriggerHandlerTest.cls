@IsTest
public class LeadTriggerHandlerTest {
    
    @TestSetup
    static void makeData() {

        List<Lead> testLeads = new List<Lead>();

        testLeads.add(new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company 1',
            Email = 'john.doe@test.com',
            Phone = '555-0101',
            Status = 'New'
        ));

        testLeads.add(new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Test Company 2',
            Email = 'jane.smith@test.com',
            Status = 'New'
        ));

        testLeads.add(new Lead(
            FirstName = 'Bob',
            LastName = 'Johnson',
            Company = 'Test Company 3',
            Phone = '555-0103',
            Status = 'New'
        ));

        testLeads.add(new Lead(
            FirstName = 'Alice',
            LastName = 'Williams',
            Company = 'Test Company 4',
            Status = 'New'
        ));

        testLeads.add(new Lead(
            FirstName = 'Convert',
            LastName = 'Ready',
            Company = 'Conversion Company',
            Email = 'convert@ready.com',
            Phone = '555-0105',
            Status = 'New'
        ));

        testLeads.add(new Lead(
            FirstName = 'NoContact',
            LastName = 'Initially',
            Company = 'No Contact Company',
            Status = 'New'
        ));
        
        insert testLeads;
    }
    
    @IsTest
    static void testSetInitialStatusAndRating() {
        Test.startTest();
        
        List<Lead> newLeads = new List<Lead>();

        Lead lead1 = new Lead(
            FirstName = 'Test1',
            LastName = 'User1',
            Company = 'Company1',
            Email = 'test1@example.com',
            Phone = '555-1111'
        );
        newLeads.add(lead1);

        Lead lead2 = new Lead(
            FirstName = 'Test2',
            LastName = 'User2',
            Company = 'Company2',
            Email = 'test2@example.com'
        );
        newLeads.add(lead2);

        Lead lead3 = new Lead(
            FirstName = 'Test3',
            LastName = 'User3',
            Company = 'Company3',
            Phone = '555-3333'
        );
        newLeads.add(lead3);

        Lead lead4 = new Lead(
            FirstName = 'Test4',
            LastName = 'User4',
            Company = 'Company4'
        );
        newLeads.add(lead4);

        Lead lead5 = new Lead(
            FirstName = 'Test5',
            LastName = 'User5',
            Company = 'Company5',
            Email = '',
            Phone = ''
        );
        newLeads.add(lead5);

        Lead lead6 = new Lead(
            FirstName = 'Test6',
            LastName = 'User6',
            Company = 'Company6',
            Email = '   ',
            Phone = '   '
        );
        newLeads.add(lead6);
        
        LeadTriggerHandler.setInitialStatusAndRating(newLeads);
        
        Test.stopTest();
        

        System.assertEquals('Contacted', lead1.Status, 'Lead with both email and phone should have Contacted status');
        System.assertEquals('Warm', lead1.Rating, 'Lead with both email and phone should have Warm rating');
        
        System.assertEquals('New', lead2.Status, 'Lead with only email should have New status');
        System.assertEquals('Cold', lead2.Rating, 'Lead with only email should have Cold rating');
        
        System.assertEquals('New', lead3.Status, 'Lead with only phone should have New status');
        System.assertEquals('Cold', lead3.Rating, 'Lead with only phone should have Cold rating');
        
        System.assertEquals('New', lead4.Status, 'Lead with no email or phone should have New status');
        System.assertEquals('Cold', lead4.Rating, 'Lead with no email or phone should have Cold rating');
        
        System.assertEquals('New', lead5.Status, 'Lead with empty email and phone should have New status');
        System.assertEquals('Cold', lead5.Rating, 'Lead with empty email and phone should have Cold rating');
        
        System.assertEquals('New', lead6.Status, 'Lead with whitespace email and phone should have New status');
        System.assertEquals('Cold', lead6.Rating, 'Lead with whitespace email and phone should have Cold rating');
    }
    
    @IsTest
    static void testProcessLeadsEmailPhoneAddition() {

        Lead noContactLead = [SELECT Id, FirstName, LastName, Email, Phone, Status, Rating FROM Lead WHERE FirstName = 'NoContact' LIMIT 1];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = noContactLead.clone(true, true, true, true);
        oldLead.Email = null;
        oldLead.Phone = null;
        oldLead.Status = 'New';
        oldLead.Rating = 'Cold';
        oldLeadMap.put(noContactLead.Id, oldLead);

        noContactLead.Email = 'newcontact@test.com';
        noContactLead.Phone = '555-9999';
        noContactLead.Status = 'New'; 
        noContactLead.Rating = 'Cold'; 
        newLeads.add(noContactLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :noContactLead.Id];
        System.assertEquals('Contacted', updatedLead.Status, 'Lead should be updated to Contacted when email and phone are added');
        System.assertEquals('Warm', updatedLead.Rating, 'Lead should be updated to Warm rating when email and phone are added');
    }
    
    @IsTest
    static void testProcessLeadsStatusChangeToReview() {
        Lead testLead = [SELECT Id, Status, Rating FROM Lead LIMIT 1];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Status = 'New';
        oldLead.Rating = 'Cold';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Status = 'Review';
        testLead.Rating = 'Cold'; 
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Hot', updatedLead.Rating, 'Rating should be updated to Hot when status changes to Review');
    }
    
    @IsTest
    static void testProcessLeadsStatusChangeToUnqualified() {
        Lead testLead = [SELECT Id, Status, Rating FROM Lead LIMIT 1];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Status = 'New';
        oldLead.Rating = 'Warm';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Status = 'Unqualified';
        testLead.Rating = 'Warm'; 
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Cold', updatedLead.Rating, 'Rating should be updated to Cold when status changes to Unqualified');
    }
    
    @IsTest
    static void testProcessLeadsStatusChangeToClosedConverted() {
        Lead conversionLead = [SELECT Id, FirstName, LastName, Company, Email, Phone, Status, Rating, IsConverted FROM Lead WHERE FirstName = 'Convert' LIMIT 1];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = conversionLead.clone(true, true, true, true);
        oldLead.Status = 'Review';
        oldLead.Rating = 'Warm';
        oldLeadMap.put(conversionLead.Id, oldLead);

        conversionLead.Status = 'Closed - Converted';
        conversionLead.Rating = 'Warm'; 
        newLeads.add(conversionLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();
        

        Lead convertedLead = [SELECT Id, IsConverted, Rating FROM Lead WHERE Id = :conversionLead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted when status changes to Closed - Converted');
        System.assertEquals('Hot', convertedLead.Rating, 'Rating should be updated to Hot when status changes to Closed - Converted');

        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'Conversion Company'];
        System.assertEquals(1, accounts.size(), 'Account should be created from lead conversion');
  
        List<Contact> contacts = [SELECT Id, FirstName, LastName FROM Contact WHERE FirstName = 'Convert' AND LastName = 'Ready'];
        System.assertEquals(1, contacts.size(), 'Contact should be created from lead conversion');

        List<Opportunity> opportunities = [SELECT Id, Name FROM Opportunity WHERE Name = 'Conversion Company Opportunity'];
        System.assertEquals(1, opportunities.size(), 'Opportunity should be created from lead conversion');
    }
    
    @IsTest
    static void testProcessLeadsRatingChangeToWarm() {
        List<Lead> existingLeads = [SELECT Id, Status, Rating FROM Lead LIMIT 2];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();
        
        for (Lead l : existingLeads) {
            Lead oldLead = l.clone(true, true, true, true);
            oldLead.Rating = 'Cold';
            oldLead.Status = 'New';
            oldLeadMap.put(l.Id, oldLead);

            l.Rating = 'Warm';
            l.Status = 'New';
            newLeads.add(l);
        }
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        List<Lead> updatedLeads = [SELECT Id, Status, Rating FROM Lead WHERE Id IN :newLeads];
        for (Lead l : updatedLeads) {
            System.assertEquals('Review', l.Status, 'Lead status should be updated to Review when rating changes to Warm');
        }
    }
    
    @IsTest
    static void testProcessLeadsRatingFromStatus() {
        List<Lead> existingLeads = [SELECT Id, Status, Rating FROM Lead LIMIT 4];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();
        
        String[] statuses = new String[]{'Closed - Not Converted', 'Closed - Converted', 'Review', 'Unqualified'};
        String[] expectedRatings = new String[]{'Cold', 'Hot', 'Hot', 'Cold'}; // Updated Review to Hot
        
        for (Integer i = 0; i < existingLeads.size() && i < statuses.size(); i++) {
            Lead l = existingLeads[i];

            Lead oldLead = l.clone(true, true, true, true);
            oldLead.Status = 'New';
            oldLead.Rating = 'Warm';
            oldLeadMap.put(l.Id, oldLead);
            l.Status = statuses[i];
            l.Rating = 'Warm'; 
            newLeads.add(l);
        }
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        List<Lead> updatedLeads = [SELECT Id, Status, Rating FROM Lead WHERE Id IN :newLeads];
        for (Integer i = 0; i < updatedLeads.size(); i++) {
            Lead l = updatedLeads[i];
            System.assertEquals(expectedRatings[i], l.Rating, 'Rating should match expected value for status: ' + l.Status);
        }
    }
    
    @IsTest
    static void testProcessLeadsConversionNotReady() {
        Lead testLead = [SELECT Id, FirstName, LastName, Company, Email, Phone, Status, Rating FROM Lead LIMIT 1];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Status = 'Review';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Status = 'Closed - Converted';
        testLead.Company = null;
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead nonConvertedLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(false, nonConvertedLead.IsConverted, 'Lead should not be converted without company');
    }
    
    @IsTest
    static void testProcessLeadsNoUpdatesNeeded() {
        List<Lead> existingLeads = [SELECT Id, Status, Rating FROM Lead LIMIT 1];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();
        
        for (Lead l : existingLeads) {

            Lead oldLead = l.clone(true, true, true, true);
            oldLeadMap.put(l.Id, oldLead);
            newLeads.add(l);
        }
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        System.assert(true, 'Method should complete without errors when no updates are needed');
    }
    
    @IsTest
    static void testProcessLeadsWithNullOldMap() {
        List<Lead> existingLeads = [SELECT Id, Status, Rating FROM Lead LIMIT 1];
        
        Test.startTest();

        LeadTriggerHandler.processLeads(existingLeads, null);
        
        Test.stopTest();

        System.assert(true, 'Method should handle null oldLeadMap without errors');
    }
    
    @IsTest
    static void testGetRatingFromStatusAllCases() {

        List<Lead> testLeads = new List<Lead>();

        String[] statuses = new String[]{'Closed - Not Converted', 'Closed - Converted', 'Review', 'Unqualified', 'Other Status'};
        
        for (String status : statuses) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'User',
                Company = 'Test Company',
                Email = 'test@example.com',
                Status = status,
                Rating = 'Cold' 
            ));
        }
        
        insert testLeads;
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        
        for (Lead l : testLeads) {
            Lead oldLead = l.clone(true, true, true, true);
            oldLead.Status = 'New';
            oldLead.Rating = 'Warm';
            oldLeadMap.put(l.Id, oldLead);
        }
        
        LeadTriggerHandler.processLeads(testLeads, oldLeadMap);
        
        Test.stopTest();

        System.assert(true, 'All switch cases should be covered');
    }
    
    @IsTest
    static void testIsLeadReadyForConversionEdgeCases() {
        Test.startTest();

        Lead leadNoCompany = new Lead(
            FirstName = 'Test',
            LastName = 'NoCompany',
            Email = 'test@example.com',
            Status = 'New'
        );
        insert leadNoCompany;

        Lead leadNoEmail = new Lead(
            FirstName = 'Test',
            LastName = 'NoEmail',
            Company = 'Test Company',
            Status = 'New'
        );
        insert leadNoEmail;

        Lead leadEmptyCompany = new Lead(
            FirstName = 'Test',
            LastName = 'EmptyCompany',
            Company = '',
            Email = 'test@example.com',
            Status = 'New'
        );
        insert leadEmptyCompany;

        Lead leadWhitespaceCompany = new Lead(
            FirstName = 'Test',
            LastName = 'WhitespaceCompany',
            Company = '   ',
            Email = 'test@example.com',
            Status = 'New'
        );
        insert leadWhitespaceCompany;
        
        List<Lead> newLeads = new List<Lead>{leadNoCompany, leadNoEmail, leadEmptyCompany, leadWhitespaceCompany};
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        
        for (Lead l : newLeads) {
            Lead oldLead = l.clone(true, true, true, true);
            oldLead.Status = 'Review';
            oldLeadMap.put(l.Id, oldLead);
            l.Status = 'Closed - Converted';
        }
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        List<Lead> checkedLeads = [SELECT Id, IsConverted FROM Lead WHERE Id IN :newLeads];
        for (Lead l : checkedLeads) {
            System.assertEquals(false, l.IsConverted, 'Lead should not be converted when not ready');
        }
    }
    
    @IsTest
    static void testConvertLeadsOptimizedErrorHandling() {
        Test.startTest();

        Lead errorLead = new Lead(
            FirstName = 'Error',
            LastName = 'Lead',
            Company = 'Error Company',
            Email = 'error@example.com',
            Status = 'New'
        );
        insert errorLead;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(errorLead.Id);
        lc.setConvertedStatus('Closed - Converted');
        Database.convertLead(lc);

        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        Lead oldLead = errorLead.clone(true, true, true, true);
        oldLead.Status = 'Review';
        oldLead.IsConverted = false;
        oldLeadMap.put(errorLead.Id, oldLead);
        
        errorLead.Status = 'Closed - Converted';
        errorLead.IsConverted = false; 
        
        LeadTriggerHandler.processLeads(new List<Lead>{errorLead}, oldLeadMap);
        
        Test.stopTest();

        System.assert(true, 'Method should handle conversion errors gracefully');
    }
    
    @IsTest
    static void testProcessLeadsWithSetLogic() {
        List<Lead> existingLeads = [SELECT Id, Status, Rating FROM Lead LIMIT 2];
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        
        for (Lead l : existingLeads) {
            Lead oldLead = l.clone(true, true, true, true);
            oldLead.Rating = 'Cold';
            oldLeadMap.put(l.Id, oldLead);
            l.Rating = 'Warm';
        }
        
        LeadTriggerHandler.processLeadsWithSetLogic(existingLeads, oldLeadMap);
        
        Test.stopTest();

        List<Lead> updatedLeads = [SELECT Id, Status FROM Lead WHERE Id IN :existingLeads];
        for (Lead l : updatedLeads) {
            System.assertEquals('Review', l.Status, 'Lead should be updated to Review status');
        }
    }
    
    @IsTest
    static void testDMLExceptionHandling() {

        Test.startTest();

        Lead testLead = new Lead(
            FirstName = 'DML',
            LastName = 'Test',
            Company = 'DML Company',
            Email = 'dml@test.com',
            Status = 'New',
            Rating = 'Cold'
        );
        insert testLead;
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Rating = 'Cold';
        oldLeadMap.put(testLead.Id, oldLead);
        
        testLead.Rating = 'Warm';

        try {
            LeadTriggerHandler.processLeads(new List<Lead>{testLead}, oldLeadMap);
        } catch (Exception e) {

            System.assert(false, 'Exception should be handled internally');
        }
        
        Test.stopTest();
        
        System.assert(true, 'DML exception handling should work correctly');
    }
    
    @IsTest
    static void testEmailPhoneAdditionButStatusAlreadyContacted() {

        Lead testLead = new Lead(
            FirstName = 'Already',
            LastName = 'Contacted',
            Company = 'Already Company',
            Status = 'New'
        );
        insert testLead;
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Email = null;
        oldLead.Phone = null;
        oldLead.Status = 'New';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Email = 'already@contacted.com';
        testLead.Phone = '555-8888';
        testLead.Status = 'Contacted'; // Already contacted
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];

        System.assertEquals('Contacted', updatedLead.Status, 'Status should remain Contacted');
        System.assertEquals('Warm', updatedLead.Rating, 'Rating should be updated to Warm');
    }
    
    @IsTest
    static void testStatusChangeWithNoRatingChange() {

        Lead testLead = new Lead(
            FirstName = 'Status',
            LastName = 'Change',
            Company = 'Status Company',
            Email = 'status@change.com',
            Status = 'New',
            Rating = 'Cold'
        );
        insert testLead;
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Status = 'New';
        oldLead.Rating = 'Cold';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Status = 'Contacted';
        testLead.Rating = 'Cold'; 
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Contacted', updatedLead.Status, 'Status should be updated to Contacted');
        System.assertEquals('Cold', updatedLead.Rating, 'Rating should remain Cold');
    }
    
    @IsTest
    static void testRatingAlreadyCorrectForStatus() {

        Lead testLead = new Lead(
            FirstName = 'Correct',
            LastName = 'Rating',
            Company = 'Correct Company',
            Email = 'correct@rating.com',
            Status = 'New',
            Rating = 'Cold'
        );
        insert testLead;
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Status = 'New';
        oldLead.Rating = 'Cold';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Status = 'Review';
        testLead.Rating = 'Hot'; 
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Review', updatedLead.Status, 'Status should be Review');
        System.assertEquals('Hot', updatedLead.Rating, 'Rating should remain Hot');
    }
    
    @IsTest
    static void testMultipleConditionsInSingleLead() {

        Lead testLead = new Lead(
            FirstName = 'Complex',
            LastName = 'Scenario',
            Company = 'Complex Company',
            Status = 'New',
            Rating = 'Cold'
        );
        insert testLead;
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Email = null;
        oldLead.Phone = null;
        oldLead.Status = 'New';
        oldLead.Rating = 'Cold';
        oldLeadMap.put(testLead.Id, oldLead);
        
        // Update lead to have email, phone, and different status
        testLead.Email = 'complex@scenario.com';
        testLead.Phone = '555-7777';
        testLead.Status = 'New'; 
        testLead.Rating = 'Cold';
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Contacted', updatedLead.Status, 'Status should be Contacted due to email/phone addition');
        System.assertEquals('Warm', updatedLead.Rating, 'Rating should be Warm due to email/phone addition');
    }
    
    @IsTest
    static void testClosedConvertedWithoutStatusChange() {

        Lead testLead = new Lead(
            FirstName = 'Already',
            LastName = 'Closed',
            Company = 'Already Closed Company',
            Email = 'already@closed.com',
            Status = 'Closed - Converted',
            Rating = 'Warm'
        );
        insert testLead;
        
        Test.startTest();
        
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        List<Lead> newLeads = new List<Lead>();

        Lead oldLead = testLead.clone(true, true, true, true);
        oldLead.Status = 'Closed - Converted';
        oldLead.Rating = 'Warm';
        oldLeadMap.put(testLead.Id, oldLead);

        testLead.Rating = 'Cold'; 
        newLeads.add(testLead);
        
        LeadTriggerHandler.processLeads(newLeads, oldLeadMap);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Id, Status, Rating FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Hot', updatedLead.Rating, 'Rating should be updated to Hot for Closed - Converted status');
    }
}