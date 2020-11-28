public class AutoCompleteController {
    @AuraEnabled(cacheable=true)
    public static List<ResultssObject> getRecords(String searchString, String objectApiName,  String valueFieldApiName, String extendedWhereClause, Integer maxRecords, String extraObjects, String SearchScope, string QueryType, boolean Bypasssharing){
        searchString = String.escapeSingleQuotes(searchString);
        if(string.isnotblank(objectApiName)) objectApiName = String.escapeSingleQuotes(objectApiName);
        if(string.isnotblank(valueFieldApiName)) valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
        if( string.isblank(QueryType)) QueryType = 'search';

        FlowFindCollection.Requests request = new FlowFindCollection.Requests();
            request.sObjectName = objectApiName;
            if(QueryType.toLowerCase() =='search') request.queries = searchString;
            request.scope = SearchScope;
            request.whereClause = extendedWhereClause;
            request.FieldApiINames = valueFieldApiName;
            request.WhereLimit = maxRecords;
            request.SearchExtraObjects = extraObjects;


            if(Bypasssharing== true){ 
                request.BypassSharing = Bypasssharing;
            }



            //Add the searchString where statement
            if(QueryType.toLowerCase() =='select'){
                request.whereClause = ' '+valueFieldApiName+'  like\'%'+searchString+'%\'';
                if( string.isNotBlank(extendedWhereClause)) request.whereClause += ' AND '+extendedWhereClause; 
                
            }

            //if searching on an id value
            if( searchString != null && (searchString.length() ==15 || searchString.length() == 18) ){
                try{
                    id recordid = id.valueOf(searchString);
                    request.whereClause = ' id = \''+searchString+'\' ';
                    if( string.isNotBlank(extendedWhereClause)) request.whereClause += ' AND '+extendedWhereClause; 
                    request.queries = null;
                }
                catch( Exception e){}

            }


            system.debug('AutoCompleteController request');
            system.debug(request);
            List<FlowFindCollection.Results> results = FlowFindCollection.execute(
                new List<FlowFindCollection.Requests>{ request }
            );
            
            




        list<Id> outputIds = results[0].outputIds;
        list<String> outputRecordNames = results[0].outputRecordNames;
        list<sobject> outputCollection = results[0].outputCollection;
        List<ResultssObject> returnList = new List<ResultssObject>();
        //add Collection results to a map - to add the value name
        Map<id,string> IdValueMap = new Map<id,string>();

        system.debug('AutoCompleteController results');
        system.debug(outputIds);
        system.debug(outputRecordNames);
        system.debug(outputCollection);

        for(sobject eachRecord : outputCollection){
            string value = '';
            if(string.isNotBlank(valueFieldApiName)) value =eachRecord.get(valueFieldApiName)+'';
            IdValueMap.put(eachRecord.get('id')+'',value);
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
                if(string.isnotblank(eachResult.displayValue )) eachResult.displayValue += ' ('+ValueFromNamedField+')';
                else eachResult.displayValue += IdValueMap.get(eachId)+'';
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