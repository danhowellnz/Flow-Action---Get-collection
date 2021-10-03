public class AutoCompleteController {
    @AuraEnabled(cacheable=true)
    public static List<ResultssObject> getRecords(String searchString, String objectApiName,  String valueFieldApiName, String extendedWhereClause, Integer maxRecords, String extraObjects, String SearchScope, string QueryType, boolean Bypasssharing){
        searchString = escapeSosl(searchString);
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




        /**
     * Designed to prepare text input for the FIND { phrase } part of SOSL query.
     *
     * Removes reserved logical operators: AND NOT, AND, OR
     * Escapes special characters: ? & | ! { } [ ] ( ) ^ ~ * : " ' + -
     *
     * Does not handle backslash (\) so do not include it in the text input.
     * Returns null if text is blank.
     *
     * https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_sosl_find.htm
     */
    public static String escapeSosl( String text ) {

        System.debug( 'escaping sosl term: ' + text );

        String escapedText;

        if ( String.isBlank( text ) ) {

            escapedText = null;

        } else {

            // Escaping characters is a bit annoying because
            // we are having to plan for multiple levels of evaluation of the escaped characters:
            //  1. Apex   -- this code requires double slahes (\\) to equate to a single slash (\) in the string literal
            //  2. Regex  -- when the replaceAll method parses the input sequence the apex \\ is read as a single \, so have to double up again in Apex to get \\ in regex land
            //  3. SOSL   -- when Search.query() method parses the query string it expects valid apex string literal, so any \ must be escaped as \\

            // In addition to my below logic, you can check out some other solutions here:
            // http://salesforce.stackexchange.com/questions/64757/function-to-properly-escape-dynamic-sosl-input

            // escape single quotes
            // we do not handle the single quote escaping in the matcher.replaceAll method along with the other escaping because we would end up with incorrect number of slashes
            escapedText = String.escapeSingleQuotes( text ) ;

            // remove special logical operators from the term (case insensitive)
            // these are keywords for SOSL, can't escape them so we exclude them from the search term
            escapedText = escapedText.replaceAll( '(?i)( AND NOT | AND | OR )', ' ' );

            // escape reserved characters
            // note, we handled single quotes above already
            // note, we do not handle \, it ends up being overly escaped
            // ? & | ! { } [ ] ( ) ^ ~ * : \ " ' + -
            Pattern myPattern = Pattern.compile( '(\\?|\\&|\\||\\!|\\{|\\}|\\[|\\]|\\(|\\)|\\^|\\~|\\*|\\:|\\"|\\+|\\-)' );
            Matcher myMatcher = myPattern.matcher( escapedText );

            // remember all the notes above about the 7 circles of hell of escaping text for apex, regex, sosl??
            // so all that comes into play here when we now perform the escaping of the matched special characters
            // we need 8 slashes (\\\\\\\\)
            //      ...in apex that translates into a string literal of just 4 (\\\\)
            //      ...once the replaceAll method runs it parses the input as regex, and regex like apex needs slashes escaped so the 4 (\\\\) it received is interpreted as regex literal of 2 (\\)
            //      ...we return the apex literal string with each special character now prefixed with 2 slashes (\\)
            //      ...when Search.query() method parses the escaped string literal we return from here those 2 slashes (\\) get interpreted as 1 slash (\)
            escapedText = myMatcher.replaceAll( '\\\\\\\\$1' );

            // collapse repeated whitespace
            escapedText = escapedText.replaceAll( '( )+', ' ' ).trim();

        }

        System.debug( 'escaped sosl term: ' + escapedText );

        return escapedText;
    }

}
