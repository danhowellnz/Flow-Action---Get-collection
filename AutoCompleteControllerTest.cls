@isTest
public  class AutoCompleteControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account(Name='Salesforce');
        insert acc;
    }

    @isTest
    public static void testGetRecords_Find(){
        //getRecords(String searchString, String objectApiName,  String valueFieldApiName, String extendedWhereClause, Integer maxRecords, String extraObjects, String SearchScope, string QueryType)

        //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_SOSL.htm
        List<Id> fixedSearchResults = new List<Id>();
        Id resultId = [select id from account limit 1][0].Id;
        fixedSearchResults.add(resultId);

        Test.setFixedSearchResults(fixedSearchResults);

        List<AutoCompleteController.ResultssObject> accountSearch = AutoCompleteController.getRecords(  'Salesforce', 'Account',  'Description',null, 10,'Contact',null,'Search', false);
        System.assertEquals(1, accountSearch.size());

        //Save result
        account acc = [select id from account limit 1][0];
        AutoCompleteController.saveResult(acc.id,'name', 'new name');
    }

    @isTest
    public static void testGetRecords_Find_nosharing(){

        List<Id> fixedSearchResults = new List<Id>();
        Id resultId = [select id from account limit 1][0].Id;
        fixedSearchResults.add(resultId);

        Test.setFixedSearchResults(fixedSearchResults);

        List<AutoCompleteController.ResultssObject> accountSearch = AutoCompleteController.getRecords(  'Salesforce', 'Account',  'Description',null, 10,'Contact',null,'Search', true);
        System.assertEquals(1, accountSearch.size());

        //Save result
        account acc = [select id from account limit 1][0];
        AutoCompleteController.saveResult(acc.id,'name', 'new name');
    }

    @isTest
    public static void testGetRecords_dontFind(){
        List<AutoCompleteController.ResultssObject> accountSearch = AutoCompleteController.getRecords('abc', 'Account', 'Name', '', 100,null,null,'Search',null);
        System.assertEquals(0, accountSearch.size());
    }



}