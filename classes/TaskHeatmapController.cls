public with sharing class TaskHeatmapController {

    public class DayWrapper {
        @AuraEnabled public String dayName { get; set; }
        @AuraEnabled public Integer taskCount { get; set; }
        @AuraEnabled public String heatmapClass { get; set; }
        @AuraEnabled public Long dateMillis { get; set; }

        public DayWrapper(String dayName, Integer taskCount, Date d) {
            this.dayName = dayName;
            this.taskCount = taskCount;

            this.dateMillis = Datetime.newInstance(d, Time.newInstance(0,0,0,0)).getTime();

            if (taskCount == 0) { this.heatmapClass = 'heatmap-low'; }
            else if (taskCount <= 3) { this.heatmapClass = 'heatmap-medium'; }
            else { this.heatmapClass = 'heatmap-high'; }
        }
    }

    @RemoteAction
    public static List<DayWrapper> getWeeklyTaskData(Long startMillis) {

        Date startDate = Datetime.newInstance(startMillis).date();
        List<DayWrapper> weeklyData = new List<DayWrapper>();
        Map<Date, Integer> taskCountByDate = new Map<Date, Integer>();

        for (Integer i = 0; i < 7; i++) {
            taskCountByDate.put(startDate.addDays(i), 0);
        }

        List<Task> tasks = [
            SELECT ActivityDate FROM Task
            WHERE OwnerId = :UserInfo.getUserId() AND ActivityDate >= :startDate
            AND ActivityDate <= :startDate.addDays(6) AND Status != 'Completed'
        ];

        for (Task t : tasks) {
            Date taskDate = t.ActivityDate;
            if (taskCountByDate.containsKey(taskDate)) {
                taskCountByDate.put(taskDate, taskCountByDate.get(taskDate) + 1);
            }
        }

        for (Integer i = 0; i < 7; i++) {
            Date currentDay = startDate.addDays(i);
            String dayName = Datetime.newInstance(currentDay, Time.newInstance(0,0,0,0)).format('EEEE');
            Integer count = taskCountByDate.get(currentDay);
            weeklyData.add(new DayWrapper(dayName, count, currentDay));
        }
        return weeklyData;
    }

    @RemoteAction
    public static List<Task> getTasksForDate(Long dateMillis) {

        Date selectedDate = Datetime.newInstance(dateMillis).date();
        
        List<Task> tasks = [
            SELECT Id, Subject, Status, Who.Name, What.Name FROM Task
            WHERE OwnerId = :UserInfo.getUserId() AND ActivityDate = :selectedDate
            AND Status != 'Completed' ORDER BY CreatedDate DESC
        ];

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, tasks);
        return decision.getRecords();
    }
}