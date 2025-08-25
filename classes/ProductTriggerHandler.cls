public class ProductTriggerHandler {
    
    private static Boolean isExecuting = false;
    
    public static void handleTrigger() {
        if (isExecuting) return; // Prevent recursion
        
        isExecuting = true;
        
        try {
            if (Trigger.isBefore) {
                if (Trigger.isInsert) {
                    handleBeforeInsert((List<Product2>)Trigger.new);
                }
                if (Trigger.isUpdate) {
                    handleBeforeUpdate((List<Product2>)Trigger.new, (Map<Id, Product2>)Trigger.oldMap);
                }
            }
            
            if (Trigger.isAfter) {
                if (Trigger.isInsert) {
                    handleAfterInsert((List<Product2>)Trigger.new);
                }
            }
        } finally {
            isExecuting = false;
        }
    }
    
    private static void handleBeforeInsert(List<Product2> newProducts) {
        generateProductCodes(newProducts);
        setDefaultPrices(newProducts);
    }
    
    private static void handleBeforeUpdate(List<Product2> newProducts, Map<Id, Product2> oldMap) {
        List<Product2> productsNeedingNewCodes = new List<Product2>();
        
        for (Product2 product : newProducts) {
            Product2 oldProduct = oldMap.get(product.Id);
            // Regenerate code if Family changed
            if (product.Family != oldProduct.Family || String.isBlank(product.ProductCode)) {
                productsNeedingNewCodes.add(product);
            }
        }
        
        if (!productsNeedingNewCodes.isEmpty()) {
            generateProductCodes(productsNeedingNewCodes);
        }
    }
    
    private static void handleAfterInsert(List<Product2> newProducts) {
        // Query the products again to get the updated Default_Price__c values
        List<Product2> productsWithPrices = [
            SELECT Id, Default_Price__c 
            FROM Product2 
            WHERE Id IN :newProducts AND Default_Price__c != null
        ];
        
        if (!productsWithPrices.isEmpty()) {
            createPricebookEntries(productsWithPrices);
        }
    }
    
    private static void generateProductCodes(List<Product2> products) {
        // Get existing product codes to avoid duplicates
        Set<String> existingCodes = new Set<String>();
        for (Product2 existingProduct : [SELECT ProductCode FROM Product2 WHERE ProductCode != null]) {
            existingCodes.add(existingProduct.ProductCode);
        }
        
        Map<String, String> familyPrefixes = new Map<String, String>{
            'Bootcamp' => 'BC',
            'Online Class' => 'OC',
            'Workshop' => 'WS',
            'Degree' => 'DG',
            'Sertifikasi' => 'ST'
        };
        
        for (Product2 product : products) {
            if (String.isBlank(product.ProductCode)) {
                String prefix = familyPrefixes.get(product.Family);
                if (prefix == null) {
                    prefix = 'GN'; // General prefix for unknown family
                }
                
                String baseCode = prefix + DateTime.now().format('yyyyMM');
                String productCode = baseCode;
                Integer counter = 1;
                
                // Ensure uniqueness
                while (existingCodes.contains(productCode)) {
                    productCode = baseCode + String.valueOf(counter).leftPad(3, '0');
                    counter++;
                }
                
                product.ProductCode = productCode;
                existingCodes.add(productCode);
            }
        }
    }
    
    private static void setDefaultPrices(List<Product2> products) {
        Map<String, Decimal> familyDefaultPrices = new Map<String, Decimal>{
            'Bootcamp' => 15000000,      // 15 juta
            'Online Class' => 2500000,   // 2.5 juta
            'Workshop' => 1500000,       // 1.5 juta
            'Degree' => 50000000,        // 50 juta
            'Sertifikasi' => 3000000     // 3 juta
        };
        
        for (Product2 product : products) {
            if (product.Default_Price__c == null && product.Family != null) {
                Decimal defaultPrice = familyDefaultPrices.get(product.Family);
                if (defaultPrice != null) {
                    product.Default_Price__c = defaultPrice;
                }
            }
        }
    }
    
    private static void createPricebookEntries(List<Product2> products) {
        // Get Standard Pricebook
        List<Pricebook2> standardPricebooks = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if (standardPricebooks.isEmpty()) {
            return; // No standard pricebook found
        }
        
        Pricebook2 standardPricebook = standardPricebooks[0];
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        for (Product2 product : products) {
            if (product.Default_Price__c != null) {
                PricebookEntry pbe = new PricebookEntry(
                    Pricebook2Id = standardPricebook.Id,
                    Product2Id = product.Id,
                    UnitPrice = product.Default_Price__c,
                    IsActive = true
                );
                pricebookEntries.add(pbe);
            }
        }
        
        if (!pricebookEntries.isEmpty()) {
            insert pricebookEntries;
        }
    }
}