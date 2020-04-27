# Flow-Action---Get-collection

**What does it do?**

It’s a new flow action to make the most of generic Sobjects :)

It can use
- Dynamic where clauses - define as text
- Work with any object
- Use IN statements - If you provide a list of Ids
- Bypass sharing rules (this is useful sometimes)


**Install**
- Production: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t7F000005EwuV
- Sandbox: https://test.salesforce.com/packaging/installPackage.apexp?p0=04t7F000005EwuV
- Source code: https://github.com/danhowellnz/Flow-Action---Get-collection

**How to use**

- Add an “action” to your flow and search for “Get Collection as SObject”-
- Select the object type


**FieldApiINames**

Comma separated list of field API names.

eg.ID,Name,Primary_contact__c


**WhereClause**

A text value defining the where clause. You must not SOQL to add this. You should be able to add nested statements and do fun advance things here like normal apex.

eg.createddate = Last_N_Years:2

**sObjectName**

The name of the Object

eg. Account

**IdsList**

You load a number of Ids into this variable and then it will return all of these. This uses the Id IN :IdsList ability in Apex to find them all in one go.
Must be a text varilbe and allow multiple must be checked. 

**BypassSharing**

We used this for checking for duplicate records before inserting. Or if you want to move a contact to an account that the user doesn’t have access yet.

eg. {!$GlobalConstant.True}

**outputCollection**

The records being returned

Create a record variable -Allow multiple must be checked. 


# Better Documentation

https://docs.google.com/document/d/1rYS4Rv2zMr9Qj6d8aM-zGDZWgF_4n9ShJgaA3Nt3K8g/edit?usp=sharing


