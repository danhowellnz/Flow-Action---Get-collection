public with sharing class FlowFindCollection{
        //Store Name fields for objects
        public static map<string,String> ObjectNameMap = new map<string,String> ();

    // defines the input parameters of this flow element in the canvas designer
public class Requests { 
    
    @InvocableVariable(label='2.FieldApiIName - to return' description='Comma serperated list of api names' required=true)
    public string FieldApiINames;

    @InvocableVariable(label='3.Where Clause for this object' description='eg. where createddate = last_n_years:2' required=false)
    public string WhereClause;
    
    @InvocableVariable(label='1.ObJect API Name' description='eg. Account or custom__c' required=true)
    public string sObjectName;

    @InvocableVariable(label='4.List of Ids to Limit Get to' description='' required=false)
    public list<Id> IdsList;

    @InvocableVariable(label='5.Bypass sharing rules' description='' required=false)
    public boolean BypassSharing;

    @InvocableVariable(label='6.Search Queries,  comma seperated list of values to search for' description='A list of queries / search terms to apply to the SOSL search' required=false)
    public String queries;

    @InvocableVariable(label='7.Search Scope' description='The scope of the SOSL search (default ALL FIELDS)')
    public String scope;

    @InvocableVariable(label='8.Search Extra Objects for Ids eg. Account,Opportunity,Case,Lead,User' description='eg. Account or custom__c' required=false)
    public string SearchExtraObjects;

} 


public class Results {     
    @InvocableVariable(label='1.Record Collection')
    public list<SObject> outputCollection;

    @InvocableVariable(label='2.Ids (String Collection)')
    public list<Id> outputIds;

    @InvocableVariable(label='3.Record Names (String Collection)')
    public list<Id> outputRecordNames;
  }   
    
 @InvocableMethod(label='Get / Search with APEX' description=' ')
 public static List <Results>  execute( List<Requests> requests ) {

    //Ini repsonse
    List<Results> responseWrapper= new List<Results>();
                   

    //Start loop
     for ( Requests request : requests ) {
        //Vars
        List<Id> ListOfIds = request.IdsList;
        Results response = new Results();
        response.outputCollection = new list<SObject>();
        response.outputIds = new list<Id>();


        //SELECT
        if( string.isblank(request.queries) ){
            string fieldAPINames_commaSepereated = getfieldAPINames_commaSepereated(request.FieldApiINames, request.sObjectName);
      
            string WhereClause = '';
            WhereClause += request.WhereClause == null ? '' : request.WhereClause;
            //Has IN LISt
            if(request.IdsList!=null){
                WhereClause += request.WhereClause == null ? '' : ' AND ';
                WhereClause +=  ' Id IN :ListOfIds';
            }
            
            //Where not blank so add in WHERE
            WhereClause = WhereClause == '' ? '' :  ' WHERE '+WhereClause; 
            string selectClause =  fieldAPINames_commaSepereated;
  
            //create soql string
            string soql =  'SELECT '+selectClause+' FROM '+request.sObjectName+' '+WhereClause;
            system.debug('FlowFindCollectiong____'+soql);

            
            //---SHARING---//
            //Run query with or without sharing
            if(request.BypassSharing==true){
                response.outputCollection = FlowFindCollection_WithoutSharing.FlowFindCollection_WithoutSharing(soql,ListOfIds);
            }else{
                //No sharing
                response.outputCollection =  Database.query(soql);
            }
            //Save all Ids
            Set<Id> Uniqueids = (new Map<Id,Sobject>(response.outputCollection)).keySet().clone();
            response.outputIds.addAll(Uniqueids);

            
            //system.debug(response.outputCollection);
            responseWrapper.add(response);


         }



        //------------SEARCH-------------//
        
        if(string.isNotBlank(request.queries) ){
            responseWrapper.add( Execute_Search(request) );
        }





        
     } //end loop   
     
     return responseWrapper;
}    


   private static results Execute_Search (Requests request){
            string fieldAPINames_commaSepereated = getfieldAPINames_commaSepereated(request.FieldApiINames, request.sObjectName);
            Results response = new Results();
            response.outputCollection = new list<SObject>();
            response.outputIds = new list<Id>();
            response.outputRecordNames = new list<string>();           
  
            //String queryString = string.escapeSingleQuotes(request.queries);
            String queryString = request.queries.replaceAll('\'', '"');

            //If no quotes added
            if( !queryString.contains('\'') && !queryString.contains('\"')){
                queryString = '"'+queryString+'"';
            }
        
            System.debug('FlowFindCollection__execute queryString >>>'+queryString);

            //if has extra objects to saerch - get the name and id
            string ExtraObjects ='';
            if(String.isNotBlank(request.SearchExtraObjects)){
                string SearchExtraObjects = request.SearchExtraObjects.replaceAll(' ','').toLowerCase(); //remove all whitespace
                SearchExtraObjects = SearchExtraObjects.replaceAll(request.sObjectName.toLowerCase()+',',''); //remove duplicates
                SearchExtraObjects = SearchExtraObjects.replaceAll(request.sObjectName.toLowerCase(),'');

                for(string EachObject : SearchExtraObjects.split(',') ){
                    SObjectType ObjectType = Schema.getGlobalDescribe().get(EachObject);
                    Map<String,Schema.SObjectField> mfields = ObjectType.getDescribe().fields.getMap();

                    string NameField = getNameUniqueField(ObjectType).toLowerCase();
                    system.debug('FlowFindCollection__ExtraObject >>>'+EachObject+' | '+NameField);
                    ObjectNameMap.put(EachObject.toLowerCase(), NameField);

                    ExtraObjects += EachObject;
                    ExtraObjects +='(Id';  // all records have id
                    if( mfields.get(NameField)!=null){ ExtraObjects += ','+NameField;} //Has Name on the object
                    ExtraObjects += '),';
                }
                ExtraObjects = ExtraObjects.removeEnd(',');
            }
            //Add lookup object
            SObjectType ObjectType = Schema.getGlobalDescribe().get(request.sObjectName);
            string NameField = getNameUniqueField(ObjectType).toLowerCase();
            ObjectNameMap.put(request.sObjectName.toLowerCase(), NameField);
           


            System.debug(ObjectNameMap);

            // Build SOSL
            String sosl  = 'FIND {'+queryString+'}';
            sosl  += String.isNotBlank(request.scope) ? ' IN ' + request.scope : '';
            sosl  +=  ' RETURNING ';
            sosl  +=  request.sObjectName+'('+fieldAPINames_commaSepereated;
            sosl  += String.isNotBlank(request.whereClause) ? ' WHERE ' + request.whereClause : '';
            sosl  +=')';
            sosl  += String.isNotBlank(ExtraObjects) ? ','+ExtraObjects: '';


            System.debug('FlowFindCollection__execute sosl >>>'+sosl);
            // Execute the SOSL search

            List<List<SObject>> searchList;

            if(request.BypassSharing==true){
                searchList = FlowFindCollection_WithoutSharing.FlowSearchCollection_WithoutSharing(sosl);
            }
            else{
                //searchResults = Search.find(sosl);
                searchList = search.query(sosl);
            }


            //Loop for results and add to return collection
            Integer NumberOfObjectsSearched = searchList.size();
            Integer NumberOfRecordsFound = 0;
            list<Id> AllIds = new list<id>();
            list<String> AllNames = new list<String>();

            for(List<SObject> EachsearchList : searchList ){ 
                string ObjectName = EachsearchList.getSObjectType().getDescribe().getName().toLowerCase() +'';
                NumberOfRecordsFound += EachsearchList.size();
                for(SObject EachRecord : EachsearchList){
                    //system.debug('FOR'+'SObject EachRecord : EachsearchList');
                    AllIds.add(EachRecord.Id);
                    string NamefieldonObject = ObjectNameMap.get( ObjectName)+'';
                    try{//Names are finicky, let's not fail on that
                        AllNames.add( EachRecord.get(NamefieldonObject)+'');}  //Get field api name from map
                    catch (exception e){AllNames.add(' ');}
                }
                if( EachsearchList.getSObjectType()+'' == request.sObjectName ){
                    response.outputCollection.addAll(EachsearchList);
                }
            }
            if(AllIds.size()>0) response.outputIds.addAll(AllIds);
            if(AllNames.size()>0) response.outputRecordNames.addAll(AllNames);

            System.debug('NumberOfObjectsSearched: '+NumberOfObjectsSearched);
            System.debug('NumberOfRecordsFound: '+NumberOfRecordsFound);


            return response;
        
   } 
   


//UTILITIES

    private static string getfieldAPINames_commaSepereated(string FieldApiINames, string sObjectName){
        string fieldAPINames_commaSepereated = '';
        //Generate fields to find
        if(FieldApiINames.contains('*') ){  //If has * get all fields
            SObjectType ObjectType1 = Schema.getGlobalDescribe().get(sObjectName);
            Map<String,Schema.SObjectField> mfields1 = ObjectType1.getDescribe().fields.getMap();
            for (String SObjectField : mfields1.keySet()){
                fieldAPINames_commaSepereated += SObjectField+',';
            }
            fieldAPINames_commaSepereated = fieldAPINames_commaSepereated.removeEnd(',');
        }
        else{
            //add ID field to apinames if missing
            FieldApiINames = string.isBlank(FieldApiINames) ? 'id' : FieldApiINames;
                fieldAPINames_commaSepereated =  FieldApiINames.containsIgnoreCase('id') ?  FieldApiINames : ' Id,'+ FieldApiINames ;
        }
        return fieldAPINames_commaSepereated;
    }


    private static String getNameUniqueField(Schema.sObjectType objType){
        Schema.DescribeSObjectResult ObjResult =  objType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = ObjResult.Fields.getMap();
        for(Schema.SObjectField objField : mapFields.values() ){
            if(objField.getDescribe().isNameField()){
                return objField.getDescribe().getName();
            }
            if(objField.getDescribe().isAutoNumber()){
                return objField.getDescribe().getName();

            }
            if(objField.getDescribe().isUnique()){
                return objField.getDescribe().getName();

            }
        }
        
        return 'Name';

    }


}