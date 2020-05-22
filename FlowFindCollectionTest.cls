@isTest
public with sharing class FlowFindCollectionTest {
    
        @isTest
        public static void   FlowFindCollectionTest() { 
            //create sample  data
            Account A = new Account(
               Name = 'test Account12345'
            );
            insert A;
    
            
            FlowFindCollection.Requests request = new FlowFindCollection.Requests();
            request.sObjectName 	= 'Account';
            request.FieldApiINames 	= 'Name';
            request.WhereClause		= 'Name = \'test Account12345\'';
            
            system.debug(request);
            
            List<FlowFindCollection.Requests> requests = new List<FlowFindCollection.Requests>{ request };
    
            Test.startTest();

            list<FlowFindCollection.Results> responses = FlowFindCollection.execute( requests );
    
            Test.stopTest();

            system.assertEquals(1, responses[0].outputCollection.size());

             //Todo - assertions around sharing access. Can NOT view
        }

        @isTest
        public static void   FlowFindCollectionTest_WithoutSharing() { 
            //create sample  data
            Account A = new Account(
               Name = 'test Account12345'
            );
            insert A;
    
            
            FlowFindCollection.Requests request = new FlowFindCollection.Requests();
            request.sObjectName 	= 'Account';
            request.FieldApiINames 	= 'Name';
            request.WhereClause		= 'Name = \'test Account12345\'';
            request.BypassSharing		=true;
                     List<FlowFindCollection.Requests> requests = new List<FlowFindCollection.Requests>{ request };
    
                    
            //No sharing
            
            List<FlowFindCollection.Requests> requests2 = new List<FlowFindCollection.Requests>{ request };
            Test.startTest();
            list<FlowFindCollection.Results> responses_withoutsharing = FlowFindCollection.execute( requests2 );
            Test.stopTest();


            //Todo - assertions around sharing access. Can still view
        }


        //Test IDS



        @IsTest
        static void testSearch() {
            List<Account> accounts = new List<Account>{
                new Account(Name='United 1'),
                new Account(Name='United 2'),
                new Account(Name='United 3', Type='Test')
            };
            insert accounts;
            FlowFindCollection.Requests request = new FlowFindCollection.Requests();
            request.sObjectName = 'Account';
            request.queries = 'United';
            request.scope = 'ALL FIELDS';
            request.whereClause = 'Type = \'Test\'';
            request.FieldApiINames = '*';
            request.SearchExtraObjects = 'Lead,Account';
            Test.setFixedSearchResults(new Id[]{accounts[2].Id});
            Test.startTest();
            List<FlowFindCollection.Results> results = FlowFindCollection.execute(
                new List<FlowFindCollection.Requests>{ request }
            );
            Test.stopTest();
            System.assertEquals(3, [SELECT COUNT() FROM Account], 'Expected to have 3 accounts');
            System.assertEquals(1, results.size(), 'Expected only 1 result collection returned');
        }

        
        @IsTest
        static void testSearch_withousharing() {
            List<Account> accounts = new List<Account>{
                new Account(Name='United 1'),
                new Account(Name='United 2'),
                new Account(Name='United 3', Type='Test')
            };
            insert accounts;
            FlowFindCollection.Requests request = new FlowFindCollection.Requests();
            request.sObjectName = 'Account';
            request.queries = 'United';
            request.scope = 'ALL FIELDS';
            request.whereClause = 'Type = \'Test\'';
            request.BypassSharing		=true;
            request.FieldApiINames = 'Name';
            Test.setFixedSearchResults(new Id[]{accounts[2].Id});
            Test.startTest();
            List<FlowFindCollection.Results> results = FlowFindCollection.execute(
                new List<FlowFindCollection.Requests>{ request }
            );
            Test.stopTest();
            System.assertEquals(3, [SELECT COUNT() FROM Account], 'Expected to have 3 accounts');
            System.assertEquals(1, results.size(), 'Expected only 1 result collection returned');
        }
}