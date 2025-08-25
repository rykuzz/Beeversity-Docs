@isTest
private class AccountSummaryControllerTest {

    private static User testUser;

    @TestSetup
    static void makeData() {
        // Buat pengguna uji yang akan menjadi pemilik sebagian besar data
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        testUser = new User(
            Alias = 'testu', Email = 'testuser@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'Testington', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@testorg.com'
        );
        insert testUser;

        // Jalankan pembuatan data sebagai pengguna ini
        System.runAs(testUser) {
            try {
                List<Account> accountsToInsert = new List<Account>();

                // 1. Akun Lengkap (Healthy)
                Account healthyAcc = new Account(
                    Name = 'Healthy Corp', Type = 'Customer - Direct', Industry = 'Technology',
                    Phone = '123-456-7890', Website = 'http://healthy.com', BillingStreet = '123 Main St',
                    BillingCity = 'San Francisco', AnnualRevenue = 5000000, NumberOfEmployees = 250,
                    Description = 'A well-documented company.'
                    // JIKA PERLU, TAMBAHKAN FIELD WAJIB DARI ORGANISASI ANDA DI SINI
                    // Contoh: , Rating = 'Hot'
                );
                accountsToInsert.add(healthyAcc);

                // 2. Akun Kurang (At-Risk)
                Account atRiskAcc = new Account(
                    Name = 'At-Risk Industries', Type = 'Prospect', Industry = 'Consulting',
                    Phone = '987-654-3210', AnnualRevenue = 1000000
                    // JIKA PERLU, TAMBAHKAN FIELD WAJIB DARI ORGANISASI ANDA DI SINI
                );
                accountsToInsert.add(atRiskAcc);

                // 3. Akun Minim (Critical)
                Account criticalAcc = new Account(
                    Name = 'Critical Ventures'
                    // JIKA PERLU, TAMBAHKAN FIELD WAJIB DARI ORGANISASI ANDA DI SINI
                );
                accountsToInsert.add(criticalAcc);

                insert accountsToInsert;

                // Buat data relasi
                Contact c = new Contact(LastName = 'Smith', AccountId = healthyAcc.Id);
                Opportunity o = new Opportunity(Name = 'Big Deal', StageName = 'Prospecting', CloseDate = Date.today().addMonths(1), AccountId = healthyAcc.Id);
                Case cs = new Case(Subject = 'Test Case', Status = 'New', AccountId = healthyAcc.Id);
                insert new List<SObject>{c, o, cs};

            } catch (Exception e) {
                // INI AKAN MEMBERI TAHU KITA PENYEBAB MASALAHNYA
                System.debug(LoggingLevel.ERROR, '!!! ERROR SAAT SETUP TEST: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, '!!! DETAIL ERROR: ' + e.getStackTraceString());
            }
        }
    }

    @isTest
    static void testGetAccountScorecard_SuccessPaths() {
        Test.startTest();
        System.runAs(testUser) {
            // Skenario 1: Pengguna dengan beberapa akun
            AccountSummaryController.AccountScorecardResult result = AccountSummaryController.getAccountScorecard();

            // Verifikasi hasil
            System.assertEquals(3, result.totalAccountsProcessed, 'Harusnya memproses 3 akun.');
            System.assertEquals(1, result.healthyAccounts.size(), 'Harusnya ada 1 akun "healthy".');
            System.assertEquals(1, result.atRiskAccounts.size(), 'Harusnya ada 1 akun "at-risk".');
            System.assertEquals(1, result.criticalAccounts.size(), 'Harusnya ada 1 akun "critical".');
            System.assertEquals('Healthy Corp', result.healthyAccounts[0].Name, 'Nama akun healthy tidak sesuai.');
            
            // Verifikasi juga metode refresh
            AccountSummaryController.AccountScorecardResult refreshResult = AccountSummaryController.refreshAccountScorecard();
            System.assertEquals(3, refreshResult.totalAccountsProcessed, 'Hasil refresh harusnya sama.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountScorecard_NoAccounts() {
        // Buat pengguna baru yang tidak punya akun sama sekali
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User userWithoutAccounts = new User(
            Alias = 'noacc', Email = 'noacc@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'NoAccounts', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'noaccounts' + System.currentTimeMillis() + '@testorg.com'
        );
        insert userWithoutAccounts;

        Test.startTest();
        System.runAs(userWithoutAccounts) {
            // Panggil metode sebagai pengguna tanpa akun untuk menguji cabang 'nol'/'kosong'
            AccountSummaryController.AccountScorecardResult result = AccountSummaryController.getAccountScorecard();

            // Verifikasi bahwa hasilnya kosong tapi tidak error
            System.assertEquals(0, result.totalAccountsProcessed, 'Total akun harusnya 0.');
            System.assertEquals(true, result.healthyAccounts.isEmpty(), 'Daftar healthy harus kosong.');
            System.assertEquals(0, result.summaryData[0].total, 'Jumlah di ringkasan harus 0.');
            System.assertEquals(0, result.summaryData[0].percentage, 'Persentase harus 0.');
        }
        Test.stopTest();
    }

    @isTest
    static void testSuggestions_EdgeCases() {
        // TUJUAN: Menguji cabang logika spesifik dengan memanggil getAccountCompletionSuggestions
        
        // 1. Setup Pengguna Tidak Aktif
        User userToDeactivate = new User(
            Alias = 'inact', Email = 'inactive@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'Inactive', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = testUser.ProfileId, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'inactiveuser' + System.currentTimeMillis() + '@testorg.com',
            IsActive = true // Buat aktif dulu agar bisa jadi owner
        );
        insert userToDeactivate;

        Account accWithInactiveOwner = new Account(Name = 'Inactive Owner Account', OwnerId = userToDeactivate.Id);
        insert accWithInactiveOwner;

        // Nonaktifkan pengguna SETELAH akun dibuat
        userToDeactivate.IsActive = false;
        update userToDeactivate;

        // 2. Setup Akun dengan nilai 0
        Account accWithZeroValues = new Account(
            Name = 'Zero Value Corp', OwnerId = testUser.Id,
            AnnualRevenue = 0, NumberOfEmployees = 0
        );
        insert accWithZeroValues;
        
        Test.startTest();
        
        // Uji kasus pemilik tidak aktif
        Map<String, Object> inactiveOwnerResult = AccountSummaryController.getAccountCompletionSuggestions(accWithInactiveOwner.Id);
        System.assert(((String)inactiveOwnerResult.get('missingFields')).contains('Active Owner'), 'Harusnya mendeteksi Owner tidak aktif.');
        
        // Uji kasus nilai 0
        Map<String, Object> zeroValueResult = AccountSummaryController.getAccountCompletionSuggestions(accWithZeroValues.Id);
        System.assert(((String)zeroValueResult.get('missingFields')).contains('Annual Revenue'), 'Harusnya mendeteksi Annual Revenue 0.');
        System.assert(((String)zeroValueResult.get('missingFields')).contains('Number of Employees'), 'Harusnya mendeteksi Number of Employees 0.');
        
        Test.stopTest();
    }

    @isTest
    static void testExceptionHandling() {
        System.runAs(testUser) {
            // Skenario 1: Uji blok catch di getAccountScorecard dengan memicu governor limit
            Test.startTest();
            try {
                // Habiskan batas query SOQL
                for(Integer i = 0; i < 100; i++) { 
                    List<Account> accs = [SELECT Id FROM Account LIMIT 1]; 
                }
            } catch(Exception e) {
                // Governor limit exception diharapkan terjadi di sini
            }

            AccountSummaryController.AccountScorecardResult limitResult = AccountSummaryController.getAccountScorecard();
            Test.stopTest();

            // Verifikasi bahwa blok catch di controller berfungsi
            System.assertNotEquals(null, limitResult, 'Hasil tidak boleh null saat terjadi limit exception.');
            System.assertEquals(0, limitResult.totalAccountsProcessed, 'Total akun harus 0 saat error.');
            System.assertEquals('Data Lengkap', limitResult.summaryData[0].label, 'Harus mengembalikan data ringkasan default dari blok catch.');

            // Skenario 2: Uji blok catch di getAccountCompletionSuggestions dengan ID yang tidak valid
            Map<String, Object> invalidIdResult = AccountSummaryController.getAccountCompletionSuggestions('001000000000000');
            System.assertEquals('Error retrieving data', invalidIdResult.get('missingFields'), 'Harus menangani ID yang tidak valid.');
        }
    }
}