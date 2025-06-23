# Setup
1) Download all the files
2) Create a zip file
3) Open Salesforce Workbench
4) Connect it to a Salesforce Org
5) Migration > Deploy
6) Upload the zip folder that already contains the Package Manifest
7) Select Rollback on Error
8) Test Level: Run Specified Test: CareBenefitCalloutTest
   
# Assumptions
1) The Provider Account will already be associated with the patient account
2) Only one service detail per care benefit verify request. (As per the email communication between Dylan and me)
3) No fields are required. (As per the email communication between Dylan and me)
   
# Challenges
1) Figuring out the Data Model
