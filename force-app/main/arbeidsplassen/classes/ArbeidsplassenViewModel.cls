
/**
 * The model that will be used to present available positions in the LWC
 */

public with sharing class ArbeidsplassenViewModel {

	public Date applicationDue {get; set;}
	public String city {get; set;}
	public String engagementtype {get; set;}
	public String extent {get; set;}
	public String link {get; set;}
	public Datetime published {get; set;}
	public String title {get; set;}

	public ArbeidsplassenViewModel( ArbeidsplassenModel.Content content ) {

		applicationDue = stringToDate( content.applicationDue );
		city = uppercaseFirstLetter( content.workLocations[0].city );
		engagementtype = content.engagementtype;
		extent = content.extent;
		link = content.link;
		published = stringToDatetime( content.published );
		title = content.title;
	}

	private static Date stringToDate( String dateString ) {
		try {
			return Date.valueOf( dateString.replace( 'T', ' ' ) );
		} catch ( Exception e ) {
			return null;
		}
	}

	private static Datetime stringToDatetime( String datetimeString ) {

		try {
			return Datetime.valueOf( datetimeString.replace( 'T', ' ' ).split( '\\.' )[0] );
		} catch ( Exception e ) {
			return null;
		}
	}

	public String uppercaseFirstLetter ( String name ) {

		String result = '';

		if ( name != null && name != '' ) {
			name = name.toLowerCase();
			for ( String iter : name.split( '[ ]+' ) ) {
				if ( iter != null && iter != '' ) {
					if ( iter.length() > 1 ) {
						result += iter.substring( 0, 1 ).toUpperCase() + iter.substring( 1, iter.length() ) + ' ';
					} else {
						result += iter.substring( 0, 1 ).toUpperCase() + ' ';
					}
				}
			}
			result = result.substring( 0, result.length() - 1 );
		}

		return result;
	}
}
