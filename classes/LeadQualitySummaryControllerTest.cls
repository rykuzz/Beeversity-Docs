@isTest
private class LeadQualitySummaryControllerTest {

    /**
     * @description Metode @TestSetup untuk membuat data uji. Dijalankan sekali untuk semua metode tes.
     * Membuat 4 lead dengan kualitas data yang berbeda-beda.
     */
    @TestSetup
    static void makeData() {
        // Buat beberapa lead dengan tingkat kelengkapan data yang berbeda
        List<Lead> leadsToCreate = new List<Lead>();

        // 1. Lead Hebat (Skor 100) - 5/5 field terisi
        leadsToCreate.add(new Lead(
            LastName = 'Santoso',
            Company = 'Perusahaan Hebat',
            Email = 'hebat@example.com',
            Phone = '111111',
            Industry = 'Technology'
        ));

        // 2. Lead Baik (Skor 80) - 4/5 field terisi
        leadsToCreate.add(new Lead(
            LastName = 'Budi',
            Company = 'Perusahaan Baik',
            Email = 'baik@example.com',
            Phone = '222222'
            // Industry sengaja dikosongkan
        ));

        // 3. Lead Buruk (Skor 60) - 3/5 field terisi
        leadsToCreate.add(new Lead(
            LastName = 'Cahyo',
            Company = 'Perusahaan Buruk',
            Email = 'buruk@example.com'
            // Phone dan Industry sengaja dikosongkan
        ));

        // 4. Lead Sangat Buruk (Skor 40) - 2/5 field terisi
        leadsToCreate.add(new Lead(
            LastName = 'Dewi',
            Company = 'Perusahaan Sangat Buruk'
            // Email, Phone, Industry sengaja dikosongkan
        ));
        
        insert leadsToCreate;
    }

    /**
     * @description Tes utama untuk skenario sukses dengan data yang beragam.
     */
    @isTest
    static void testGetLeadQualitySummary_SuccessScenario() {
        Test.startTest();
        // Act: Panggil metode yang akan diuji
        LeadQualitySummaryController.LeadQualitySummary summary = LeadQualitySummaryController.getLeadQualitySummary();
        Test.stopTest();

        // Assert: Verifikasi semua agregat dan daftar
        System.assertNotEquals(null, summary, 'Hasil ringkasan tidak boleh null.');
        
        // Verifikasi jumlah total
        System.assertEquals(4, summary.totalLeads, 'Total leads seharusnya 4.');

        // Verifikasi jumlah per kategori
        System.assertEquals(1, summary.greatLeadsCount, 'Jumlah lead hebat seharusnya 1.');
        System.assertEquals(1, summary.goodLeadsCount, 'Jumlah lead baik seharusnya 1.');
        System.assertEquals(2, summary.poorLeadsCount, 'Jumlah lead buruk seharusnya 2.');

        // Verifikasi skor rata-rata ( (100 + 80 + 60 + 40) / 4 = 70 )
        System.assertEquals(70, summary.averageScore, 'Skor rata-rata seharusnya 70.');
        
        // Verifikasi daftar lead buruk
        System.assertEquals(2, summary.poorLeads.size(), 'Daftar lead buruk seharusnya berisi 2 record.');
        
        // Verifikasi urutan daftar lead buruk (skor terendah di awal)
        System.assertEquals(40, summary.poorLeads[0].score, 'Lead pertama dalam daftar buruk seharusnya memiliki skor 40.');
        System.assertEquals(60, summary.poorLeads[1].score, 'Lead kedua dalam daftar buruk seharusnya memiliki skor 60.');
    }

    /**
     * @description Tes kasus khusus di mana tidak ada lead di database.
     */
    @isTest
    static void testGetLeadQualitySummary_NoLeads() {
        // Hapus data yang dibuat oleh @TestSetup untuk simulasi database kosong
        delete [SELECT Id FROM Lead];

        Test.startTest();
        // Act: Panggil metode pada database kosong
        LeadQualitySummaryController.LeadQualitySummary summary = LeadQualitySummaryController.getLeadQualitySummary();
        Test.stopTest();

        // Assert: Pastikan semua nilai adalah 0 dan tidak ada error
        System.assertNotEquals(null, summary);
        System.assertEquals(0, summary.totalLeads, 'Total leads seharusnya 0.');
        System.assertEquals(0, summary.averageScore, 'Skor rata-rata seharusnya 0.');
        System.assertEquals(0, summary.greatLeadsCount, 'Jumlah lead hebat seharusnya 0.');
        System.assertEquals(0, summary.goodLeadsCount, 'Jumlah lead baik seharusnya 0.');
        System.assertEquals(0, summary.poorLeadsCount, 'Jumlah lead buruk seharusnya 0.');
        System.assertEquals(0, summary.poorLeads.size(), 'Daftar lead buruk seharusnya kosong.');
    }

    /**
     * @description Tes unit khusus untuk logika perbandingan (sorting) di inner class LeadInfo.
     */
    @isTest
    static void testLeadInfo_ComparableImplementation() {
        // Arrange: Buat beberapa instance LeadInfo
        LeadQualitySummaryController.LeadInfo leadLow = new LeadQualitySummaryController.LeadInfo();
        leadLow.score = 40;
        
        LeadQualitySummaryController.LeadInfo leadHigh = new LeadQualitySummaryController.LeadInfo();
        leadHigh.score = 90;
        
        LeadQualitySummaryController.LeadInfo leadSame = new LeadQualitySummaryController.LeadInfo();
        leadSame.score = 90;
        
        // Act & Assert: Uji langsung metode compareTo
        System.assertEquals(-1, leadLow.compareTo(leadHigh), 'Skor rendah harus mengembalikan -1 saat dibandingkan dengan skor tinggi.');
        System.assertEquals(1, leadHigh.compareTo(leadLow), 'Skor tinggi harus mengembalikan 1 saat dibandingkan dengan skor rendah.');
        System.assertEquals(0, leadHigh.compareTo(leadSame), 'Skor yang sama harus mengembalikan 0.');

        // Uji sorting pada List
        List<LeadQualitySummaryController.LeadInfo> leadList = new List<LeadQualitySummaryController.LeadInfo>{leadHigh, leadLow};
        leadList.sort();
        
        System.assertEquals(40, leadList[0].score, 'Lead dengan skor terendah harus berada di urutan pertama setelah di-sort.');
    }
}
