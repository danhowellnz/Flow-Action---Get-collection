  
public with sharing class AutoCompleteController {
    @AuraEnabled(cacheable=true)
    public static List<ResultssObject> getRecords(String searchString, String objectApiName,  String valueFieldApiName, String extendedWhereClause, Integer maxRecords, String extraObjects, String SearchScope, string QueryType){
        searchString = String.escapeSingleQuotes(searchString);
        objectApiName = String.escapeSingleQuotes(objectApiName);
        valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
        if( string.isblank(QueryType)) QueryType = 'search';

        FlowFindCollection.Requests request = new FlowFindCollection.Requests();
            request.sObjectName = objectApiName;
            if(QueryType.toLowerCase() =='search') request.queries = searchString;
            request.scope = SearchScope;
            request.whereClause = extendedWhereClause;
            request.FieldApiINames = valueFieldApiName;
            request.WhereLimit = maxRecords;
            request.SearchExtraObjects = extraObjects;
            system.debug('AutoCompleteController request');
            system.debug(request);

            List<FlowFindCollection.Results> results = FlowFindCollection.execute(
                new List<FlowFindCollection.Requests>{ request }
            );
            
            system.debug('AutoCompleteController results');
            system.debug(results);


        list<Id> outputIds = results[0].outputIds;
        list<String> outputRecordNames = results[0].outputRecordNames;
        list<sobject> outputCollection = results[0].outputCollection;
        List<ResultssObject> returnList = new List<ResultssObject>();
        //add Collection results to a map - to add the value name
        Map<id,string> IdValueMap = new Map<id,string>();

        for(sobject eachRecord : outputCollection){
            IdValueMap.put(eachRecord.get('id')+'',eachRecord.get(valueFieldApiName)+'');
        }
 
        integer i = 0;
        for(Id eachId : outputIds){
            ResultssObject eachResult = new ResultssObject();
            eachResult.recordId = eachId+'';
            eachResult.displayValue = outputRecordNames[i];
            eachResult.PuredisplayValue = outputRecordNames[i];
            eachResult.ObjectAPIName = eachId.getSobjectType().getDescribe().getName();
            eachResult.ObjectLabel = eachId.getSobjectType().getDescribe().getLabel();
            //If has a ValueFromNamedField
            string ValueFromNamedField = IdValueMap.get(eachId);
            if(string.isNotBlank(ValueFromNamedField) && ValueFromNamedField != eachResult.displayValue){ 
                eachResult.displayValue +=  ' ('+IdValueMap.get(eachId)+')';
            } 

            i++;
            returnList.add(eachResult); 
        }

        system.debug('AutoCompleteController Ids found: '+outputIds.size());
        //system.debug(returnList);
        //system.debug('AutoCompleteController_CPU time: '+System.Limits.getCpuTime());
        
        return returnList;
    }

    @AuraEnabled
    public static void saveResult(id  recordId,string fieldAPiName, String value){
        system.debug('AutoCompleteController_saveResult to: '+recordId);
        string ObjectAPIName = recordId.getSobjectType().getDescribe().getName();
        sObject sObj = Schema.getGlobalDescribe().get(ObjectAPIName).newSObject() ;
        sObj.id =recordId;
        sObj.put(fieldAPiName, value);
        update sObj;
    }    

    
    public class ResultssObject { 
        @AuraEnabled  
        public id recordId{get;set;}
        @AuraEnabled
        public string displayValue{get;set;}
        @AuraEnabled
        public string PuredisplayValue{get;set;}
        @AuraEnabled
        public string ObjectAPIName{get;set;}
        @AuraEnabled
        public string ObjectLabel{get;set;}
    }

}