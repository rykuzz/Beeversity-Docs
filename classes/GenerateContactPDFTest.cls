@isTest
private class GenerateContactPDFTest {

    // Tes skenario sukses di mana PDF berhasil dibuat dan dilampirkan
    @isTest
    static void testGenerateAndAttachPDF_Success() {
        // 1. PERSIAPAN DATA
        Contact con = new Contact(LastName = 'Stark');
        insert con;

        // Siapkan ID dalam format List seperti yang diharapkan oleh metode
        List<Id> contactIds = new List<Id>{ con.Id };

        // 2. EKSEKUSI
        // Karena metode ini memanggil getContentAsPDF(), kita perlu mengatur konteks halaman
        // Pastikan halaman 'ContactSummaryPDF' ada di organisasi Anda
        Test.setCurrentPage(Page.ContactSummaryPDF);

        Test.startTest();
        GenerateContactPDF.generateAndAttachPDF(contactIds);
        Test.stopTest();

        // 3. VERIFIKASI HASIL
        // Metode ini tidak mengembalikan apa pun (void), jadi kita harus
        // memverifikasi hasilnya dengan query ke database.
        List<ContentVersion> attachedFiles = [
            SELECT Id, Title, PathOnClient, FirstPublishLocationId
            FROM ContentVersion
            WHERE FirstPublishLocationId = :con.Id
        ];

        // Pastikan satu file berhasil dibuat dan dilampirkan
        System.assertEquals(1, attachedFiles.size(), 'Seharusnya ada 1 file yang dilampirkan ke Kontak.');
        
        // Verifikasi detail file yang dibuat
        ContentVersion resultFile = attachedFiles[0];
        System.assertEquals('Ringkasan Kontak - ' + Date.today().format(), resultFile.Title, 'Judul file tidak sesuai.');
        System.assertEquals('ContactSummary.pdf', resultFile.PathOnClient, 'Nama file tidak sesuai.');
    }

    // Tes skenario di mana daftar ID yang diberikan kosong
    @isTest
    static void testGenerateAndAttachPDF_EmptyList() {
        // 1. PERSIAPAN DATA (tidak ada data yang dibutuhkan)
        List<Id> emptyContactIds = new List<Id>();

        // 2. EKSEKUSI
        Test.startTest();
        // Panggil metode dengan daftar kosong
        GenerateContactPDF.generateAndAttachPDF(emptyContactIds);
        Test.stopTest();

        // 3. VERIFIKASI HASIL
        // Pastikan tidak ada file yang dibuat
        List<ContentVersion> files = [SELECT Id FROM ContentVersion];
        System.assertEquals(0, files.size(), 'Seharusnya tidak ada file yang dibuat jika daftar ID kosong.');
    }
    
    // Tes skenario di mana daftar ID yang diberikan null
    @isTest
    static void testGenerateAndAttachPDF_NullList() {
        // 1. PERSIAPAN DATA (tidak ada data yang dibutuhkan)

        // 2. EKSEKUSI
        Test.startTest();
        // Panggil metode dengan null
        GenerateContactPDF.generateAndAttachPDF(null);
        Test.stopTest();

        // 3. VERIFIKASI HASIL
        // Pastikan tidak ada file yang dibuat
        List<ContentVersion> files = [SELECT Id FROM ContentVersion];
        System.assertEquals(0, files.size(), 'Seharusnya tidak ada file yang dibuat jika daftar ID null.');
    }
}