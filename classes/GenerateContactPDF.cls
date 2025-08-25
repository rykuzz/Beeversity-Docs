public with sharing class GenerateContactPDF {

    @InvocableMethod(label='Generate and Attach Contact PDF' description='Renders a VF page as a PDF and attaches it to the Contact record.')
    public static void generateAndAttachPDF(List<Id> contactIds) {

        if (contactIds == null || contactIds.isEmpty()) {
            return;
        }

        Id contactId = contactIds[0];

 
        PageReference pdfPage = Page.ContactSummaryPDF;
        pdfPage.getParameters().put('id', contactId);

        Blob pdfBlob;
        try {

            pdfBlob = pdfPage.getContentAsPDF();
        } catch (Exception e) {

            throw new AuraHandledException('Gagal membuat PDF: ' + e.getMessage());
        }


        ContentVersion cv = new ContentVersion();
        cv.Title = 'Ringkasan Kontak - ' + Date.today().format();
        cv.PathOnClient = 'ContactSummary.pdf';
        cv.VersionData = pdfBlob;
        cv.FirstPublishLocationId = contactId; 
        insert cv;
    }
}