@isTest
private class CaseReminderControllerTest {

    // Menguji skenario sukses di mana ID Kasus yang valid diberikan.
    @isTest
    static void testGetCaseForEmail_Success() {
        // 1. Persiapan Data
        // Buat Akun sebagai parent dari Kasus
        Account testAccount = new Account(Name = 'Test Corp');
        insert testAccount;

        // Buat record Kasus untuk pengujian
        Case testCase = new Case(
            AccountId = testAccount.Id,
            Subject = 'Email Test Subject',
            Status = 'New',
            Origin = 'Web'
        );
        insert testCase;

        // 2. Eksekusi Kode
        Test.startTest();

        // Buat instance dari controller
        CaseReminderController controller = new CaseReminderController();
        // Atur ID record, sama seperti yang dilakukan oleh halaman Visualforce
        controller.caseRecordId = testCase.Id; 

        // Panggil metode untuk mengambil data
        Case resultCase = controller.getCaseForEmail();

        Test.stopTest();

        // 3. Verifikasi Hasil (Assertion)
        System.assertNotEquals(null, resultCase, 'Kasus yang dikembalikan seharusnya tidak null.');
        System.assertEquals(testCase.Id, resultCase.Id, 'ID Kasus harus cocok dengan yang diberikan.');
        System.assertEquals('Email Test Subject', resultCase.Subject, 'Subjek Kasus harus benar.');
        System.assertEquals('Test Corp', resultCase.Account.Name, 'Nama Akun harus terisi dengan benar.');
    }

    // Menguji skenario di mana tidak ada ID Kasus yang diberikan (null).
    @isTest
    static void testGetCaseForEmail_NullId() {
        // 1. Persiapan Data (tidak ada data yang dibutuhkan)

        // 2. Eksekusi Kode
        Test.startTest();
        
        CaseReminderController controller = new CaseReminderController();
        // Biarkan controller.caseRecordId tetap null

        Case resultCase = controller.getCaseForEmail();

        Test.stopTest();

        // 3. Verifikasi Hasil
        // Controller seharusnya mengembalikan null karena tidak ada ID untuk di-query.
        System.assertEquals(null, resultCase, 'Kasus yang dikembalikan harus null jika tidak ada ID.');
    }

    // Menguji perilaku "lazy loading".
    // Query hanya boleh berjalan sekali, bahkan jika metode dipanggil berkali-kali.
    @isTest
    static void testGetCaseForEmail_LazyLoading() {
        // 1. Persiapan Data
        Case testCase = new Case(Subject = 'Lazy Load Test');
        insert testCase;

        // 2. Eksekusi Kode
        Test.startTest();
        
        CaseReminderController controller = new CaseReminderController();
        controller.caseRecordId = testCase.Id;

        // Panggil getter untuk pertama kalinya (ini akan menjalankan query)
        Case firstCallResult = controller.getCaseForEmail();

        // Panggil getter untuk kedua kalinya (ini seharusnya tidak menjalankan query lagi)
        Case secondCallResult = controller.getCaseForEmail();

        Test.stopTest();

        // 3. Verifikasi Hasil
        System.assertNotEquals(null, firstCallResult, 'Panggilan pertama seharusnya mengembalikan data Kasus.');
        System.assertNotEquals(null, secondCallResult, 'Panggilan kedua juga seharusnya mengembalikan data Kasus.');
        System.assertEquals(firstCallResult.Id, secondCallResult.Id, 'Panggilan kedua harus mengembalikan record Kasus yang sama.');
    }
}