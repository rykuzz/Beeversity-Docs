public with sharing class AccountSummaryController {
    
    // Constants for better maintainability
    private static final Integer QUERY_LIMIT = 2000;
    private static final Integer HEALTHY_SCORE_THRESHOLD = 80;
    private static final Integer CRITICAL_SCORE_THRESHOLD = 40;
    
    // Scoring weights for data completeness (total should be 100)
    private static final Integer BASIC_INFO_SCORE = 20;        // Name, Type, Industry
    private static final Integer CONTACT_INFO_SCORE = 25;     // Phone, Website, BillingAddress
    private static final Integer BUSINESS_INFO_SCORE = 20;    // AnnualRevenue, NumberOfEmployees, Description
    private static final Integer OWNERSHIP_SCORE = 15;        // Owner assigned and active
    private static final Integer RELATIONSHIP_SCORE = 20;     // Has Contacts, Opportunities, or Cases

    public class AccountScorecardResult {
        @AuraEnabled public List<SummaryItem> summaryData { get; set; }
        @AuraEnabled public List<AccountData> criticalAccounts { get; set; }
        @AuraEnabled public List<AccountData> atRiskAccounts { get; set; }
        @AuraEnabled public List<AccountData> healthyAccounts { get; set; }
        @AuraEnabled public Integer totalAccountsProcessed { get; set; }
        @AuraEnabled public DateTime lastUpdated { get; set; }

        public AccountScorecardResult() {
            this.summaryData = new List<SummaryItem>();
            this.criticalAccounts = new List<AccountData>();
            this.atRiskAccounts = new List<AccountData>();
            this.healthyAccounts = new List<AccountData>();
            this.totalAccountsProcessed = 0;
            this.lastUpdated = DateTime.now();
        }
    }

    public class AccountData {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String OwnerName { get; set; }
        @AuraEnabled public String Type { get; set; }
        @AuraEnabled public String Industry { get; set; }
        @AuraEnabled public String Phone { get; set; }
        @AuraEnabled public String Website { get; set; }
        @AuraEnabled public Integer completenessScore { get; set; }
        @AuraEnabled public String missingFields { get; set; }
        @AuraEnabled public String completenessLevel { get; set; }
        @AuraEnabled public Date LastModifiedDate { get; set; }

        public AccountData(Account acc, Integer score, String missing, String level) {
            this.Id = acc.Id;
            this.Name = acc.Name;
            this.OwnerName = acc.Owner?.Name;
            this.Type = acc.Type;
            this.Industry = acc.Industry;
            this.Phone = acc.Phone;
            this.Website = acc.Website;
            this.completenessScore = score;
            this.missingFields = missing;
            this.completenessLevel = level;
            this.LastModifiedDate = acc.LastModifiedDate?.date();
        }
    }

    public class SummaryItem {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer total { get; set; }
        @AuraEnabled public Decimal percentage { get; set; }
        @AuraEnabled public Decimal averageScore { get; set; }
        
        public SummaryItem(String label, Integer total, Decimal percentage, Decimal avgScore) {
            this.label = label;
            this.total = total;
            this.percentage = percentage;
            this.averageScore = avgScore;
        }
    }

    @AuraEnabled(cacheable=true)
    public static AccountScorecardResult getAccountScorecard() {
        try {
            AccountScorecardResult result = new AccountScorecardResult();
            Id currentUserId = UserInfo.getUserId();

            // Enhanced query with more fields for completeness check
            List<Account> myAccounts = [
                SELECT Id, Name, Type, Industry, Phone, Website, BillingStreet, BillingCity, 
                       BillingState, BillingCountry, AnnualRevenue, NumberOfEmployees, 
                       Description, OwnerId, Owner.Name, Owner.IsActive, LastModifiedDate,
                       (SELECT Id FROM Contacts LIMIT 1),
                       (SELECT Id FROM Opportunities LIMIT 1),
                       (SELECT Id FROM Cases LIMIT 1)
                FROM Account
                WHERE OwnerId = :currentUserId
                  AND IsDeleted = false
                ORDER BY LastModifiedDate DESC
                LIMIT :QUERY_LIMIT
            ];

            // Process accounts efficiently
            Map<String, Object> categorizedData = categorizeAccountsByCompleteness(myAccounts);
            
            result.criticalAccounts = (List<AccountData>) categorizedData.get('critical');
            result.atRiskAccounts = (List<AccountData>) categorizedData.get('atRisk');
            result.healthyAccounts = (List<AccountData>) categorizedData.get('healthy');
            result.totalAccountsProcessed = myAccounts.size();
            
            // Calculate summary with averages
            Integer totalAccounts = myAccounts.size();
            result.summaryData = buildSummaryData(
                result.healthyAccounts, 
                result.atRiskAccounts, 
                result.criticalAccounts, 
                totalAccounts
            );

            return result;
            
        } catch (Exception e) {
            // Log error for debugging
            System.debug(LoggingLevel.ERROR, 'Error in getAccountScorecard: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // Return empty result to prevent UI errors
            AccountScorecardResult errorResult = new AccountScorecardResult();
            errorResult.summaryData = new List<SummaryItem>{
                new SummaryItem('Data Lengkap', 0, 0, 0),
                new SummaryItem('Data Kurang', 0, 0, 0),
                new SummaryItem('Data Minim', 0, 0, 0)
            };
            return errorResult;
        }
    }

    private static Map<String, Object> categorizeAccountsByCompleteness(List<Account> accounts) {
        Map<String, List<AccountData>> categorized = new Map<String, List<AccountData>>{
            'critical' => new List<AccountData>(),
            'atRisk' => new List<AccountData>(),
            'healthy' => new List<AccountData>()
        };

        for (Account acc : accounts) {
            Map<String, Object> scoreData = calculateCompletenessScore(acc);
            Integer score = (Integer) scoreData.get('score');
            String missingFields = (String) scoreData.get('missingFields');
            String level = (String) scoreData.get('level');
            
            AccountData accountData = new AccountData(acc, score, missingFields, level);
            
            if (score >= HEALTHY_SCORE_THRESHOLD) {
                categorized.get('healthy').add(accountData);
            } else if (score <= CRITICAL_SCORE_THRESHOLD) {
                categorized.get('critical').add(accountData);
            } else {
                categorized.get('atRisk').add(accountData);
            }
        }

        return new Map<String, Object>{
            'critical' => categorized.get('critical'),
            'atRisk' => categorized.get('atRisk'),
            'healthy' => categorized.get('healthy')
        };
    }

    private static Map<String, Object> calculateCompletenessScore(Account acc) {
        Integer score = 0;
        List<String> missingFieldsList = new List<String>();

        // 1. Basic Information (20 points)
        Integer basicScore = 0;
        if (String.isNotBlank(acc.Name)) basicScore += 7;
        if (String.isNotBlank(acc.Type)) {
            basicScore += 7;
        } else {
            missingFieldsList.add('Type');
        }
        if (String.isNotBlank(acc.Industry)) {
            basicScore += 6;
        } else {
            missingFieldsList.add('Industry');
        }
        score += basicScore;

        // 2. Contact Information (25 points)
        Integer contactScore = 0;
        if (String.isNotBlank(acc.Phone)) {
            contactScore += 8;
        } else {
            missingFieldsList.add('Phone');
        }
        if (String.isNotBlank(acc.Website)) {
            contactScore += 8;
        } else {
            missingFieldsList.add('Website');
        }
        // Billing Address completeness
        if (String.isNotBlank(acc.BillingStreet) && String.isNotBlank(acc.BillingCity)) {
            contactScore += 9;
        } else {
            missingFieldsList.add('Billing Address');
        }
        score += contactScore;

        // 3. Business Information (20 points)
        Integer businessScore = 0;
        if (acc.AnnualRevenue != null && acc.AnnualRevenue > 0) {
            businessScore += 7;
        } else {
            missingFieldsList.add('Annual Revenue');
        }
        if (acc.NumberOfEmployees != null && acc.NumberOfEmployees > 0) {
            businessScore += 6;
        } else {
            missingFieldsList.add('Number of Employees');
        }
        if (String.isNotBlank(acc.Description)) {
            businessScore += 7;
        } else {
            missingFieldsList.add('Description');
        }
        score += businessScore;

        // 4. Ownership (15 points)
        Integer ownershipScore = 0;
        if (acc.OwnerId != null) {
            ownershipScore += 8;
            if (acc.Owner?.IsActive == true) {
                ownershipScore += 7;
            } else {
                missingFieldsList.add('Active Owner');
            }
        } else {
            missingFieldsList.add('Owner');
        }
        score += ownershipScore;

        // 5. Relationships (20 points)
        Integer relationshipScore = 0;
        if (!acc.Contacts.isEmpty()) {
            relationshipScore += 7;
        } else {
            missingFieldsList.add('Contacts');
        }
        if (!acc.Opportunities.isEmpty()) {
            relationshipScore += 7;
        } else {
            missingFieldsList.add('Opportunities');
        }
        if (!acc.Cases.isEmpty()) {
            relationshipScore += 6;
        } else {
            missingFieldsList.add('Cases/Support History');
        }
        score += relationshipScore;

        // Determine completeness level
        String level;
        if (score >= HEALTHY_SCORE_THRESHOLD) {
            level = 'Lengkap';
        } else if (score <= CRITICAL_SCORE_THRESHOLD) {
            level = 'Minim';
        } else {
            level = 'Kurang';
        }

        String missingFields = missingFieldsList.isEmpty() ? 
            'Semua data lengkap' : 
            'Perlu: ' + String.join(missingFieldsList, ', ');

        return new Map<String, Object>{
            'score' => score,
            'missingFields' => missingFields,
            'level' => level
        };
    }

    private static List<SummaryItem> buildSummaryData(
        List<AccountData> healthyAccounts, 
        List<AccountData> atRiskAccounts, 
        List<AccountData> criticalAccounts, 
        Integer totalCount
    ) {
        List<SummaryItem> summaryItems = new List<SummaryItem>();
        
        // Calculate percentages
        Integer healthyCount = healthyAccounts.size();
        Integer atRiskCount = atRiskAccounts.size();
        Integer criticalCount = criticalAccounts.size();
        
        Decimal healthyPercentage = totalCount > 0 ? (healthyCount * 100.0 / totalCount).setScale(1) : 0;
        Decimal atRiskPercentage = totalCount > 0 ? (atRiskCount * 100.0 / totalCount).setScale(1) : 0;
        Decimal criticalPercentage = totalCount > 0 ? (criticalCount * 100.0 / totalCount).setScale(1) : 0;

        // Calculate average scores
        Decimal healthyAvgScore = calculateAverageScore(healthyAccounts);
        Decimal atRiskAvgScore = calculateAverageScore(atRiskAccounts);
        Decimal criticalAvgScore = calculateAverageScore(criticalAccounts);

        summaryItems.add(new SummaryItem('Data Lengkap', healthyCount, healthyPercentage, healthyAvgScore));
        summaryItems.add(new SummaryItem('Data Kurang', atRiskCount, atRiskPercentage, atRiskAvgScore));
        summaryItems.add(new SummaryItem('Data Minim', criticalCount, criticalPercentage, criticalAvgScore));

        return summaryItems;
    }

    private static Decimal calculateAverageScore(List<AccountData> accounts) {
        if (accounts.isEmpty()) return 0;
        
        Integer totalScore = 0;
        for (AccountData acc : accounts) {
            totalScore += acc.completenessScore;
        }
        
        return (totalScore * 1.0 / accounts.size()).setScale(1);
    }

    // Additional method for real-time refresh (non-cacheable)
    @AuraEnabled
    public static AccountScorecardResult refreshAccountScorecard() {
        return getAccountScorecard();
    }

    // Method to get field completion suggestions for a specific account
    @AuraEnabled
    public static Map<String, Object> getAccountCompletionSuggestions(String accountId) {
        try {
            Account acc = [
                SELECT Id, Name, Type, Industry, Phone, Website, BillingStreet, BillingCity, 
                       BillingState, BillingCountry, AnnualRevenue, NumberOfEmployees, 
                       Description, OwnerId, Owner.Name, Owner.IsActive,
                       (SELECT Id FROM Contacts LIMIT 1),
                       (SELECT Id FROM Opportunities LIMIT 1),
                       (SELECT Id FROM Cases LIMIT 1)
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            return calculateCompletenessScore(acc);
        } catch (Exception e) {
            return new Map<String, Object>{
                'score' => 0,
                'missingFields' => 'Error retrieving data',
                'level' => 'Unknown'
            };
        }
    }
}