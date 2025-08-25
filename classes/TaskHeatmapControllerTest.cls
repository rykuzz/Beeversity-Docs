@isTest
private class TaskHeatmapControllerTest {

    private static User testUser;

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        testUser = new User(
            Alias = 'testu', Email = 'testuser@heatmap.com', EmailEncodingKey = 'UTF-8',
            LastName = 'Testington', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser.heatmap' + System.currentTimeMillis() + '@testorg.com'
        );
        insert testUser;
    }

    @isTest
    static void testDayWrapperConstructor() {
        Date today = Date.today();
        TaskHeatmapController.DayWrapper low = new TaskHeatmapController.DayWrapper('Monday', 0, today);
        System.assertEquals('heatmap-low', low.heatmapClass, 'Kelas heatmap harus low untuk 0 tugas.');

        TaskHeatmapController.DayWrapper medium = new TaskHeatmapController.DayWrapper('Tuesday', 2, today);
        System.assertEquals('heatmap-medium', medium.heatmapClass, 'Kelas heatmap harus medium untuk 2 tugas.');
        
        TaskHeatmapController.DayWrapper high = new TaskHeatmapController.DayWrapper('Wednesday', 5, today);
        System.assertEquals('heatmap-high', high.heatmapClass, 'Kelas heatmap harus high untuk 5 tugas.');
    }
    
    @isTest
    static void testGetWeeklyTaskData_WithTasks() {
        System.runAs(testUser) {
            Date today = Date.today();
            List<Task> tasks = new List<Task>{
                new Task(Subject = 'Task Hari Ini', ActivityDate = today, OwnerId = UserInfo.getUserId(), Status = 'Not Started', Priority = 'Normal'),
                new Task(Subject = 'Task 2 Hari Lagi', ActivityDate = today.addDays(2), OwnerId = UserInfo.getUserId(), Status = 'In Progress', Priority = 'Normal'),
                new Task(Subject = 'Task Selesai', ActivityDate = today.addDays(4), Status = 'Completed', OwnerId = UserInfo.getUserId(), Priority = 'Normal')
            };
            
            // DITAMBAHKAN: Blok try-catch untuk debugging
            try {
                insert tasks;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '!!! ERROR SAAT MEMBUAT TASK (WeeklyData): ' + e.getMessage());
            }

            Long startMillis = Datetime.newInstance(today, Time.newInstance(0,0,0,0)).getTime();
            
            Test.startTest();
            List<TaskHeatmapController.DayWrapper> result = TaskHeatmapController.getWeeklyTaskData(startMillis);
            Test.stopTest();

            System.assertEquals(7, result.size(), 'Harus selalu mengembalikan data untuk 7 hari.');
            System.assertEquals(1, result[0].taskCount, 'Harusnya ada 1 tugas pada hari pertama.');
            System.assertEquals(1, result[2].taskCount, 'Harusnya ada 1 tugas pada hari ketiga.');
            System.assertEquals(0, result[4].taskCount, 'Harusnya tidak ada tugas yang dihitung pada hari kelima karena sudah selesai.');
        }
    }

    @isTest
    static void testGetTasksForDate_WithTasks() {
        System.runAs(testUser) {
            Account acc = new Account(Name='Heatmap Account');
            insert acc;
            Contact con = new Contact(LastName='Heatmap Contact');
            insert con;
            Date today = Date.today();

            List<Task> tasks = new List<Task>{
                new Task(Subject = 'Task dengan relasi', ActivityDate = today, OwnerId = UserInfo.getUserId(), WhatId = acc.Id, WhoId = con.Id, Status = 'Not Started', Priority = 'Normal'),
                new Task(Subject = 'Task biasa', ActivityDate = today, OwnerId = UserInfo.getUserId(), Status = 'Not Started', Priority = 'Normal')
            };
            
            // DITAMBAHKAN: Blok try-catch untuk debugging
            try {
                insert tasks;
            } catch (Exception e) {
                 System.debug(LoggingLevel.ERROR, '!!! ERROR SAAT MEMBUAT TASK (TasksForDate): ' + e.getMessage());
            }
            
            Long dateMillis = Datetime.newInstance(today, Time.newInstance(0,0,0,0)).getTime();

            Test.startTest();
            List<Task> result = TaskHeatmapController.getTasksForDate(dateMillis);
            Test.stopTest();

            System.assertEquals(2, result.size(), 'Seharusnya menemukan 2 tugas untuk hari ini.');
            System.assertEquals('Heatmap Account', result[0].What.Name, 'Nama Akun pada relasi What tidak cocok.');
            System.assertEquals('Heatmap Contact', result[0].Who.Name, 'Nama Kontak pada relasi Who tidak cocok.');
        }
    }

    @isTest
    static void testGetTasksForDate_NoTasks() {
        System.runAs(testUser) {
            Date today = Date.today();
            Long dateMillis = Datetime.newInstance(today, Time.newInstance(0,0,0,0)).getTime();
            
            Test.startTest();
            List<Task> result = TaskHeatmapController.getTasksForDate(dateMillis);
            Test.stopTest();

            System.assertEquals(true, result.isEmpty(), 'Seharusnya tidak ada tugas yang ditemukan untuk hari ini.');
        }
    }
}