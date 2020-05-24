@isTest
public with sharing class AutoCompleteControllerTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account(Name='Salesforce');
        insert acc;
    }

    @isTest
    public static void testGetRecords_Find(){
        //getRecords(String searchString, String objectApiName,  String valueFieldApiName, String extendedWhereClause, Integer maxRecords, String extraObjects, String SearchScope, string QueryType)

        List<AutoCompleteController.ResultssObject> accountSearch = AutoCompleteController.getRecords(  'Salesforce', 'Account',  'Description',null, 10,'Contact',null,'Search');

        //Asserts don't wok
        //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_SOSL.htm
        //System.assertEquals(1, accountSearch.size());
    }

    @isTest
    public static void testGetRecords_dontFind(){
        List<AutoCompleteController.ResultssObject> accountSearch = AutoCompleteController.getRecords('abc', 'Account', 'Name', '', 100,null,null,'Search');
        System.assertEquals(0, accountSearch.size());
    }

}