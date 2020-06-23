public class CourseWrapper {

	public Id RegistrationID;
	public String Title;
	public String RegistrationUrl;
	//public Integer RegistrationImageMediaStorageID;
	//public Integer FrontImageMediaStorageID;
	//public Object CatalogListMediaStorageID;
	public Datetime RegistrationFromDateTime;
	public Datetime RegistrationToDateTime;
	public Datetime RegistrationDeadline;
	public String RegistrationPlaceName;
	public String DescriptionInternal;
	//public String CatalogText;
	public String Description;
	public String FrontPageDescription;
	//public Integer ActiveWeb;
	//public Integer ShowRegistrationForm;
	public Integer ShowInActivityList;
	public Configurable_custom configurable_custom;

	public class Configurable_custom {
		public String Fylke;
		public String Type;
		public String Tema;
	}

}
