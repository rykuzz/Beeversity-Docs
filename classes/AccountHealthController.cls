public with sharing class AccountHealthController {

    // Wrapper class untuk mengirim semua data ke LWC dalam satu paket
    public class AccountHealthDetails {
        @AuraEnabled public Integer overallHealthScore;
        @AuraEnabled public Integer completenessScore;
        @AuraEnabled public Integer openOppsCount;
        @AuraEnabled public Decimal openOppsValue;
        @AuraEnabled public Integer openCasesCount;
        @AuraEnabled public Integer contactCount;
        @AuraEnabled public Date lastActivityDate;
        // BARU: Properti untuk menyimpan daftar field yang kosong
        @AuraEnabled public List<String> missingFields; 
    }

    @AuraEnabled(cacheable=true)
    public static AccountHealthDetails getAccountHealthDetails(Id recordId) {
        AccountHealthDetails details = new AccountHealthDetails();
        // BARU: Inisialisasi list
        details.missingFields = new List<String>(); 

        // 1. Ambil data dari Account itu sendiri
        Account acc = [
            SELECT Name, Website, Industry, NumberOfEmployees, LastActivityDate
            FROM Account WHERE Id = :recordId
        ];
        details.lastActivityDate = acc.LastActivityDate;

        // 2. MODIFIKASI: Hitung Kelengkapan Data sambil mencatat field yang kosong
        Integer completenessPoints = 0;
        
        if (String.isNotBlank(acc.Website)) {
            completenessPoints += 5;
        } else {
            details.missingFields.add('Website'); // Tambahkan ke daftar jika kosong
        }
        
        if (String.isNotBlank(acc.Industry)) {
            completenessPoints += 5;
        } else {
            details.missingFields.add('Industri'); // Tambahkan ke daftar jika kosong
        }

        if (acc.NumberOfEmployees != null) {
            completenessPoints += 10;
        } else {
            details.missingFields.add('Jumlah Karyawan'); // Tambahkan ke daftar jika kosong
        }
        
        details.completenessScore = completenessPoints;

        // 3. Agregasi data dari Opportunity (Tidak ada perubahan di sini)
        AggregateResult[] oppResults = [
            SELECT COUNT(Id) oppCount, SUM(Amount) totalValue
            FROM Opportunity
            WHERE AccountId = :recordId AND IsClosed = false
        ];
        details.openOppsCount = (Integer)oppResults[0].get('oppCount');
        details.openOppsValue = (Decimal)oppResults[0].get('totalValue') == null ? 0 : (Decimal)oppResults[0].get('totalValue');

        // 4. Agregasi data dari Case (Tidak ada perubahan di sini)
        AggregateResult[] caseResults = [
            SELECT COUNT(Id) caseCount
            FROM Case
            WHERE AccountId = :recordId AND IsClosed = false
        ];
        details.openCasesCount = (Integer)caseResults[0].get('caseCount');

        // 5. Agregasi data dari Contact (Tidak ada perubahan di sini)
        AggregateResult[] contactResults = [
            SELECT COUNT(Id) contactCount FROM Contact WHERE AccountId = :recordId
        ];
        details.contactCount = (Integer)contactResults[0].get('contactCount');

        // 6. Hitung Skor Kesehatan Keseluruhan (Tidak ada perubahan di sini)
        Integer healthScore = 0;
        healthScore += details.completenessScore; // max 20
        if (details.openOppsValue > 500000000) healthScore += 40;
        else if (details.openOppsValue > 100000000) healthScore += 25;
        else if (details.openOppsValue > 0) healthScore += 10;
        if (acc.LastActivityDate != null) {
            Integer daysSinceActivity = Date.today().daysBetween(acc.LastActivityDate);
            if (daysSinceActivity <= 30) healthScore += 30;
            else if (daysSinceActivity <= 90) healthScore += 15;
        }
        if (details.openCasesCount == 0) healthScore += 10;
        else if (details.openCasesCount <= 2) healthScore += 5;
        details.overallHealthScore = healthScore > 100 ? 100 : healthScore;

        return details;
    }
}