({
    
    Init : function (component, event, helper) {

        //If on record Page
       if(component.get("v.recordId")!=null){
        component.set("v.CardStyle", "CardPadding");
       }
       console.log('Global Lookup made with love by the team at GravityLab.nz if you are a New Zealand based Salesforce guru, care about great results and have great communication skills get in touch.');
       
    },    

    searchHandler : function (component, event, helper) {
        let searchString = event.target.value;
        
        if (searchString.length >= 3) {
            component.set("v.openDropDown", true);

            //Ensure that not many function execution happens if user keeps typing
            if (component.get("v.inputSearchFunction")) {
                clearTimeout(component.get("v.inputSearchFunction"));
            }

            var inputTimer = setTimeout($A.getCallback(function () {
                component.set("v.searchedValue", searchString);
                helper.searchRecords(component, searchString);
            }), 700);
            component.set("v.inputSearchFunction", inputTimer);
        } else{
            component.set("v.results", []);
            component.set("v.openDropDown", false);
        }
    },

    searchHandlerFocus : function (component, event, helper) {
        let searchedValue = component.get("v.searchedValue");
        if(searchedValue != null && searchedValue!=""){
            component.set("v.inputValue", searchedValue);
        //call searchhandler
        
        event.target.value = searchedValue;
        let keyupEvent = new Event('keyup');
        event.target.dispatchEvent(keyupEvent);
        }
        
    },

    optionClickHandler : function (component, event, helper) {
        const selectedId = event.target.closest('li').dataset.id;
        const selectedValue = event.target.closest('li').dataset.value;
        component.set("v.inputValue", selectedValue);
        component.set("v.openDropDown", false);
        component.set("v.selectedOption", selectedId);
    },


    clearOption : function (component, event, helper) {
        component.set("v.results", []);
        component.set("v.openDropDown", false);
        component.set("v.inputValue", "");
        component.set("v.selectedOption", "");
        component.set("v.searchedValue", "");
    },
    
    closeLookup : function (component, event, helper) {
        component.set("v.Loading", false);
        component.set("v.openDropDown", false);
    },

    saveResultTrigger : function (component, event, helper) {
        console.log('save '+component.get("v.selectedOption")+' to: '+component.get("v.InputFieldAPIName")+' on '+component.get("v.recordId"));
        var action = component.get("c.saveResult");
        action.setParams({
            "recordId" : component.get("v.recordId"),
            "fieldAPiName" : component.get("v.InputFieldAPIName"),
            "value" : component.get("v.selectedOption"),
        });
        action.setCallback(this,function(response) {
            var toastEvent = $A.get("e.force:showToast");
            if (response.getState() === "SUCCESS") {
                    toastEvent.setParams({
                        "title": "SUCCESS",
                        "type": "success",
                        "message": "Saved"
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
            } else{
                    toastEvent.setParams({
                        "title": "ERROR",
                        "type": "error",
                        "message": "SAveing Globbal Lookup: Something went wrong, check debug logs!"
                    });
                    toastEvent.fire();
            }
        });
        $A.enqueueAction(action);

    },
})