@RestResource(urlMapping = '/Course/*')
global with sharing class CourseHandler {
	@HttpGet
	global static void doGet() {
		List<Course__c> courses = [SELECT Id, Name, RegistrationUrl__c, RegistrationFromDateTime__c, RegistrationToDateTime__c, RegistrationDeadline__c, RegistrationPlaceName__c, DescriptionInternal__c, Description__c, FrontPageDescription__c, Active__c, Region__c, Type_of_course__c, Theme__c FROM Course__c];

		List<CourseWrapper> wrapperList = new List<CourseWrapper>();

		for ( Integer i = 0; i < courses.size(); i++ ) {
			CourseWrapper wrapper = new CourseWrapper();

			wrapper.RegistrationID = courses[i].Id;
			wrapper.Title = courses[i].Name;
			wrapper.RegistrationUrl = courses[i].RegistrationUrl__c;
			wrapper.RegistrationFromDateTime = courses[i].RegistrationFromDateTime__c;
			wrapper.RegistrationToDateTime = courses[i].RegistrationToDateTime__c;
			wrapper.RegistrationDeadline = courses[i].RegistrationDeadline__c;
			wrapper.DescriptionInternal = courses[i].DescriptionInternal__c;
			wrapper.Description = courses[i].Description__c;
			wrapper.FrontPageDescription = courses[i].FrontPageDescription__c;
			wrapper.ShowInActivityList = courses[i].Active__c ? 1 : 0;

			wrapper.configurable_custom = new CourseWrapper.Configurable_custom();

			wrapper.configurable_custom.Fylke = courses[i].Region__c;
			wrapper.configurable_custom.Type = courses[i].Type_of_course__c;
			wrapper.configurable_custom.Tema = courses[i].Theme__c;


			wrapperList.add( wrapper );
		}

		//String result = System.JSON.serialize( wrapperList, true );

		RestContext.response.addHeader( 'Content-Type', 'application/json' );
		RestContext.response.responseBody = Blob.valueOf( JSON.serialize( wrapperList ) );

	}


}
