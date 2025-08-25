@isTest
private class AccountSummaryControllerTest {

    // Metode @TestSetup untuk membuat data uji umum sekali saja
    @TestSetup
    static void makeData() {
        // 1. Buat pengguna uji untuk menjadi pemilik akun
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'testUser',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            CompanyName = 'Test Co',
            Title = 'Tester',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert testUser;

        // Jalankan pembuatan data sebagai pengguna uji
        System.runAs(testUser) {
            List<Account> accountsToCreate = new List<Account>();

            // 2. Buat akun 'Healthy' (skor tinggi)
            Account healthyAcc = new Account(
                Name = 'Healthy Corp',
                OwnerId = testUser.Id,
                Type = 'Customer - Direct',
                Industry = 'Technology',
                Phone = '1234567890',
                Website = 'www.healthycorp.com',
                BillingStreet = '123 Main St',
                BillingCity = 'San Francisco',
                AnnualRevenue = 5000000,
                NumberOfEmployees = 150,
                Description = 'A very complete and healthy account record.'
            );
            accountsToCreate.add(healthyAcc);

            // 3. Buat akun 'At Risk' (skor sedang)
            Account atRiskAcc = new Account(
                Name = 'At-Risk Industries',
                OwnerId = testUser.Id,
                Type = 'Partner',
                Phone = '9876543210',
                BillingStreet = '456 Market St',
                BillingCity = 'New York'
                // Industry, Website, Revenue, Employees, Description sengaja dikosongkan
            );
            accountsToCreate.add(atRiskAcc);

            // 4. Buat akun 'Critical' (skor rendah)
            Account criticalAcc = new Account(
                Name = 'Critical Ventures',
                OwnerId = testUser.Id
                // Hampir semua field dikosongkan
            );
            accountsToCreate.add(criticalAcc);

            insert accountsToCreate;

            // Tambahkan data terkait untuk Akun 'Healthy' agar mendapat skor penuh
            Contact c = new Contact(LastName = 'Test', AccountId = healthyAcc.Id);
            Opportunity o = new Opportunity(Name = 'Big Deal', StageName = 'Prospecting', CloseDate = Date.today().addMonths(1), AccountId = healthyAcc.Id);
            Case cs = new Case(Status = 'New', Origin = 'Web', AccountId = healthyAcc.Id);
            insert c;
            insert o;
            insert cs;
        }
    }

    // Tes skenario sukses utama: pengguna memiliki akun di semua kategori
    @isTest
    static void testGetAccountScorecard_SuccessScenario() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'testUser' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            AccountSummaryController.AccountScorecardResult result = AccountSummaryController.getAccountScorecard();
            Test.stopTest();

            // Verifikasi hasil
            System.assertNotEquals(null, result, 'Hasil tidak boleh null.');
            System.assertEquals(3, result.totalAccountsProcessed, 'Harusnya memproses 3 akun.');
            
            // Verifikasi jumlah di setiap kategori
            System.assertEquals(1, result.healthyAccounts.size(), 'Harusnya ada 1 akun "Healthy".');
            System.assertEquals(1, result.atRiskAccounts.size(), 'Harusnya ada 1 akun "At Risk".');
            System.assertEquals(1, result.criticalAccounts.size(), 'Harusnya ada 1 akun "Critical".');

            // Verifikasi detail akun "Healthy"
            AccountSummaryController.AccountData healthyData = result.healthyAccounts[0];
            System.assertEquals('Healthy Corp', healthyData.Name);
            System.assertEquals('Lengkap', healthyData.completenessLevel);
            System.assertEquals('Semua data lengkap', healthyData.missingFields, 'Akun Healthy seharusnya tidak memiliki data yang kurang.');
            System.assert(healthyData.completenessScore >= 80, 'Skor akun Healthy harus >= 80.');
            
            // Verifikasi detail akun "Critical"
            AccountSummaryController.AccountData criticalData = result.criticalAccounts[0];
            System.assertEquals('Critical Ventures', criticalData.Name);
            System.assertEquals('Minim', criticalData.completenessLevel);
            System.assert(criticalData.missingFields.contains('Type'), 'Akun Critical seharusnya kekurangan field Type.');
            System.assert(criticalData.missingFields.contains('Phone'), 'Akun Critical seharusnya kekurangan field Phone.');
            System.assert(criticalData.completenessScore <= 40, 'Skor akun Critical harus <= 40.');

            // Verifikasi data ringkasan (summary)
            System.assertEquals(3, result.summaryData.size(), 'Data ringkasan harus memiliki 3 item.');
            System.assertEquals('Data Lengkap', result.summaryData[0].label);
            System.assertEquals(1, result.summaryData[0].total);
        }
    }

    // Tes skenario di mana pengguna tidak memiliki akun sama sekali
    @isTest
    static void testGetAccountScorecard_NoAccountsForUser() {
        // Buat pengguna baru yang tidak memiliki akun
        User userWithoutAccounts = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'noAccounts',
            Email = 'noaccounts@example.com',
            Username = 'noaccounts' + System.currentTimeMillis() + '@example.com',
            Alias = 'noacc',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert userWithoutAccounts;

        System.runAs(userWithoutAccounts) {
            Test.startTest();
            AccountSummaryController.AccountScorecardResult result = AccountSummaryController.getAccountScorecard();
            Test.stopTest();

            // Verifikasi hasil untuk kasus tanpa data
            System.assertNotEquals(null, result, 'Hasil tidak boleh null.');
            System.assertEquals(0, result.totalAccountsProcessed, 'Total akun harus 0.');
            System.assertEquals(0, result.healthyAccounts.size(), 'List Healthy harus kosong.');
            System.assertEquals(0, result.atRiskAccounts.size(), 'List At Risk harus kosong.');
            System.assertEquals(0, result.criticalAccounts.size(), 'List Critical harus kosong.');
            System.assertEquals(0, result.summaryData[0].percentage, 'Persentase harus 0 jika tidak ada akun.');
        }
    }
    
    // Tes metode `getAccountCompletionSuggestions` untuk akun yang ada
    @isTest
    static void testGetAccountCompletionSuggestions_Success() {
        // Ambil akun At-Risk yang dibuat di TestSetup
        Account atRiskAccount = [SELECT Id FROM Account WHERE Name = 'At-Risk Industries' LIMIT 1];

        Test.startTest();
        Map<String, Object> suggestions = AccountSummaryController.getAccountCompletionSuggestions(atRiskAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, suggestions, 'Saran tidak boleh null.');
        
        // Verifikasi bahwa saran yang diberikan sudah benar
        String missingFields = (String)suggestions.get('missingFields');
        System.assert(missingFields.contains('Industry'), 'Harus menyarankan pengisian Industry.');
        System.assert(missingFields.contains('Website'), 'Harus menyarankan pengisian Website.');
        System.assert(missingFields.contains('Annual Revenue'), 'Harus menyarankan pengisian Annual Revenue.');
        System.assert(missingFields.contains('Contacts'), 'Harus menyarankan penambahan Kontak.');
    }

    // Tes metode `getAccountCompletionSuggestions` jika ID akun tidak valid
    @isTest
    static void testGetAccountCompletionSuggestions_InvalidId() {
        Test.startTest();
        // Gunakan ID yang tidak ada di database
        Map<String, Object> suggestions = AccountSummaryController.getAccountCompletionSuggestions('001000000000000AAA');
        Test.stopTest();

        // Verifikasi bahwa metode menangani error dengan benar sesuai blok catch
        System.assertNotEquals(null, suggestions);
        System.assertEquals(0, suggestions.get('score'), 'Skor harus 0 untuk ID yang tidak valid.');
        System.assertEquals('Error retrieving data', suggestions.get('missingFields'), 'Pesan error harus sesuai.');
        System.assertEquals('Unknown', suggestions.get('level'), 'Level harus Unknown untuk error.');
    }
    
    // Tes metode refresh, yang seharusnya berperilaku sama dengan getAccountScorecard
    @isTest
    static void testRefreshAccountScorecard() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'testUser' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            // Panggil metode refresh
            AccountSummaryController.AccountScorecardResult result = AccountSummaryController.refreshAccountScorecard();
            Test.stopTest();

            // Lakukan verifikasi yang sama dengan tes utama
            System.assertNotEquals(null, result);
            System.assertEquals(3, result.totalAccountsProcessed, 'Metode refresh harus memproses 3 akun.');
            System.assertEquals(1, result.healthyAccounts.size(), 'Metode refresh harus menemukan 1 akun "Healthy".');
        }
    }
}
