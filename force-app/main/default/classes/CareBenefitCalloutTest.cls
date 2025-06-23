@isTest
public class CareBenefitCalloutTest {

    // Mock HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":"Acknowledged","statusReason":"Care Benefit Verification Request successfully sent to Benefits Verification Provider."}');
            return res;
        }
    }

    @isTest
    static void testCareBenefitCallout_success() {
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        System.debug(personAccountRecordTypeId);
        // Create Requester Account
        Account requester = new Account(RecordTypeId = personAccountRecordTypeId,FirstName='John', LastName='Doe', 
                                        PersonBirthdate = Date.newInstance(1990, 1, 1), PersonGenderIdentity = 'Male' );
        insert requester;

        // Create Provider Account
        Account provider = new Account(FirstName='Dr. Walter', LastName='Smith', National_Provider_Identifier_NPI__c = 'NPI001');
        insert provider;


        MemberPlan memberPlan = new MemberPlan(Name = 'Aetna', MemberNumber = '12345', GroupNumber = '67890', Subscriber_ID__c = 'SID001', MemberId = requester.Id);
        insert memberPlan;

        // Create CareBenefitVerifyRequest
        SObject cbv = Schema.getGlobalDescribe().get('CareBenefitVerifyRequest').newSObject();
        cbv.put('RequesterId', requester.Id);
        cbv.put('ProviderId', provider.Id);
        cbv.put('MemberPlanId', memberPlan.Id);
        insert cbv;

        // Create Service Detail record
        SObject service = Schema.getGlobalDescribe().get('Service_Detail__c').newSObject();
        service.put('Service_Date__c', Date.today());
        service.put('Service_Type__c', 'Consultation');
        service.put('Diagnosis_Code__c', 'ICD-10');
        service.put('Procedure_Code__c', 'OPT');

        // Link to parent using correct relationship name (guessing here)
        service.put('Care_Benefit_Verify_Request__c', cbv.Id);
        insert service;

        // Set callout mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new CareBenefitCallout(new List<CareBenefitVerifyRequest>{(CareBenefitVerifyRequest) cbv}));
        Test.stopTest();

        // Verify that status is updated (assumes you have read access)
        CareBenefitVerifyRequest updated = [SELECT Id ,Status, StatusReason FROM CareBenefitVerifyRequest WHERE Id = :cbv.Id];
        System.assertEquals('Completed', updated.Status);
        System.assertEquals('Care Benefit Verification Request successfully sent to Benefits Verification Provider.', updated.StatusReason);
    }
}