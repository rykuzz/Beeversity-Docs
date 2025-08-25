public class LeadTriggerHandler {
    
    public static void setInitialStatusAndRating(List<Lead> newLeads) {
        for (Lead l : newLeads) {
            Boolean hasEmail = String.isNotBlank(l.Email);
            Boolean hasPhone = String.isNotBlank(l.Phone);
            
            if (!hasEmail && !hasPhone) {
                l.Status = 'New';
                l.Rating = 'Cold';
            } else if (hasEmail && hasPhone) {
                l.Status = 'Contacted';
                l.Rating = 'Warm';
            } else {
                l.Status = 'New';
                l.Rating = 'Cold';
            }
        }
    }
    
    public static void processLeads(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        List<Lead> leadsToConvert = new List<Lead>();
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();

        for (Lead l : newLeads) {
            Lead oldL = oldLeadMap != null ? oldLeadMap.get(l.Id) : null;
            Boolean needsUpdate = false;
            Lead leadToUpdate = l.clone(true, true, true, true);

            if (oldL != null) {
                Boolean oldHadNoEmailPhone = String.isBlank(oldL.Email) && String.isBlank(oldL.Phone);
                Boolean newHasEmailPhone = String.isNotBlank(l.Email) && String.isNotBlank(l.Phone);
                
                if (oldHadNoEmailPhone && newHasEmailPhone && l.Status != 'Contacted') {
                    leadToUpdate.Status = 'Contacted';
                    leadToUpdate.Rating = 'Warm';
                    needsUpdate = true;
                }
            }

            if (!needsUpdate) {
                Boolean ratingChangedToWarm = oldL != null && oldL.Rating != 'Warm' && l.Rating == 'Warm';
                if (ratingChangedToWarm && l.Status != 'Review') {
                    leadToUpdate.Status = 'Review';
                    needsUpdate = true;
                }
            }

            if (oldL != null) {
                Boolean statusChanged = oldL.Status != l.Status;
                
                if (statusChanged) {

                    if (l.Status == 'Review' && l.Rating != 'Hot') {
                        leadToUpdate.Rating = 'Hot';
                        needsUpdate = true;
                    } else if (l.Status == 'Unqualified' && l.Rating != 'Cold') {
                        leadToUpdate.Rating = 'Cold';
                        needsUpdate = true;
                    } else if (l.Status == 'Closed - Converted' && l.Rating != 'Hot') {
                        leadToUpdate.Rating = 'Hot';
                        needsUpdate = true;
                    }

                    if (l.Status == 'Closed - Converted' && isLeadReadyForConversion(l)) {
                        leadsToConvert.add(l);
                    }
                }
            }
            
            if (!needsUpdate) {
                String newRating = getRatingFromStatus(l.Status);
                if (newRating != null && l.Rating != newRating) {
                    leadToUpdate.Rating = newRating;
                    needsUpdate = true;
                }
            }

            if (needsUpdate) {
                leadsToUpdate.put(l.Id, leadToUpdate);
            }
        }

        if (!leadsToUpdate.isEmpty()) {
            try {
                update leadsToUpdate.values();
            } catch (DmlException e) {
                System.debug('Error updating leads: ' + e.getMessage());
            }
        }
        
        if (!leadsToConvert.isEmpty()) {
            convertLeadsOptimized(leadsToConvert);
        }
    }
    
    private static String getRatingFromStatus(String status) {
        switch on status {
            when 'Closed - Not Converted' {
                return 'Cold';
            }
            when 'Closed - Converted' {
                return 'Hot';
            }
            when 'Review' {
                return 'Hot';  
            }
            when 'Unqualified' {
                return 'Cold';
            }
            when else {
                return null;
            }
        }
    }

    private static Boolean isLeadReadyForConversion(Lead l) {
        return String.isNotBlank(l.Company) && 
               String.isNotBlank(l.Email) && 
               !l.IsConverted;
    }
  
    private static void convertLeadsOptimized(List<Lead> leadsToConvert) {
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();

        for(Lead lead : leadsToConvert) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setDoNotCreateOpportunity(false);
            lc.setConvertedStatus('Closed - Converted');
            lc.setOpportunityName(lead.Company + ' Opportunity');
            lc.setAccountId(null);
            lc.setOwnerId(lead.OwnerId);
            leadConverts.add(lc);
        }

        if (!leadConverts.isEmpty()) {
            List<Database.LeadConvertResult> results = Database.convertLead(leadConverts, false);
            handleConversionResults(results, leadsToConvert);
        }
    }

    private static void handleConversionResults(List<Database.LeadConvertResult> results, List<Lead> originalLeads) {
        for(Integer i = 0; i < results.size(); i++) {
            if(!results[i].isSuccess()) {
                Database.Error error = results[i].getErrors()[0];
                System.debug('Lead convert failed for Lead Id ' + originalLeads[i].Id + 
                           ' Error: ' + error.getMessage() + 
                           ' Status Code: ' + error.getStatusCode());
            } else {
                System.debug('Lead successfully converted: ' + originalLeads[i].Id + 
                           ' Account: ' + results[i].getAccountId() + 
                           ' Contact: ' + results[i].getContactId() + 
                           ' Opportunity: ' + results[i].getOpportunityId());
            }
        }
    }
    
    public static void processLeadsWithSetLogic(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : newLeads) {
            leadIds.add(l.Id);
        }
        processLeads(newLeads, oldLeadMap);
    }
}