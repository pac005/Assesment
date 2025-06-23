//queable method for async and higher limits
public with sharing class CareBenefitCallout implements Queueable, Database.AllowsCallouts {

    private Integer maxRetries = 3;
    private List<CareBenefitVerifyRequest> cbvRecordIds;

    public CareBenefitCallout(List<CareBenefitVerifyRequest> cbvRecordIds) {
        this.cbvRecordIds = cbvRecordIds;
    }

    public void execute(QueueableContext context) 
    {
        //Get care beneft verify records in bulk for processing and an inner query for service details
        List<CareBenefitVerifyRequest> records = [
            SELECT Id, Requester.FirstName, Requester.LastName,Birthdate__c,Gender__c , MemberPlan.Name, MemberPlan.MemberNumber, 
            MemberPlan.GroupNumber, MemberPlan.Subscriber_ID__c, 
            Provider.FirstName, Provider.LastName, National_Provider_Identifier__c, 
            (Select Id, Service_Date__c, Name, Service_Type__c, Procedure_Code__c, Diagnosis_Code__c from Service_Details__r LIMIT 1) 
            FROM CareBenefitVerifyRequest where Id IN :cbvRecordIds
        ];

        system.debug(records);


         List<CareBenefitVerifyWrapper.RequestWrapper> payload = new List<CareBenefitVerifyWrapper.RequestWrapper>();

         //loop to build payload
        for (CareBenefitVerifyRequest rec : records) {
            //Request wrapper class to build payload
            CareBenefitVerifyWrapper.RequestWrapper req = new CareBenefitVerifyWrapper.RequestWrapper();

            req.patientFirstName = rec.Requester.FirstName;
            req.patientLastName = rec.Requester.LastName;
            req.patientDOB = rec.Birthdate__c;
            req.patientGender = rec.Gender__c;

            req.insuranceProviderName = rec.MemberPlan.Name;
            req.policyNumber = rec.MemberPlan.MemberNumber;
            req.groupNumber = rec.MemberPlan.GroupNumber;
            req.subscriberId = rec.MemberPlan.Subscriber_ID__c;

            req.providerNPI = rec.National_Provider_Identifier__c;
            req.providerFirstName = rec.Provider.FirstName;
            req.providerLastName = rec.Provider.LastName;
            
            //System.debug(req.Service_Detail__c);

            Service_Detail__c detail = rec.Service_Details__r[0];
            req.serviceType = detail.Service_Type__c;
            req.serviceDate = detail.Service_Date__c;
            req.diagnosisCode = detail.Procedure_Code__c;
            req.procedureCode = detail.Diagnosis_Code__c;

            system.debug(req);

            payload.add(req);
        }
        //send reqyest method
        sendRequest(JSON.serialize(payload));
    }

    private void sendRequest(String jsonPayload) {
        
        Integer attempt = 0;
        Boolean success = false;
        
        List<CareBenefitVerifyRequest> records = [
            SELECT Id, Requester.FirstName, Requester.LastName,Birthdate__c,Gender__c , MemberPlan.Name, MemberPlan.MemberNumber, 
            MemberPlan.GroupNumber, MemberPlan.Subscriber_ID__c, 
            Provider.Name, Provider.LastName, National_Provider_Identifier__c, 
            (Select Id, Service_Date__c, Name, Service_Type__c, Procedure_Code__c, Diagnosis_Code__c from Service_Details__r LIMIT 1) 
            FROM CareBenefitVerifyRequest where Id IN :cbvRecordIds
        ];

        //http request to send send payload with retry mechanism 
        while (attempt < maxRetries && !success) {
            attempt++;
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:ExternalBenefitVerification/benefit-verification-request');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(jsonPayload);

                Http http = new Http();
                HttpResponse res = http.send(req);

                //handle status code errors
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    success = true;
                    System.debug('Callout succeeded on attempt ' + attempt);
                    System.debug(JSON.deserializeUntyped(res.getBody()));
                    
                    String responseBody = res.getBody();

                    // Parse the JSON into a Map
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                    String status = (String) parsedResponse.get('status');
                    String statusReason = (String) parsedResponse.get('statusReason');

                    //update records
                    if(status == 'Acknowledged')
                    {
                        for (CareBenefitVerifyRequest rec : records) {
                            rec.Status = 'Acknowledged';
                            rec.StatusReason = statusReason;
                        }
                        update records;
                    }

                } else {
                    System.debug('Callout attempt ' + attempt + ' failed with status: ' + res.getStatusCode());
                }
            }
            //handle all exceptions
            catch(Exception e){
                 System.debug('Callout attempt ' + attempt + ' threw exception: ' + e.getMessage());
            }

        }
    
    }
}
