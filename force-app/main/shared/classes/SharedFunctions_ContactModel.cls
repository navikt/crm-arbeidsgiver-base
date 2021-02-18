public with sharing class SharedFunctions_ContactModel {
    public String firstName;
    public String lastName;
    public String phone;
    public String email;
    public String companyNumber;
    public String source;

    public SharedFunctions_ContactModel(
        String firstName,
        String lastName,
        String phone,
        String email,
        String companyNumber,
        String source
    ) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.phone = phone;
        this.email = email;
        this.companyNumber = companyNumber;
        this.source = source;
    }
    public SharedFunctions_ContactModel() {
    }
}
