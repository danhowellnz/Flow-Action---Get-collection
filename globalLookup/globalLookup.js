import { LightningElement,api,track } from 'lwc';
import searchRecords from '@salesforce/apex/AutoCompleteController.getRecords';
import saveResultApex from '@salesforce/apex/AutoCompleteController.saveResult';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent,FlowNavigationBackEvent,FlowNavigationPauseEvent,FlowNavigationFinishEvent  } from 'lightning/flowSupport';
import { updateRecord } from 'lightning/uiRecordApi';

export default class AutoCompleteLWC extends LightningElement {
    @api label;
    @api objectApiNameInput;
    @api valueFieldApiName;
    @api idFieldApiName = "id";
    @api extendedWhereClause;
    @api maxRecords;
    @api extraObjects;
    @api searchScope;
    @api selectedOption;
    @api queryType;
    @api inputFieldAPIName;
    @api StartingValue;
    @api FlowAction;
    @api Bypasssharing;
    @api LoadPreloadedRecordId = false;

    @track results = [];
    @track openDropDown = false;
    @api inputValue;
    @track inputSearchFunction;
    @track loading = false;
    @track searchedValue;
    @track cardStyle = "";
    @track RecentlyTyped = false;
    @api recordId;
    @api availableActions = [];

    connectedCallback(){

        if(this.recordId != null){
            this.cardStyle = "CardPadding";
            
        }
        this.inputValue = "";

        if(this.selectedOption != null){
            this.recordId = this.selectedOption;
            this.LoadPreloadedRecordId = true;
            this.searchRecordsLWC(this.selectedOption);
        }

        if(this.StartingValue != null ){
            this.searchedValue = this.StartingValue;
            this.inputValue = this.StartingValue;
            this.openDropDown = true;
            this.loading = true;

            setTimeout(() => { //delayed so input is rendered
                const  target = this.template.querySelector('input');
                if(target!=null) target.value = this.searchedValue;
                let keyupEvent = new Event('keyup');
                if(target!=null) target.dispatchEvent(keyupEvent);


                if(this.StartsWithRecordId ){
                    setTimeout(() => { 
                        console.log('here');
                    }, 1000);
                }


            }, 300);

        }
    }

    @api
    get labelClass(){
        return (this.label === "" || this.label === null || this.label === undefined) ? "display:hidden" : "display:block" ;
    }

    @api
    get classValueCombo(){
        return this.openDropDown ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open" : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
    }

    @api 
    get ShowSearchIcon(){
        return ((this.selectedOption === "" || this.selectedOption === null || this.selectedOption === undefined) && this.openDropDown === false) ? true : false;
    }
    
    @api
    get showSavebutton(){
        return (this.recordId !== undefined && this.recordId !== null && this.recordId !== ""   &&
        this.inputFieldAPIName !== undefined && this.inputFieldAPIName !== null && this.inputFieldAPIName !== "") 
        ? true : false;
    }

    @api
    get buttonDisabled(){
        return ((this.recordId === undefined || this.recordId === null || this.recordId === "") || 
                (this.selectedOption === undefined || this.selectedOption === null || this.selectedOption === "")) ? true : false ;
    }
    searchHandler(event) {
        this.inputValue = event.target.value ? event.target.value : "";
        debugger;
        let searchString = this.inputValue;
        if (searchString.length >= 3) {

            if(this.RecentlyTyped == false){
                this.RecentlyTyped = true;
                this.searchedValue = searchString;
                this.searchRecordsLWC(searchString);

                 setTimeout(() => {
                    this.RecentlyTyped = false;
                    this.searchRecordsLWC(searchString);
                }, 1000);
            }

        } else{
            this.results = [];
            this.openDropDown = false;
        }
    }
    searchRecordsLWC(searchString){
        this.openDropDown = true;
        this.loading = true;

        searchRecords({
            "searchString" : searchString,
            "objectApiName" : this.objectApiNameInput ,
            "valueFieldApiName" : this.valueFieldApiName,
            "extendedWhereClause" : this.extendedWhereClause,
            "maxRecords" : this.maxRecords,
            "extraObjects" : this.extraObjects,
            "SearchScope" : this.searchScope,
            "QueryType" : this.queryType,
            "Bypasssharing" : this.Bypasssharing
            })
            .then(result => {
                const serverResult = result;
                const results = [];
                serverResult.forEach(element => {
                    let ObjectAPINameResult = element['ObjectAPIName'];
                    let IconName = 'standard:'+ObjectAPINameResult.toLowerCase();
                    if(IconName=='standard:emailmessage'){ IconName='standard:email';}

                    if(ObjectAPINameResult.toLowerCase() == 'environmenthubmember'){ IconName='standard:data_integration_hub';}
                    //Ah products why are you 2
                    if(ObjectAPINameResult.includes("2")){ IconName='standard:'+ObjectAPINameResult.toLowerCase().replace("2", "");}

                    if(ObjectAPINameResult.includes("__c")){
                        IconName = 'standard:display_text';
                    }
						
                    let displayValue = this.extraObjects != undefined && this.extraObjects.length>0 ? element['ObjectLabel']+': ' : '';
                    displayValue += element['displayValue'];

                    if(this.LoadPreloadedRecordId ==true){
                        this.inputValue = displayValue;
                    }
                    const result = {id : element['recordId'], Displayvalue : displayValue, ObjectAPINameResult : element['ObjectAPIName'], IconName : IconName, PureDisplayvalue : element['PuredisplayValue']};
                    results.push(result);
                    //console.log(result);
                });
                this.loading = false;
                this.results = results;
                
            	
                if(serverResult.length>0){
                    this.openDropDown = true;
                }else{
                    this.openDropDown = false;
                }

                if(this.LoadPreloadedRecordId ==true){
                    console.log(this.inputValue);
                    this.LoadPreloadedRecordId = false;
                    this.openDropDown = false;
                }
                
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: "ERROR",
                    message: "Something went wrong!! Check server logs!!",
                    variant: "error"
                });
                this.dispatchEvent(evt);
            });
    }
    closeLookup() {
        this.loading = false;
        this.openDropDown = false;
    }
    
    searchHandlerFocus(event) {
        //this.searchedValue = event.target.value;
        let searchedValue = this.searchedValue;
        
        if(searchedValue !== null && searchedValue !== "" && searchedValue !== undefined){
           // console.log('searchHandlerFocus: '+ searchedValue);
            this.inputValue = this.searchedValue;
            event.target.value = searchedValue;
            let keyupEvent = new Event('keyup');
            event.target.dispatchEvent(keyupEvent);
        }
    }
    optionClickHandler(event) {
        const selectedId = event.target.closest('li').dataset.id;
        const selectedValue = event.target.closest('li').dataset.value;
        this.inputValue = selectedValue;
        this.openDropDown = false;
        this.selectedOption = selectedId;

        console.log('selectedId: '+selectedId);
        console.log('FlowAction: '+this.FlowAction);

        // notify the flow of the new value
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedOption', this.selectedOption);
        this.dispatchEvent(attributeChangeEvent);


        // check if NEXT is allowed on this screen
        if(this.FlowAction != null){this.FlowAction= this.FlowAction.toUpperCase();}
        if (this.availableActions.find(action => action === this.FlowAction)) {
            console.log('Fire:'+this.FlowAction.toUpperCase());
            if(this.FlowAction.toUpperCase() =='NEXT'){
                console.log('2');
                const nextNavigationEvent  = new FlowNavigationNextEvent();
                this.dispatchEvent(nextNavigationEvent );
            }if(this.FlowAction.toUpperCase() =='PREVIOUS'){
                const backNavigationEvent = new FlowNavigationBackEvent();
                this.dispatchEvent(backNavigationEvent );
            }if(this.FlowAction.toUpperCase() =='BACK'){
                const backNavigationEvent = new FlowNavigationBackEvent();
                this.dispatchEvent(backNavigationEvent );
            }if(this.FlowAction.toUpperCase() =='PAUSE'){
                const pauseNavigateEvent = new FlowNavigationPauseEvent();
                this.dispatchEvent(pauseNavigateEvent );
            }if(this.FlowAction.toUpperCase() =='FINISH'){
                const finishNavigateEvent = new FlowNavigationFinishEvent(); 
                this.dispatchEvent(finishNavigateEvent );
            }
        }

    }

    NewRecordHandler(event) {
        this.inputValue = null;
        this.openDropDown = false;
        this.selectedOption = null;
        //this.dispatchEvent(new CustomEvent('addnewrecord'));

        const defaultValues = encodeDefaultFieldValues({
            //FirstName: 'Morag',
            //LastName: 'de Fault',
            //LeadSource: 'Other'
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiNameInput,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues // and here we set defaults as a nav parameter
            }
        });


    }

    saveResultTrigger() {
        console.log('save '+this.selectedOption+' to: '+this.inputFieldAPIName+' on '+this.recordId);

        saveResultApex({
                "recordId" : this.recordId,
                "fieldAPiName" : this.inputFieldAPIName,
                "value" : this.selectedOption,
            })
            .then(result => {
                const evt = new ShowToastEvent({
                    title: "SUCCESS",
                    message: "Saved",
                    variant: "success"
                });
                this.dispatchEvent(evt);
                //window.reload();
                //$A.get('e.force:refreshView').fire();
                // a way (WORKAROUND) to refresh data in standard components
                updateRecord({ fields: { Id: this.recordId } });

            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: "ERROR",
                    message: "Saving Global Lookup: Something went wrong, check debug logs!",
                    variant: "error"
                });
                this.dispatchEvent(evt);
            });
    }
    clearOption(){
        this.results = [];
        this.openDropDown = false;
        this.inputValue = "";
        this.selectedOption = "";
        this.searchedValue = "";

        // notify the flow of the new value
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedOption', null);
        this.dispatchEvent(attributeChangeEvent);

    }
}