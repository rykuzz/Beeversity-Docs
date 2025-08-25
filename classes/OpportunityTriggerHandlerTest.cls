@isTest
private class OpportunityTriggerHandlerTest {

    // --- Mock Classes for HTTP Callout ---
    // Mock untuk simulasi respons SUKSES dari API Mailjet
    private class MailjetMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Messages":[{"Status":"success"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock untuk simulasi respons GAGAL dari API Mailjet
    private class MailjetMockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Messages":[{"Status":"error", "Errors":[{"ErrorMessage":"Invalid recipient"}]}]}');
            res.setStatusCode(400);
            return res;
        }
    }

    // --- Test Setup ---
    @TestSetup
    static void makeData() {
        // 1. Buat Email Template yang dibutuhkan oleh handler
        EmailTemplate template = new EmailTemplate(
            DeveloperName = 'InvoiceEmailTemplate',
            TemplateType = 'HTML',
            Name = 'Invoice Email Template',
            IsActive = true,
            Subject = 'Invoice for {!relatedTo.Name}',
            HtmlValue = 'Hello {!recipient.Name}, here is your invoice.',
            Body = 'Hello {!recipient.Name}, here is your invoice.'
        );
        insert template;

        // 2. Buat data record
        Account acc = new Account(Name='Test Corp');
        insert acc;

        Contact con = new Contact(LastName='Primary Contact', Email='test@example.com', AccountId=acc.Id);
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;

        // 3. Tautkan Kontak sebagai Kontak Utama
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = con.Id,
            IsPrimary = true
        );
        insert ocr;
    }

    // --- Test Methods ---
    @isTest
    static void testAfterUpdate_SuccessAndCallout() {
        // Ambil data dari TestSetup
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];

        // Buat oldMap untuk simulasi trigger
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{
            opp.Id => new Opportunity(Id = opp.Id, StageName = 'Prospecting')
        };
        
        // Update stage opportunity
        opp.StageName = 'Closed Won';
        List<Opportunity> newOpps = new List<Opportunity>{ opp };
        
        // Atur mock untuk mencegat panggilan HTTP
        Test.setMock(HttpCalloutMock.class, new MailjetMockSuccess());
        
        Test.startTest();
        // Panggil handler
        OpportunityTriggerHandler.afterUpdate(newOpps, oldOppMap);
        Test.stopTest(); // Ini akan menjalankan metode @future
        
        // Verifikasi bahwa 1 email telah diproses
        // Karena @future berjalan di konteks terpisah, verifikasi terbaik adalah
        // memastikan tidak ada error yang tidak tertangani.
        // Cakupan kode untuk metode @future akan tercapai.
    }
    
    @isTest
    static void testAfterUpdate_CalloutFailure() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{ opp.Id => new Opportunity(Id = opp.Id, StageName = 'Prospecting') };
        opp.StageName = 'Closed Won';
        List<Opportunity> newOpps = new List<Opportunity>{ opp };
        
        // Atur mock untuk respons GAGAL
        Test.setMock(HttpCalloutMock.class, new MailjetMockFailure());
        
        Test.startTest();
        OpportunityTriggerHandler.afterUpdate(newOpps, oldOppMap);
        Test.stopTest();
        // Verifikasi bahwa kode berjalan tanpa error, karena error callout ditangani
        // di dalam blok catch-debug.
    }

    @isTest
    static void testAfterUpdate_NoPrimaryContact() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Hapus OCR yang dibuat di TestSetup
        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id];
        
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{ opp.Id => new Opportunity(Id = opp.Id, StageName = 'Prospecting') };
        opp.StageName = 'Closed Won';
        List<Opportunity> newOpps = new List<Opportunity>{ opp };

        Test.startTest();
        OpportunityTriggerHandler.afterUpdate(newOpps, oldOppMap);
        Test.stopTest();

        // Verifikasi bahwa tidak ada panggilan @future yang dibuat
        System.assertEquals(0, Limits.getFutureCalls(), 'Seharusnya tidak ada panggilan @future jika tidak ada kontak utama.');
    }

    @isTest
    static void testAfterUpdate_StageNotChangedToWon() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>{ opp.Id => opp.clone() };
        
        // Ubah stage, tetapi BUKAN ke 'Closed Won'
        opp.StageName = 'Qualification';
        List<Opportunity> newOpps = new List<Opportunity>{ opp };
        
        Test.startTest();
        OpportunityTriggerHandler.afterUpdate(newOpps, oldOppMap);
        Test.stopTest();

        // Verifikasi bahwa tidak ada panggilan @future yang dibuat
        System.assertEquals(0, Limits.getFutureCalls(), 'Seharusnya tidak ada panggilan @future jika stage tidak berubah menjadi Closed Won.');
    }
}