public with sharing class FlowFindCollection{


    // defines the input parameters of this flow element in the canvas designer
public class Requests { 
    
    @InvocableVariable(label='FieldApiIName' description='Comma serperated list of api names' required=true)
    public string FieldApiINames;

    @InvocableVariable(label='WhereClause' description='eg. where createddate = last_n_years:2' required=false)
    public string WhereClause;
    
    @InvocableVariable(label='sObjectName' description='eg. Account' required=true)
    public string sObjectName;

    @InvocableVariable(label='List Of Ids' description='' required=false)
    public list<Id> IdsList;

    @InvocableVariable(label='Bypass sharing rules' description='' required=false)
    public boolean BypassSharing;

} 


public class Results {     
    @InvocableVariable
    public list<SObject> outputCollection;
  }   
    
 @InvocableMethod(label='Get Collection as SObject' description=' ')
 public static List <Results>  execute( List<Requests> requests ) {

        //Wrap the Results object in a List container 
        //(an extra step added to allow this interface to also support bulkification)
        List<Results> responseWrapper= new List<Results>();
        

     for ( Requests request : requests ) {
        List<Id> ListOfIds = request.IdsList;

        string WhereClause = '';
        WhereClause += request.WhereClause == null ? '' : request.WhereClause;
        //Has IN LISt
        if(request.IdsList!=null){
            WhereClause += request.WhereClause == null ? '' : ' AND ';
            WhereClause +=  ' Id IN :ListOfIds';
        }
        
        //Where not blank so add in WHERE
        WhereClause = WhereClause == '' ? '' :  ' WHERE '+WhereClause; 
         
        //add ID field to lookup if missing
        string selectClause =  request.FieldApiINames.containsIgnoreCase('id') ?  request.FieldApiINames : ' Id,'+ request.FieldApiINames ;
         
        //create soql string
        string soql =  'SELECT '+selectClause+' FROM '+request.sObjectName+' '+WhereClause;
        system.debug('FlowFindCollectiong____'+soql);
         
        //Run query with or without sharing
        Results response = new Results();
        system.debug('FlowFindCollectiong____BypassSharing:'+request.BypassSharing);
        if(request.BypassSharing==true){
            response.outputCollection = FlowFindCollection_WithoutSharing.FlowFindCollection_WithoutSharing(soql,ListOfIds);
        }else{
            //No sharing
            response.outputCollection =  Database.query(soql);
        }
        
        //system.debug(response.outputCollection);
        responseWrapper.add(response);

        
     }    
     
     return responseWrapper;
}    





}