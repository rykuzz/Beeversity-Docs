@isTest
private class AccountHealthControllerTest {

    @TestSetup
    static void makeData() {
        Account baseAccount = new Account(Name = 'Base Test Account');
        insert baseAccount;
    }

    @isTest
    static void testPerfectHealthScore() {
        // --- GIVEN (Persiapan Data) ---
        Account acc = [SELECT Id FROM Account WHERE Name = 'Base Test Account' LIMIT 1];
        
        // Update Akun dengan data lengkap
        acc.Website = 'www.perfect.com';
        acc.Industry = 'Technology';
        acc.NumberOfEmployees = 1000;
        // DIUBAH: Hapus baris LastActivityDate dari sini
        update acc;

        // DIUBAH: Buat record Task untuk mengatur LastActivityDate secara tidak langsung
        Task recentActivity = new Task(
            WhatId = acc.Id,
            Subject = 'Recent Test Task',
            ActivityDate = Date.today().addDays(-10) // Aktivitas baru (< 30 hari)
        );
        insert recentActivity;

        // Buat Opportunity dengan nilai sangat tinggi
        Opportunity opp = new Opportunity(
            Name = 'Mega Deal',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(2),
            Amount = 600000000 
        );
        insert opp;
        
        // --- WHEN (Eksekusi Kode) ---
        Test.startTest();
        // Query di dalam controller akan mengambil LastActivityDate yang sudah diperbarui oleh sistem
        AccountHealthController.AccountHealthDetails result = AccountHealthController.getAccountHealthDetails(acc.Id);
        Test.stopTest();

        // --- THEN (Verifikasi Hasil) ---
        // Perhitungan skor tetap sama
        // Total = 20 (completeness) + 40 (opps) + 30 (activity) + 10 (cases) = 100
        System.assertEquals(100, result.overallHealthScore, 'Skor kesehatan keseluruhan seharusnya 100.');
        System.assertEquals(20, result.completenessScore, 'Skor kelengkapan seharusnya 20.');
        System.assertEquals(1, result.openOppsCount, 'Jumlah opportunity terbuka seharusnya 1.');
        System.assertEquals(0, result.openCasesCount, 'Jumlah kasus terbuka seharusnya 0.');
        System.assertEquals(true, result.missingFields.isEmpty(), 'Seharusnya tidak ada field yang hilang.');
    }

    @isTest
    static void testPoorHealthScore() {
        // --- GIVEN (Persiapan Data) ---
        Account acc = [SELECT Id FROM Account WHERE Name = 'Base Test Account' LIMIT 1];

        // DIUBAH: Buat record Task dengan tanggal lama untuk LastActivityDate
        Task oldActivity = new Task(
            WhatId = acc.Id,
            Subject = 'Old Test Task',
            ActivityDate = Date.today().addDays(-120) // Aktivitas lama (> 90 hari)
        );
        insert oldActivity;

        // Buat Opportunity dengan nilai kecil
        Opportunity opp = new Opportunity(
            Name = 'Small Deal',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Amount = 50000
        );
        insert opp;

        // Buat banyak kasus terbuka
        List<Case> cases = new List<Case>{
            new Case(AccountId = acc.Id, Status = 'New', Subject = 'Problem 1'),
            new Case(AccountId = acc.Id, Status = 'Working', Subject = 'Problem 2'),
            new Case(AccountId = acc.Id, Status = 'New', Subject = 'Problem 3')
        };
        insert cases;

        // --- WHEN (Eksekusi Kode) ---
        Test.startTest();
        AccountHealthController.AccountHealthDetails result = AccountHealthController.getAccountHealthDetails(acc.Id);
        Test.stopTest();

        // --- THEN (Verifikasi Hasil) ---
        // Total = 0 (completeness) + 10 (opps) + 0 (activity) + 0 (cases) = 10
        System.assertEquals(10, result.overallHealthScore, 'Skor kesehatan keseluruhan seharusnya 10.');
        System.assertEquals(0, result.completenessScore, 'Skor kelengkapan seharusnya 0.');
        System.assertEquals(3, result.openCasesCount, 'Jumlah kasus terbuka seharusnya 3.');
        System.assertEquals(3, result.missingFields.size(), 'Seharusnya ada 3 field yang hilang.');
    }

    @isTest
    static void testMediumHealthScore() {
        // --- GIVEN (Persiapan Data) ---
        Account acc = [SELECT Id FROM Account WHERE Name = 'Base Test Account' LIMIT 1];
        
        // Update Akun dengan beberapa data
        acc.Website = 'www.medium.com';
        update acc;

        // DIUBAH: Buat record Task dengan tanggal menengah
        Task mediumActivity = new Task(
            WhatId = acc.Id,
            Subject = 'Medium Test Task',
            ActivityDate = Date.today().addDays(-60) // Aktivitas menengah (antara 31-90 hari)
        );
        insert mediumActivity;

        // Buat Opportunity dengan nilai menengah
        Opportunity opp = new Opportunity(
            Name = 'Medium Deal',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addMonths(2),
            Amount = 150000000
        );
        insert opp;

        // Buat 2 kasus terbuka
        List<Case> cases = new List<Case>{
            new Case(AccountId = acc.Id, Status = 'New', Subject = 'Issue A'),
            new Case(AccountId = acc.Id, Status = 'Working', Subject = 'Issue B')
        };
        insert cases;

        // --- WHEN (Eksekusi Kode) ---
        Test.startTest();
        AccountHealthController.AccountHealthDetails result = AccountHealthController.getAccountHealthDetails(acc.Id);
        Test.stopTest();

        // --- THEN (Verifikasi Hasil) ---
        // Total = 5 (completeness) + 25 (opps) + 15 (activity) + 5 (cases) = 50
        System.assertEquals(50, result.overallHealthScore, 'Skor kesehatan keseluruhan seharusnya 50.');
        System.assertEquals(5, result.completenessScore, 'Skor kelengkapan seharusnya 5.');
        System.assertEquals(2, result.openCasesCount, 'Jumlah kasus terbuka seharusnya 2.');
        System.assertEquals(2, result.missingFields.size(), 'Seharusnya ada 2 field yang hilang.');
    }
    
    @isTest
    static void testNoRelatedRecords() {
        // --- GIVEN (Persiapan Data) ---
        Account acc = [SELECT Id FROM Account WHERE Name = 'Base Test Account' LIMIT 1];
        // Tidak ada record terkait yang dibuat, termasuk Task. LastActivityDate akan null.

        // --- WHEN (Eksekusi Kode) ---
        Test.startTest();
        AccountHealthController.AccountHealthDetails result = AccountHealthController.getAccountHealthDetails(acc.Id);
        Test.stopTest();

        // --- THEN (Verifikasi Hasil) ---
        // Total = 0 (completeness) + 0 (opps) + 0 (activity) + 10 (cases) = 10
        System.assertEquals(10, result.overallHealthScore, 'Skor kesehatan keseluruhan seharusnya 10.');
        System.assertEquals(0, result.completenessScore, 'Skor kelengkapan seharusnya 0.');
        System.assertEquals(0, result.openOppsCount, 'Jumlah opportunity terbuka seharusnya 0.');
        System.assertEquals(0, result.openOppsValue, 'Nilai opportunity terbuka seharusnya 0.');
        System.assertEquals(0, result.openCasesCount, 'Jumlah kasus terbuka seharusnya 0.');
    }
}