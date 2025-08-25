@isTest
private class ContactSummaryControllerTest {

    // Tes skenario di mana Kontak memiliki relasi Kasus dan Opportunity.
    @isTest
    static void testController_WithRelatedRecords() {
        // 1. PERSIAPAN DATA
        Account acc = new Account(Name='Test Account');
        insert acc;

        Contact con = new Contact(LastName='SummaryTest', AccountId=acc.Id);
        insert con;

        // Buat Kasus yang terkait dengan Kontak
        Case c = new Case(ContactId=con.Id, Subject='Test Case', Status='New');
        insert c;

        // Buat Opportunity dan tautkan ke Kontak melalui OpportunityContactRole
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id, StageName='Prospecting', CloseDate=Date.today().addMonths(1));
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole(ContactId=con.Id, OpportunityId=opp.Id);
        insert ocr;

        // 2. EKSEKUSI
        Test.startTest();

        // Siapkan konteks halaman Visualforce dan parameter URL 'id'
        // DIUBAH: Menggunakan referensi halaman generik
        PageReference pageRef = new PageReference('/apex/dummyPage'); 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', con.Id);

        // Buat StandardSetController yang dibutuhkan oleh konstruktor
        ApexPages.StandardSetController stdSetCtrl = new ApexPages.StandardSetController(new List<Contact>{con});

        // Buat instance dari controller Anda
        ContactSummaryController controller = new ContactSummaryController(stdSetCtrl);

        Test.stopTest();

        // 3. VERIFIKASI HASIL (ASSERTION)
        System.assertNotEquals(null, controller.contact, 'Kontak seharusnya berhasil diambil.');
        System.assertEquals(con.Id, controller.contact.Id, 'ID Kontak tidak cocok.');
        System.assertEquals(Date.today(), controller.generatedDate, 'Tanggal generate harus hari ini.');

        // Verifikasi Kasus
        System.assertEquals(false, controller.relatedCases.isEmpty(), 'Daftar Kasus seharusnya tidak kosong.');
        System.assertEquals(1, controller.relatedCases.size(), 'Seharusnya ada 1 Kasus.');
        System.assertEquals(true, controller.hasCases, 'hasCases seharusnya bernilai true.');

        // Verifikasi Opportunity
        System.assertEquals(false, controller.relatedOpps.isEmpty(), 'Daftar Opportunity seharusnya tidak kosong.');
        System.assertEquals(1, controller.relatedOpps.size(), 'Seharusnya ada 1 Opportunity Contact Role.');
        System.assertEquals(true, controller.hasOpportunities, 'hasOpportunities seharusnya bernilai true.');
    }

    // Tes skenario di mana Kontak TIDAK memiliki relasi apa pun.
    @isTest
    static void testController_WithoutRelatedRecords() {
        // 1. PERSIAPAN DATA
        Contact con = new Contact(LastName='NoRelationsTest');
        insert con;
        // Tidak ada Kasus atau Opportunity yang dibuat untuk kontak ini

        // 2. EKSEKUSI
        Test.startTest();

        // Siapkan konteks halaman Visualforce
        // DIUBAH: Menggunakan referensi halaman generik
        PageReference pageRef = new PageReference('/apex/dummyPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', con.Id);

        // Buat StandardSetController
        ApexPages.StandardSetController stdSetCtrl = new ApexPages.StandardSetController(new List<Contact>{con});

        // Buat instance dari controller Anda
        ContactSummaryController controller = new ContactSummaryController(stdSetCtrl);

        Test.stopTest();

        // 3. VERIFIKASI HASIL
        System.assertNotEquals(null, controller.contact, 'Kontak seharusnya berhasil diambil.');

        // Verifikasi Kasus (harus kosong)
        System.assertEquals(true, controller.relatedCases.isEmpty(), 'Daftar Kasus seharusnya kosong.');
        System.assertEquals(false, controller.hasCases, 'hasCases seharusnya bernilai false.');

        // Verifikasi Opportunity (harus kosong)
        System.assertEquals(true, controller.relatedOpps.isEmpty(), 'Daftar Opportunity seharusnya kosong.');
        System.assertEquals(false, controller.hasOpportunities, 'hasOpportunities seharusnya bernilai false.');
    }
}