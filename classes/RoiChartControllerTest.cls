@isTest
private class RoiChartControllerTest {

    // Tes skenario di mana semua field pada Campaign terisi.
    @isTest
    static void testController_WithData() {
        // 1. PERSIAPAN DATA
        Campaign testCampaign = new Campaign(
            Name = 'Summer Sale Campaign',
            IsActive = true,
            ROI__c = 150.758, // Nilai dengan lebih dari 2 desimal untuk menguji setScale
            ActualCost = 5000,
            BudgetedCost = 7500,
            ExpectedRevenue = 20000
        );
        insert testCampaign;

        // 2. EKSEKUSI
        Test.startTest();

        // Buat StandardController dan berikan record Campaign kita
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCampaign);
        
        // Buat instance dari controller Anda
        RoiChartController controller = new RoiChartController(stdController);

        Test.stopTest();

        // 3. VERIFIKASI HASIL
        System.assertEquals(150.76, controller.roiValue, 'Nilai ROI harus dibulatkan menjadi 2 desimal.');
        System.assertEquals(5000, controller.campaignCost, 'ActualCost tidak cocok.');
        System.assertEquals(7500, controller.budgetedCost, 'BudgetedCost tidak cocok.');
        System.assertEquals(20000, controller.expectedRevenue, 'ExpectedRevenue tidak cocok.');
    }

    // Tes skenario di mana field angka pada Campaign bernilai null.
    @isTest
    static void testController_WithNullData() {
        // 1. PERSIAPAN DATA
        // Buat Campaign hanya dengan field yang wajib diisi
        Campaign testCampaignWithNulls = new Campaign(
            Name = 'Winter Promo',
            IsActive = true
            // Biarkan ROI__c, ActualCost, BudgetedCost, ExpectedRevenue kosong (null)
        );
        insert testCampaignWithNulls;

        // 2. EKSEKUSI
        Test.startTest();

        // Buat StandardController
        ApexPages.StandardController stdController = new ApexPages.StandardController(testCampaignWithNulls);
        
        // Buat instance dari controller Anda
        RoiChartController controller = new RoiChartController(stdController);

        Test.stopTest();

        // 3. VERIFIKASI HASIL
        // Pastikan semua properti diatur ke 0 sesuai logika di controller
        System.assertEquals(0, controller.roiValue, 'roiValue seharusnya 0 jika null.');
        System.assertEquals(0, controller.campaignCost, 'campaignCost seharusnya 0 jika null.');
        System.assertEquals(0, controller.budgetedCost, 'budgetedCost seharusnya 0 jika null.');
        System.assertEquals(0, controller.expectedRevenue, 'expectedRevenue seharusnya 0 jika null.');
    }
}