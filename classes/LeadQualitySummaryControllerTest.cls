@isTest
private class LeadQualitySummaryControllerTest {

    // Tes skenario utama dengan berbagai kualitas Lead
    @isTest
    static void testSummary_WithMixedLeads() {
        // 1. PERSIAPAN DATA (DISEMPURNAKAN)
        // Buat lebih dari 5 lead untuk menguji logika Math.min(5, size)
        List<Lead> leadsToInsert = new List<Lead>();

        // Lead Hebat (Skor 100): 5 dari 5 field terisi
        leadsToInsert.add(new Lead(
            LastName = 'Musk', Company = 'Tesla', Email = 'elon@tesla.com',
            Phone = '555-1111', Industry = 'Automotive'
        ));
        // Lead Baik 1 (Skor 80): 4 dari 5 field terisi
        leadsToInsert.add(new Lead(
            LastName = 'Bezos', Company = 'Amazon', Email = 'jeff@amazon.com',
            Phone = '555-2222' // Industry kosong
        ));
        // Lead Baik 2 (Skor 80): 4 dari 5 field terisi
        leadsToInsert.add(new Lead(
            LastName = 'Gates', Company = 'Microsoft', Email = 'bill@ms.com',
            Phone = '555-3333' // Industry kosong
        ));
        // Lead Buruk 1 (Skor 40): 2 dari 5 field terisi
        leadsToInsert.add(new Lead(
            LastName = 'Parker', Company = 'Daily Bugle' // Email, Phone, Industry kosong
        ));
        // Lead Buruk 2 (Skor 60): 3 dari 5 field terisi
         leadsToInsert.add(new Lead(
            LastName = 'Stark', Company = 'Stark Industries', Email = 'tony@stark.com'
        ));
        // Lead Buruk 3 (Skor 20): 1 dari 5 field terisi
        leadsToInsert.add(new Lead(
            LastName = 'Banner' // Hanya nama
        ));
        // Lead yang sudah dikonversi (HARUS DIABAIKAN)
        Lead convertedLead = new Lead(LastName='Kent', Company='Daily Planet', IsConverted=true);
        
        insert leadsToInsert;
        insert convertedLead;

        // 2. EKSEKUSI
        Test.startTest();
        LeadQualitySummaryController.LeadQualitySummary result = LeadQualitySummaryController.getLeadQualitySummary();
        Test.stopTest();

        // 3. VERIFIKASI HASIL (DISESUAIKAN)
        System.assertNotEquals(null, result, 'Hasil ringkasan tidak boleh null.');
        // Verifikasi jumlah (hanya 6 lead aktif yang dihitung)
        System.assertEquals(6, result.totalLeads, 'Total Leads yang dihitung harusnya 6.');

        // Verifikasi jumlah per kategori
        System.assertEquals(1, result.greatLeadsCount, 'Jumlah Great Leads harus 1.'); // Skor 100
        System.assertEquals(2, result.goodLeadsCount, 'Jumlah Good Leads harus 2.');   // Skor 80, 80
        System.assertEquals(3, result.poorLeadsCount, 'Jumlah Poor Leads harus 3.');   // Skor 20, 40, 60

        // Verifikasi skor rata-rata: (100 + 80 + 80 + 40 + 60 + 20) / 6 = 380 / 6 = 63.33 -> 63
        System.assertEquals(63, result.averageScore, 'Skor rata-rata tidak sesuai.');

        // Verifikasi daftar Poor Leads (diurutkan dari skor terendah)
        // Urutan skor: 20, 40, 60, 80, 80, 100
        System.assertEquals(3, result.poorLeads.size(), 'Daftar Poor Leads harus berisi 3 record (semua yang skornya < 70 dari 5 terendah).');
        // Verifikasi urutan (skor terendah harus di urutan pertama)
        System.assertEquals('Banner', result.poorLeads[0].name, 'Lead dengan skor terendah harus pertama.');
        System.assertEquals(20, result.poorLeads[0].score, 'Skor Lead pertama di daftar Poor Leads tidak sesuai.');
    }

    // Tes skenario di mana tidak ada Lead aktif
    @isTest
    static void testSummary_NoLeads() {
        // Buat lead yang sudah dikonversi untuk memastikan query tidak salah mengambilnya
        insert new Lead(LastName='Wayne', Company='Wayne Enterprises', IsConverted=true);

        Test.startTest();
        LeadQualitySummaryController.LeadQualitySummary result = LeadQualitySummaryController.getLeadQualitySummary();
        Test.stopTest();

        // Verifikasi bahwa semua nilai adalah 0 atau kosong
        System.assertEquals(0, result.totalLeads, 'Total Leads harus 0.');
        System.assertEquals(0, result.averageScore, 'Skor rata-rata harus 0.');
        System.assertEquals(0, result.greatLeadsCount, 'Jumlah Great Leads harus 0.');
        System.assertEquals(0, result.goodLeadsCount, 'Jumlah Good Leads harus 0.');
        System.assertEquals(0, result.poorLeadsCount, 'Jumlah Poor Leads harus 0.');
        System.assertEquals(true, result.poorLeads.isEmpty(), 'Daftar Poor Leads harus kosong.');
    }

    // Tes unit untuk metode compareTo pada kelas inner LeadInfo
    @isTest
    static void testLeadInfo_Comparable() {
        // Buat instance LeadInfo secara manual untuk menguji logika perbandingan
        LeadQualitySummaryController.LeadInfo leadLowScore = new LeadQualitySummaryController.LeadInfo();
        leadLowScore.score = 40;

        LeadQualitySummaryController.LeadInfo leadHighScore = new LeadQualitySummaryController.LeadInfo();
        leadHighScore.score = 90;
        
        LeadQualitySummaryController.LeadInfo leadLowScoreClone = new LeadQualitySummaryController.LeadInfo();
        leadLowScoreClone.score = 40;

        // Verifikasi logika perbandingan
        System.assertEquals(-1, leadLowScore.compareTo(leadHighScore), 'Skor rendah dibanding skor tinggi seharusnya mengembalikan -1.');
        System.assertEquals(1, leadHighScore.compareTo(leadLowScore), 'Skor tinggi dibanding skor rendah seharusnya mengembalikan 1.');
        System.assertEquals(0, leadLowScore.compareTo(leadLowScoreClone), 'Skor yang sama seharusnya mengembalikan 0.');
    }
}