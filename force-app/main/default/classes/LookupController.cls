public with sharing class LookupController {
    private final static Integer MAX_RESULTS = 5;

    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        // Prepare query parameters
        searchTerm += '*';

        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Case(Id, CaseNumber, SCSCaseNumber__c WHERE id NOT IN :selectedIds)
            LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Cases & convert them into LookupSearchResult
        String caseIcon = 'standard:case';
        Case[] cases = (List<Case>) searchResults[0];
        for (Case myCase : cases) {
            String subtitle = myCase.CaseNumber == null ? 'Case Number' : myCase.CaseNumber;
            results.add(new LookupSearchResult(myCase.Id, 'Case', caseIcon, myCase.SCSCaseNumber__c, subtitle));
        }

        // Optionnaly sort all results on title
        results.sort();

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> getRecentlyViewed() {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        List<Case> casesToConvert = new List<Case>();

        // Get recently viewed records of type Account or Opportunity
        List<RecentlyViewed> recentRecords = [
            SELECT Id, Name, Type
            FROM RecentlyViewed
            WHERE Type = 'Case'
            ORDER BY LastViewedDate DESC
            LIMIT 5
        ];

        // Convert recent records into Case
        for (RecentlyViewed recentRecord : recentRecords) {
            casesToConvert.add([SELECT Id, CaseNumber, SCSCaseNumber__c FROM Case WHERE Id = :recentRecord.Id][0]);
        }

        // Convert cases into LookupSearchResult
        for (Case recentCase : casesToConvert) {
            results.add(
                new LookupSearchResult(
                    recentCase.Id,
                    'Case',
                    'standard:case',
                    recentCase.SCSCaseNumber__c,
                    recentCase.CaseNumber
                )
            );
        }

        return results;
    }

    @AuraEnabled(cacheable=true scope='global')
    public static LookupSearchResult getInitialSelection(Id recordId) {
        Case myCase = [SELECT Id, CaseNumber, SCSCaseNumber__c FROM Case WHERE Id = :recordId][0];
        return new LookupSearchResult(myCase.Id, 'Case', 'standard:case', myCase.SCSCaseNumber__c, myCase.CaseNumber);
    }

    
}
