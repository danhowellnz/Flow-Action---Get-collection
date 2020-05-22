public without sharing class FlowFindCollection_WithoutSharing {
    public static list<sobject> FlowFindCollection_WithoutSharing(string soql, list<id> ListOfIds) {
        system.debug('FlowFindCollection_WithoutSharing');
        return Database.query(soql);
    }
    public static List<List<SObject>> FlowSearchCollection_WithoutSharing(string sosl) {
        return Search.query(sosl);
    }    
}