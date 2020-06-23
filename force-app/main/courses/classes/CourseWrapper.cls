public class CourseWrapper {

	public Integer RegistrationID;
	public String Title;
	public String RegistrationUrl;
	//public Integer RegistrationImageMediaStorageID;
	//public Integer FrontImageMediaStorageID;
	//public Object CatalogListMediaStorageID;
	public Datetime RegistrationFromDateTime;
	public String RegistrationToDateTime;
	public String RegistrationDeadline;
	public String RegistrationPlaceName;
	public String DescriptionInternal;
	//public String CatalogText;
	public String Description;
	public String FrontPageDescription;
	public Integer ActiveWeb;
	public Integer ShowRegistrationForm;
	public Integer ShowInActivityList;
	public Configurable_custom configurable_custom;

	public class Configurable_custom {
		public String Fylke;
		public String kurs;
		public String Tema;
	}

}
