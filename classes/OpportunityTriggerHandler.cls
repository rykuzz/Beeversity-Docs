public with sharing class OpportunityTriggerHandler {
/*
    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppIdsToSendInvoice = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.StageName == 'Closed Won' && oldOppMap.get(opp.Id).StageName != 'Closed Won') {
                oppIdsToSendInvoice.add(opp.Id);
            }
        }
        
        System.debug('Jumlah Oppty yang menjadi Closed Won: ' + oppIdsToSendInvoice.size());
        if (oppIdsToSendInvoice.isEmpty()) { return; }

        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'InvoiceEmailTemplate' LIMIT 1];
        
        if (templateList.isEmpty()) {
            System.debug('Error: Email Template "InvoiceEmailTemplate" tidak ditemukan.');
            return;
        }
        EmailTemplate template = templateList[0];

        Map<Id, Id> contactToOppMap = new Map<Id, Id>();
        for (OpportunityContactRole ocr : [SELECT ContactId, OpportunityId 
                                            FROM OpportunityContactRole 
                                            WHERE OpportunityId IN :oppIdsToSendInvoice AND IsPrimary = TRUE]) {
            contactToOppMap.put(ocr.ContactId, ocr.OpportunityId);
        }
        
        System.debug('Jumlah Kontak Utama yang ditemukan: ' + contactToOppMap.size());
        if (contactToOppMap.isEmpty()) { return; }

        Set<Id> contactIds = contactToOppMap.keySet();
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :contactIds]);
        
        List<Map<String, String>> emailsToProcess = new List<Map<String, String>>();
        for (Id contactId : contactToOppMap.keySet()) {
            if (contactsMap.containsKey(contactId) && contactsMap.get(contactId).Email != null) {
                Id opportunityId = contactToOppMap.get(contactId);
                Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(template.Id, contactId, opportunityId);

                Map<String, String> emailData = new Map<String, String>();
                emailData.put('recipientEmail', contactsMap.get(contactId).Email);
                emailData.put('subject', renderedEmail.getSubject());
                emailData.put('htmlBody', renderedEmail.getHtmlBody());
                emailsToProcess.add(emailData);
            }
        }

        System.debug('Jumlah email yang siap diproses untuk @future: ' + emailsToProcess.size());
        if (!emailsToProcess.isEmpty()) {
            sendInvoiceEmails(JSON.serialize(emailsToProcess));
        }
    }

    @future(callout=true)
    private static void sendInvoiceEmails(String serializedEmailData) {

        List<Map<String, String>> emailsToSend = (List<Map<String, String>>) JSON.deserialize(serializedEmailData, List<Map<String, String>>.class);

        String apiKey = 'mlsn.47a6727e2e31c585fa11c9e539f4c4c433a359701e86bf9854b48a572da4ae9e';
        String fromEmail = 'info@test-zkq340ex2dkgd796.mlsender.net';

        Http http = new Http();
        for (Map<String, String> emailData : emailsToSend) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.mailersend.com/v1/email');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('Authorization', 'Bearer ' + apiKey);

            String recipientEmail = emailData.get('recipientEmail');
            String subject = emailData.get('subject');
            String htmlBody = emailData.get('htmlBody');

            String jsonBody = JSON.serialize(new Map<String, Object>{
                'from' => new Map<String, String>{ 'email' => fromEmail },
                'to' => new List<Object>{ new Map<String, String>{ 'email' => recipientEmail } },
                'subject' => subject,
                'html' => htmlBody
            });

            req.setBody(jsonBody);

            try {
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 202) {
                    System.debug('BERHASIL: Email ke ' + recipientEmail + ' berhasil diterima oleh MailerSend.');
                } else {
                    System.debug('GAGAL: Gagal mengirim email ke ' + recipientEmail + '. Status: ' + res.getStatus() + '. Body: ' + res.getBody());
                }
            } catch (Exception e) {
                System.debug('ERROR: Error callout ke MailerSend untuk ' + recipientEmail + ': ' + e.getMessage());
            }
        }
    }
*/

    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppIdsToSendInvoice = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.StageName == 'Closed Won' && oldOppMap.get(opp.Id).StageName != 'Closed Won') {
                oppIdsToSendInvoice.add(opp.Id);
            }
        }
        if (oppIdsToSendInvoice.isEmpty()) { return; }

        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'InvoiceEmailTemplate' LIMIT 1];
        if (templateList.isEmpty()) {
            System.debug('Error: Email Template "InvoiceEmailTemplate" tidak ditemukan.');
            return;
        }
        EmailTemplate template = templateList[0];

        Map<Id, Id> contactToOppMap = new Map<Id, Id>();
        for (OpportunityContactRole ocr : [SELECT ContactId, OpportunityId 
                                            FROM OpportunityContactRole 
                                            WHERE OpportunityId IN :oppIdsToSendInvoice AND IsPrimary = TRUE]) {
            contactToOppMap.put(ocr.ContactId, ocr.OpportunityId);
        }
        if (contactToOppMap.isEmpty()) { return; }

        Set<Id> contactIds = contactToOppMap.keySet();
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :contactIds]);
        
        List<Map<String, String>> emailsToProcess = new List<Map<String, String>>();
        for (Id contactId : contactToOppMap.keySet()) {
            if (contactsMap.containsKey(contactId) && contactsMap.get(contactId).Email != null) {
                Id opportunityId = contactToOppMap.get(contactId);
                Messaging.SingleEmailMessage renderedEmail = Messaging.renderStoredEmailTemplate(template.Id, contactId, opportunityId);

                Map<String, String> emailData = new Map<String, String>();
                emailData.put('recipientEmail', contactsMap.get(contactId).Email);
                emailData.put('subject', renderedEmail.getSubject());
                emailData.put('htmlBody', renderedEmail.getHtmlBody());
                emailsToProcess.add(emailData);
            }
        }

        if (!emailsToProcess.isEmpty()) {
            sendInvoiceEmails(JSON.serialize(emailsToProcess));
        }
    }

    @future(callout=true)
    private static void sendInvoiceEmails(String serializedEmailData) {
        List<Map<String, String>> emailsToSend = (List<Map<String, String>>) JSON.deserialize(serializedEmailData, List<Map<String, String>>.class);

        String apiKey = 'b82fcb6212b4bf2b932b3580aedbe599';
        String apiSecretKey = 'e0b75186fb468876963b113333c380e5';
        String fromEmail = 'beeversity@apple.edu.pl';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.mailjet.com/v3.1/send');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiKey + ':' + apiSecretKey));
        req.setHeader('Authorization', authorizationHeader);

        List<Map<String, Object>> messages = new List<Map<String, Object>>();
        for (Map<String, String> emailData : emailsToSend) {
            String recipientEmail = emailData.get('recipientEmail');
            String subject = emailData.get('subject');
            String htmlBody = emailData.get('htmlBody');

            messages.add(new Map<String, Object>{
                'From' => new Map<String, String>{
                    'Email' => fromEmail,
                    'Name' => 'Beeversity Finance'
                },
                'To' => new List<Object>{
                    new Map<String, String>{ 'Email' => recipientEmail }
                },
                'Subject' => subject,
                'HTMLPart' => htmlBody,
                'Headers' => new Map<String, String>{
                    'X-Priority' => '1 (Highest)',
                    'Importance' => 'high'
                }
            });
        }
        
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'Messages' => messages
        });

        req.setBody(jsonBody);

        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                System.debug('BERHASIL: Email berhasil diterima oleh Mailjet. Response: ' + res.getBody());
            } else {
                System.debug('GAGAL: Gagal mengirim email via Mailjet. Status: ' + res.getStatus() + '. Body: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('ERROR: Error callout ke Mailjet: ' + e.getMessage());
        }
    }
}