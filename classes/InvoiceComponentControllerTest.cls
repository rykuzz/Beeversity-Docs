@isTest
private class InvoiceComponentControllerTest {

    // Simpan ID record yang dibuat di setup untuk digunakan di metode tes
    private static Id testOppId;
    private static Id testContactId;

    // @TestSetup membuat data uji yang kompleks sekali saja
    @TestSetup
    static void makeData() {
        // 1. Buat data dasar
        Account acc = new Account(Name='Test Corp Inc.');
        insert acc;

        Contact con = new Contact(LastName='Smith', AccountId=acc.Id);
        insert con;

        Product2 prod = new Product2(Name='Test Product', IsActive=true);
        insert prod;

        // 2. Dapatkan Pricebook standar dan buat Pricebook Entry
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;

        // 3. Buat Opportunity dan produknya (OpportunityLineItem)
        Opportunity opp = new Opportunity(
            Name = 'Test Invoice Opp',
            AccountId = acc.Id,
            Pricebook2Id = pricebookId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 1000
        );
        insert oli;

        // 4. Tautkan Kontak ke Opportunity sebagai Kontak Utama
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = con.Id,
            IsPrimary = true
        );
        insert ocr;

        // Simpan ID untuk digunakan di tes lain
        testOppId = opp.Id;
        testContactId = con.Id;
    }

    // Tes skenario sukses dengan semua data lengkap
    @isTest
    static void testLoadData_Success() {
        Test.startTest();
        // Buat instance controller
        InvoiceComponentController controller = new InvoiceComponentController();
        // Atur ID, yang akan memicu pemuatan data
        controller.opportunityId = testOppId;
        Test.stopTest();

        // Verifikasi bahwa semua data berhasil dimuat
        System.assertNotEquals(null, controller.opp, 'Opportunity seharusnya berhasil dimuat.');
        System.assertEquals(testOppId, controller.opp.Id, 'ID Opportunity tidak cocok.');
        System.assertEquals(false, controller.opp.OpportunityLineItems.isEmpty(), 'Opportunity Line Items seharusnya ada.');
        System.assertNotEquals(null, controller.primaryContact, 'Kontak Utama seharusnya berhasil dimuat.');
        System.assertEquals(testContactId, controller.primaryContact.Id, 'ID Kontak Utama tidak cocok.');
    }

    // Tes skenario di mana Opportunity tidak memiliki Kontak Utama
    @isTest
    static void testLoadData_NoPrimaryContact() {
        // Buat Opportunity baru tanpa menautkan Kontak Utama
        Opportunity oppWithoutContact = [SELECT Id FROM Opportunity WHERE Id = :testOppId];
        
        Test.startTest();
        InvoiceComponentController controller = new InvoiceComponentController();
        controller.opportunityId = oppWithoutContact.Id;
        Test.stopTest();
        
        // Verifikasi bahwa Opportunity dimuat, tetapi Kontak Utama null
        System.assertNotEquals(null, controller.opp, 'Opportunity seharusnya berhasil dimuat.');
        // Hapus OCR agar test ini tidak terpengaruh data setup
        delete [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :oppWithoutContact.Id];
        // Panggil ulang
        controller.opportunityId = oppWithoutContact.Id;
        System.assertEquals(null, controller.primaryContact, 'Kontak Utama seharusnya null.');
    }

    // Tes untuk memastikan query tidak dijalankan berulang kali
    @isTest
    static void testLazyLoading() {
        InvoiceComponentController controller = new InvoiceComponentController();
        
        Test.startTest();
        // Panggilan pertama, data akan dimuat dan query akan berjalan
        controller.opportunityId = testOppId;
        
        Integer queriesAfterFirstCall = Limits.getQueries();
        
        // Panggilan kedua dengan ID yang sama
        controller.opportunityId = testOppId;
        
        Integer queriesAfterSecondCall = Limits.getQueries();
        Test.stopTest();

        // Verifikasi tidak ada query tambahan yang berjalan pada panggilan kedua
        System.assertEquals(queriesAfterFirstCall, queriesAfterSecondCall, 'Seharusnya tidak ada query SOQL tambahan pada panggilan kedua.');
    }
    
    // Tes penanganan error ketika ID tidak valid
    @isTest
    static void testLoadData_ExceptionHandling() {
        Test.startTest();
        InvoiceComponentController controller = new InvoiceComponentController();
        // Atur dengan ID yang tidak ada di database
        controller.opportunityId = '006000000000000AAA';
        Test.stopTest();
        
        // Verifikasi bahwa properti menjadi null setelah error
        System.assertEquals(null, controller.opp, 'Opportunity seharusnya null setelah terjadi error.');
        System.assertEquals(null, controller.primaryContact, 'Kontak Utama seharusnya null setelah terjadi error.');
    }
}