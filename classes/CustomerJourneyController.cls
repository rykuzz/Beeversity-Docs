public with sharing class CustomerJourneyController {

    // Wrapper class untuk mengirim data terstruktur ke komponen Aura
    public class JourneyWrapper {
        @AuraEnabled public Account acc;
        @AuraEnabled public Lead originLead;
        @AuraEnabled public List<Opportunity> opps;
        @AuraEnabled public Boolean wasConvertedFromLead;
    }

    /**
     * @description Mencari record Account berdasarkan keyword.
     * @param keyword String untuk pencarian nama Akun.
     * @return List<Account>
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String keyword) {
        // Hindari query kosong dan tambahkan wildcard
        String searchKey = '%' + String.escapeSingleQuotes(keyword) + '%';
        
        try {
            // Batasi hasil untuk menghindari governor limit dan performa lambat
            return [
                SELECT Id, Name, Industry
                FROM Account
                WHERE Name LIKE :searchKey
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Mengambil data 360 derajat dari satu Akun.
     * @param accountId ID dari Akun yang dipilih.
     * @return JourneyWrapper
     */
    @AuraEnabled
    public static JourneyWrapper getJourneyData(Id accountId) {
        JourneyWrapper result = new JourneyWrapper();
        result.wasConvertedFromLead = false;

        try {
            // 1. Ambil data Akun
            result.acc = [
                SELECT Id, Name, Industry, Type, Owner.Name
                FROM Account
                WHERE Id = :accountId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // 2. Ambil data Opportunity terkait
            result.opps = [
                SELECT Id, Name, StageName, Amount, CloseDate, Type
                FROM Opportunity
                WHERE AccountId = :accountId
                WITH SECURITY_ENFORCED
                ORDER BY CloseDate DESC
            ];

            // 3. Ambil semua ID Kontak dari Akun ini
            List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE AccountId = :accountId WITH SECURITY_ENFORCED];

            if (!relatedContacts.isEmpty()) {
                // Buat Set dari ID Kontak untuk digunakan dalam query berikutnya
                Set<Id> contactIds = (new Map<Id, SObject>(relatedContacts)).keySet();

                // 4. Cari Lead yang telah dikonversi menjadi salah satu dari Kontak di atas
                List<Lead> convertedLeads = [
                    SELECT Id, Name, LeadSource, CreatedDate
                    FROM Lead
                    WHERE ConvertedContactId IN :contactIds
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];

                if (!convertedLeads.isEmpty()) {
                    result.originLead = convertedLeads[0];
                    result.wasConvertedFromLead = true;
                }
            }

            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}