@isTest
private class CustomerJourneyControllerTest {

    // Setup data umum yang bisa digunakan oleh beberapa metode tes
    @TestSetup
    static void makeData() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'Universal Containers'),
            new Account(Name = 'Global Media'),
            new Account(Name = 'Pied Piper Inc.')
        };
        insert accs;
    }

    // --- Tes untuk metode searchAccounts ---

    @isTest
    static void testSearchAccounts_Success() {
        Test.startTest();
        List<Account> results = CustomerJourneyController.searchAccounts('Universal');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Seharusnya menemukan 1 akun.');
        System.assertEquals('Universal Containers', results[0].Name, 'Nama akun tidak cocok.');
    }

    @isTest
    static void testSearchAccounts_NoResults() {
        Test.startTest();
        List<Account> results = CustomerJourneyController.searchAccounts('NonExistentCompany');
        Test.stopTest();

        System.assertEquals(true, results.isEmpty(), 'Seharusnya tidak menemukan akun dan mengembalikan daftar kosong.');
    }

    @isTest
    static void testSearchAccounts_SpecialChars() {
        // Buat akun dengan tanda kutip untuk menguji escape character
        // DIUBAH: Menggunakan kutip tunggal (') dan escape character (\)
        Account specialCharAcc = new Account(Name = 'O\'Malley\'s Construction');
        insert specialCharAcc;

        Test.startTest();
        // DIUBAH: Menggunakan kutip tunggal (') dan escape character (\)
        List<Account> results = CustomerJourneyController.searchAccounts('O\'Malley\'s');
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Harus bisa menemukan akun dengan karakter khusus.');
    }

    // --- Tes untuk metode getJourneyData ---

    @isTest
    static void testGetJourneyData_FromConvertedLead() {
        // 1. Buat dan konversi Lead
        Lead l = new Lead(LastName='Musk', Company='Tesla', Status='Open - Not Contacted');
        insert l;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus('Closed - Converted');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess(), 'Konversi Lead seharusnya berhasil.');

        Id accountId = lcr.getAccountId();
        
        // Buat opportunity tambahan untuk akun yang sama
        Opportunity opp = new Opportunity(
            Name = 'Model Y Fleet',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(3)
        );
        insert opp;
        
        Test.startTest();
        CustomerJourneyController.JourneyWrapper result = CustomerJourneyController.getJourneyData(accountId);
        Test.stopTest();

        // Verifikasi semua data dalam wrapper
        System.assertNotEquals(null, result, 'Hasil wrapper tidak boleh null.');
        System.assertNotEquals(null, result.acc, 'Data Akun seharusnya terisi.');
        System.assertEquals(accountId, result.acc.Id, 'ID Akun tidak cocok.');
        System.assertEquals(2, result.opps.size(), 'Seharusnya ada 2 opportunity (1 dari konversi, 1 dibuat manual).');
        System.assertNotEquals(null, result.originLead, 'Lead asal seharusnya ditemukan.');
        System.assertEquals(l.Id, result.originLead.Id, 'ID Lead asal tidak cocok.');
        System.assertEquals(true, result.wasConvertedFromLead, 'Flag wasConvertedFromLead seharusnya true.');
    }

    @isTest
    static void testGetJourneyData_NotFromLead() {
        // Ambil akun yang dibuat di @TestSetup, yang tidak berasal dari Lead
        Account acc = [SELECT Id FROM Account WHERE Name = 'Global Media' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Ad Campaign',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30)
        );
        insert opp;

        Test.startTest();
        CustomerJourneyController.JourneyWrapper result = CustomerJourneyController.getJourneyData(acc.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Hasil wrapper tidak boleh null.');
        System.assertNotEquals(null, result.acc, 'Data Akun seharusnya terisi.');
        System.assertEquals(1, result.opps.size(), 'Seharusnya ada 1 opportunity.');
        System.assertEquals(null, result.originLead, 'Lead asal seharusnya tidak ada (null).');
        System.assertEquals(false, result.wasConvertedFromLead, 'Flag wasConvertedFromLead seharusnya false.');
    }

    @isTest
    static void testGetJourneyData_Exception() {
        Exception caughtException = null;

        Test.startTest();
        try {
            // Panggil dengan ID yang tidak valid (formatnya benar tapi tidak ada di database)
            CustomerJourneyController.getJourneyData('001000000000000AAA');
        } catch (AuraHandledException e) {
            caughtException = e;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, caughtException, 'Seharusnya melempar AuraHandledException.');
        System.assert(caughtException.getMessage().contains('List has no rows for assignment to SObject'), 'Pesan error tidak sesuai harapan.');
    }
}