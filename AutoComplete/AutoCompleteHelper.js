({
    searchRecords : function(component, searchString) {
        component.set("v.openDropDown", true);
        component.set("v.Loading", true);

        var action = component.get("c.getRecords");
        action.setParams({
            "searchString" : searchString,
            "objectApiName" : component.get("v.objectApiName"),
            "valueFieldApiName" : component.get("v.valueFieldApiName"),
            "extendedWhereClause" : component.get("v.extendedWhereClause"),
            "maxRecords" : component.get("v.maxRecords"),
            "extraObjects" : component.get("v.extraObjects"),
            "SearchScope" : component.get("v.SearchScope"),
            "QueryType" : component.get("v.QueryType")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                const serverResult = response.getReturnValue();
                const results = [];
                //console.log(serverResult);
                serverResult.forEach(element => {
                    let ObjectAPIName = element['ObjectAPIName'];
                    let IconName = 'standard:'+ObjectAPIName.toLowerCase();
                    if(IconName=='standard:emailmessage'){ IconName='standard:email';}
                    if(ObjectAPIName.includes("__c")){
                        IconName = 'standard:display_text';
                    }

                    let displayValue = component.get("v.extraObjects").length>0 ? element['ObjectLabel']+': ' : '';
                    displayValue += element['displayValue'];

                    const result = {id : element['recordId'], Displayvalue : displayValue, ObjectName : element['ObjectLabel'], IconName : IconName, PureDisplayvalue : element['PureDisplayvalue']};
                    results.push(result);
                    
                });
                component.set("v.Loading", false);
                component.set("v.results", results);
                if(serverResult.length>0){
                    component.set("v.openDropDown", true);
                }
            } else{
                var toastEvent = $A.get("e.force:showToast");
                if(toastEvent){
                    toastEvent.setParams({
                        "title": "ERROR",
                        "type": "error",
                        "message": "Something went wrong!! Check server logs!!"
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})