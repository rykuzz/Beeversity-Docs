@isTest
public class ProductTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Test setup if needed
        // Standard Pricebook biasanya sudah ada di org, tapi untuk memastikan:
        Test.getStandardPricebookId(); // This ensures standard pricebook exists in test context
    }
    
    @isTest
    static void testProductCodeGeneration() {
        Test.startTest();
        
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Java Bootcamp', Family = 'Bootcamp', IsActive = true),
            new Product2(Name = 'Python Online Course', Family = 'Online Class', IsActive = true),
            new Product2(Name = 'React Workshop', Family = 'Workshop', IsActive = true),
            new Product2(Name = 'Computer Science Degree', Family = 'Degree', IsActive = true),
            new Product2(Name = 'AWS Certification', Family = 'Sertifikasi', IsActive = true)
        };
        
        insert products;
        
        Test.stopTest();
        
        // Verify product codes are generated
        List<Product2> insertedProducts = [SELECT Id, Name, ProductCode, Family, Default_Price__c FROM Product2];
        
        for (Product2 product : insertedProducts) {
            System.assertNotEquals(null, product.ProductCode, 'Product code should be generated');
            System.assertNotEquals(null, product.Default_Price__c, 'Default price should be set');
            
            // Verify prefix based on family
            if (product.Family == 'Bootcamp') {
                System.assert(product.ProductCode.startsWith('BC'), 'Bootcamp should have BC prefix');
                System.assertEquals(15000000, product.Default_Price__c, 'Bootcamp default price should be 15M');
            } else if (product.Family == 'Online Class') {
                System.assert(product.ProductCode.startsWith('OC'), 'Online Class should have OC prefix');
                System.assertEquals(2500000, product.Default_Price__c, 'Online Class default price should be 2.5M');
            }
        }
        
        // Verify PricebookEntry is created
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, Product2Id, UnitPrice, IsActive, Pricebook2Id
            FROM PricebookEntry 
            WHERE Product2Id IN :insertedProducts
        ];
        
        System.assertEquals(insertedProducts.size(), pricebookEntries.size(), 
            'Each product should have a pricebook entry');
        
        for (PricebookEntry pbe : pricebookEntries) {
            System.assertEquals(true, pbe.IsActive, 'Pricebook entry should be active');
            System.assertNotEquals(null, pbe.UnitPrice, 'Pricebook entry should have unit price');
        }
    }
    
    @isTest
    static void testProductWithoutFamily() {
        Test.startTest();
        
        // Test product without Family (should not get default price or pricebook entry)
        Product2 product = new Product2(
            Name = 'Unknown Product',
            IsActive = true
            // No Family set
        );
        insert product;
        
        Test.stopTest();
        
        // Verify product code is still generated but no default price
        Product2 insertedProduct = [SELECT ProductCode, Default_Price__c FROM Product2 WHERE Id = :product.Id];
        System.assertNotEquals(null, insertedProduct.ProductCode, 'Product code should be generated');
        System.assertEquals(null, insertedProduct.Default_Price__c, 'Default price should be null');
        
        // Verify no pricebook entry is created when no default price
        List<PricebookEntry> pricebookEntries = [
            SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id
        ];
        System.assertEquals(0, pricebookEntries.size(), 'No pricebook entry should be created without price');
    }
    
    @isTest
    static void testProductWithExistingPrice() {
        Test.startTest();
        
        // Test product with manually set price
        Product2 product = new Product2(
            Name = 'Custom Price Product',
            Family = 'Bootcamp',
            Default_Price__c = 20000000, // Custom price
            IsActive = true
        );
        insert product;
        
        Test.stopTest();
        
        // Verify custom price is preserved
        Product2 insertedProduct = [SELECT Default_Price__c FROM Product2 WHERE Id = :product.Id];
        System.assertEquals(20000000, insertedProduct.Default_Price__c, 'Custom price should be preserved');
        
        // Verify pricebook entry is created with custom price
        List<PricebookEntry> pricebookEntries = [
            SELECT UnitPrice FROM PricebookEntry WHERE Product2Id = :product.Id
        ];
        System.assertEquals(1, pricebookEntries.size(), 'Pricebook entry should be created');
        System.assertEquals(20000000, pricebookEntries[0].UnitPrice, 'Pricebook entry should use custom price');
    }
    
    @isTest
    static void testBulkInsert() {
        Test.startTest();
        
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 100; i++) {
            products.add(new Product2(
                Name = 'Bulk Product ' + i,
                Family = 'Bootcamp',
                IsActive = true
            ));
        }
        
        insert products;
        
        Test.stopTest();
        
        // Verify all products have codes and prices
        List<Product2> insertedProducts = [SELECT ProductCode, Default_Price__c FROM Product2];
        System.assertEquals(100, insertedProducts.size(), 'All products should be inserted');
        
        for (Product2 product : insertedProducts) {
            System.assertNotEquals(null, product.ProductCode, 'All products should have codes');
            System.assertNotEquals(null, product.Default_Price__c, 'All products should have prices');
        }
        
        // Verify all pricebook entries are created
        List<PricebookEntry> pricebookEntries = [
            SELECT Id FROM PricebookEntry WHERE Product2Id IN :insertedProducts
        ];
        System.assertEquals(100, pricebookEntries.size(), 'All products should have pricebook entries');
    }
    
    @isTest
    static void testProductCodeUniqueness() {
        Test.startTest();
        
        // Insert products with same family to test uniqueness
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 10; i++) {
            products.add(new Product2(
                Name = 'Bootcamp ' + i,
                Family = 'Bootcamp',
                IsActive = true
            ));
        }
        insert products;
        
        Test.stopTest();
        
        // Verify all product codes are unique
        List<Product2> allProducts = [SELECT ProductCode FROM Product2];
        Set<String> productCodes = new Set<String>();
        
        for (Product2 product : allProducts) {
            System.assert(!productCodes.contains(product.ProductCode), 
                'Product codes must be unique: ' + product.ProductCode);
            productCodes.add(product.ProductCode);
        }
    }
    
    @isTest
    static void testProductUpdate() {
        Test.startTest();
        
        // Insert product
        Product2 product = new Product2(
            Name = 'Test Product',
            Family = 'Workshop',
            IsActive = true
        );
        insert product;
        
        // Update family (should regenerate product code)
        product.Family = 'Bootcamp';
        update product;
        
        Test.stopTest();
        
        // Verify product code was regenerated
        Product2 updatedProduct = [SELECT ProductCode, Family FROM Product2 WHERE Id = :product.Id];
        System.assertEquals('Bootcamp', updatedProduct.Family, 'Family should be updated');
        System.assert(updatedProduct.ProductCode.startsWith('BC'), 
            'Product code should be regenerated with BC prefix');
    }
    
    @isTest
    static void testExistingProductCode() {
        Test.startTest();
        
        // Create product with existing product code
        Product2 product = new Product2(
            Name = 'Test Product',
            Family = 'Bootcamp',
            ProductCode = 'EXISTING001',
            IsActive = true
        );
        insert product;
        
        Test.stopTest();
        
        // Verify existing product code is preserved
        Product2 insertedProduct = [SELECT ProductCode FROM Product2 WHERE Id = :product.Id];
        System.assertEquals('EXISTING001', insertedProduct.ProductCode, 
            'Existing product code should be preserved');
    }
}