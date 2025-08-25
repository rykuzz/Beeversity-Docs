public with sharing class LeadQualitySummaryController {


    public class LeadQualitySummary {
        @AuraEnabled public Decimal averageScore;
        @AuraEnabled public Integer totalLeads;
        @AuraEnabled public Integer greatLeadsCount;
        @AuraEnabled public Integer goodLeadsCount;
        @AuraEnabled public Integer poorLeadsCount;
        @AuraEnabled public List<LeadInfo> poorLeads;
    }


    public class LeadInfo implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Integer score;
        @AuraEnabled public String ownerName;


        public Integer compareTo(Object compareTo) {
            LeadInfo compareToInfo = (LeadInfo)compareTo;
            if (this.score == compareToInfo.score) return 0;
            if (this.score > compareToInfo.score) return 1;
            return -1;
        }
    }

    @AuraEnabled(cacheable=true)
    public static LeadQualitySummary getLeadQualitySummary() {
        List<String> fieldsToCheck = new List<String>{'Name', 'Company', 'Email', 'Phone', 'Industry'};
        

        List<Lead> activeLeads = [
            SELECT Id, Name, Company, Email, Phone, Industry, Owner.Name
            FROM Lead
            WHERE IsConverted = false 
            LIMIT 500
        ];

        Decimal totalScore = 0;
        List<LeadInfo> allLeadInfos = new List<LeadInfo>();

        for(Lead l : activeLeads) {
            Integer filledFields = 0;
            if(String.isNotBlank(l.Name)) filledFields++;
            if(String.isNotBlank(l.Company)) filledFields++;
            if(String.isNotBlank(l.Email)) filledFields++;
            if(String.isNotBlank(l.Phone)) filledFields++;
            if(String.isNotBlank(l.Industry)) filledFields++;

            Integer currentScore = (Integer)((Decimal)filledFields / fieldsToCheck.size() * 100);
            totalScore += currentScore;
            
            LeadInfo info = new LeadInfo();
            info.id = l.Id;
            info.name = l.Name;
            info.score = currentScore;
            info.ownerName = l.Owner.Name;
            allLeadInfos.add(info);
        }


        allLeadInfos.sort();

        LeadQualitySummary summary = new LeadQualitySummary();
        summary.totalLeads = activeLeads.size();
        summary.averageScore = summary.totalLeads > 0 ? totalScore.divide(summary.totalLeads, 0) : 0;
        summary.greatLeadsCount = 0;
        summary.goodLeadsCount = 0;
        summary.poorLeadsCount = 0;

        for(LeadInfo info : allLeadInfos) {
            if(info.score >= 90) summary.greatLeadsCount++;
            else if(info.score >= 70) summary.goodLeadsCount++;
            else summary.poorLeadsCount++;
        }
        
        summary.poorLeads = new List<LeadInfo>();
        for(Integer i = 0; i < Math.min(5, allLeadInfos.size()); i++) {
            if (allLeadInfos[i].score < 70) { 
               summary.poorLeads.add(allLeadInfos[i]);
            }
        }

        return summary;
    }
}