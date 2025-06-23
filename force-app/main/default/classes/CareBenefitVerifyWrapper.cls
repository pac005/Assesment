public class CareBenefitVerifyWrapper {
    //wrapper class
    public class RequestWrapper {
        public String patientFirstName;
        public String patientLastName;
        public Date patientDOB;
        public String patientGender;

        public String insuranceProviderName;
        public String policyNumber;
        public String groupNumber;
        public String subscriberId;

        public String providerNPI;
        public String providerFirstName;
        public String providerLastName;

        public String serviceType;
        public Date serviceDate;
        public String diagnosisCode;
        public String procedureCode;
    }
}
