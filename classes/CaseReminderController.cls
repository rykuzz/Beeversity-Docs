public with sharing class CaseReminderController {

    public Id caseRecordId { get; set; }

    public Case caseForEmail { get; private set; }


    public CaseReminderController() {

    }
    

    public Case getCaseForEmail() {
        if (caseForEmail == null && caseRecordId != null) {
            caseForEmail = [
                SELECT
                    Id, CaseNumber, Subject, Account.Name, Owner.FirstName,
                    LastModifiedDate, CreatedDate
                FROM Case
                WHERE Id = :caseRecordId
                LIMIT 1
            ];
        }
        return caseForEmail;
    }
}