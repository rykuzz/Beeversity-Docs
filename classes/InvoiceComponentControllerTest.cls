@isTest
private class InvoiceComponentControllerTest {

    /**
     * @description Metode @TestSetup untuk membuat serangkaian data kompleks sekali saja.
     * Data ini akan tersedia untuk semua metode tes di kelas ini.
     */
    @TestSetup
    static void makeData() {
        // 1. Buat Akun dan Kontak
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(LastName = 'Wijaya', AccountId = acc.Id, Email = 'test@wijaya.com');
        insert con;

        // 2. Buat Produk dan entri Pricebook standar
        Product2 prod1 = new Product2(Name = 'Produk A', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Produk B', IsActive = true);
        insert new List<Product2>{prod1, prod2};

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod1.Id,
            UnitPrice = 1000, IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod2.Id,
            UnitPrice = 2500, IsActive = true
        );
        insert new List<PricebookEntry>{pbe1, pbe2};

        // 3. Buat Opportunity dengan semua data terkait (untuk skenario sukses)
        Opportunity oppWithContact = new Opportunity(
            Name = 'Opp Lengkap', AccountId = acc.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addMonths(1),
            Pricebook2Id = pricebookId
        );
        insert oppWithContact;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = oppWithContact.Id, ContactId = con.Id, IsPrimary = true
        );
        insert ocr;
        
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = oppWithContact.Id, PricebookEntryId = pbe1.Id,
            Quantity = 2, UnitPrice = 1000
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = oppWithContact.Id, PricebookEntryId = pbe2.Id,
            Quantity = 5, UnitPrice = 2500
        );
        insert new List<OpportunityLineItem>{oli1, oli2};
        
        // 4. Buat Opportunity lain tanpa Kontak Utama (untuk skenario tes lain)
        Opportunity oppWithoutContact = new Opportunity(
            Name = 'Opp Tanpa Kontak', AccountId = acc.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addMonths(1)
        );
        insert oppWithoutContact;
    }

    /**
     * @description Tes skenario sukses di mana Opportunity memiliki Kontak Utama dan Line Items.
     */
    @isTest
    static void testController_HappyPath() {
        // Arrange: Ambil ID Opportunity yang sudah lengkap dari data setup
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Opp Lengkap' LIMIT 1];

        Test.startTest();
        // Act: Buat instance controller dan atur opportunityId untuk memicu pemuatan data
        InvoiceComponentController controller = new InvoiceComponentController();
        controller.opportunityId = opp.Id;
        Test.stopTest();

        // Assert: Verifikasi bahwa semua data dimuat dengan benar
        System.assertNotEquals(null, controller.opp, 'Objek Opportunity seharusnya tidak null.');
        System.assertNotEquals(null, controller.primaryContact, 'Objek Kontak Utama seharusnya tidak null.');
        System.assertEquals(opp.Id, controller.opp.Id, 'ID Opportunity yang dimuat tidak cocok.');
        System.assertEquals('Wijaya', controller.primaryContact.LastName, 'Nama Kontak Utama tidak cocok.');
        System.assertEquals(2, controller.opp.OpportunityLineItems.size(), 'Jumlah Opportunity Line Item seharusnya 2.');
    }

    /**
     * @description Tes skenario di mana Opportunity ada tetapi tidak memiliki Kontak Utama.
     * Ini menguji cabang logika 'if (!roles.isEmpty())'.
     */
    @isTest
    static void testController_NoPrimaryContact() {
        // Arrange: Ambil ID Opportunity yang tidak memiliki kontak
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Opp Tanpa Kontak' LIMIT 1];

        Test.startTest();
        // Act: Atur ID pada controller
        InvoiceComponentController controller = new InvoiceComponentController();
        controller.opportunityId = opp.Id;
        Test.stopTest();

        // Assert: Verifikasi bahwa Opportunity dimuat tetapi Kontak Utama null
        System.assertNotEquals(null, controller.opp, 'Objek Opportunity seharusnya dimuat.');
        System.assertEquals(null, controller.primaryContact, 'Objek Kontak Utama seharusnya null karena tidak ada.');
    }
    
    /**
     * @description Tes skenario di mana ID yang diberikan tidak valid (tidak ada di database).
     * Ini menguji penanganan hasil query kosong dan perilaku blok 'catch'.
     */
    @isTest
    static void testController_InvalidId() {
        Test.startTest();
        // Act: Atur ID palsu pada controller
        InvoiceComponentController controller = new InvoiceComponentController();
        controller.opportunityId = '006000000000000AAA'; // ID yang tidak ada
        Test.stopTest();

        // Assert: Verifikasi bahwa properti tetap null, seperti yang diharapkan setelah query gagal atau blok catch.
        System.assertEquals(null, controller.opp, 'Objek Opportunity seharusnya null untuk ID yang tidak valid.');
        System.assertEquals(null, controller.primaryContact, 'Objek Kontak Utama seharusnya null untuk ID yang tidak valid.');
    }

    /**
     * @description Tes logika efisiensi untuk memastikan query tidak dijalankan ulang jika ID yang sama diatur lagi.
     */
    @isTest
    static void testController_SetIdTwice() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Opp Lengkap' LIMIT 1];
        InvoiceComponentController controller = new InvoiceComponentController();
        
        // Act (First time)
        controller.opportunityId = opp.Id;
        
        // Assert (First time)
        System.assertNotEquals(null, controller.opp, 'Data seharusnya dimuat pada panggilan pertama.');

        Test.startTest();
        // Hitung jumlah query SOQL sebelum mengatur ID untuk kedua kalinya
        Integer queriesBefore = Limits.getQueries();
        
        // Act (Second time)
        controller.opportunityId = opp.Id; // Atur ID yang sama lagi
        
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Assert (Second time)
        System.assertEquals(0, queriesAfter - queriesBefore, 'Seharusnya tidak ada query SOQL baru yang dijalankan saat mengatur ID yang sama lagi.');
    }
}
