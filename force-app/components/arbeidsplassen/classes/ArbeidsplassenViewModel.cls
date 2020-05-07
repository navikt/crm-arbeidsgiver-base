
/**
 * The model that will be used to present available positions in the LWC
 */

public with sharing class ArbeidsplassenViewModel {

	@AuraEnabled public Date applicationDue {get; set;}
	@AuraEnabled public String city {get; set;}
	@AuraEnabled public String engagementtype {get; set;}
	@AuraEnabled public String extent {get; set;}
	@AuraEnabled public String link {get; set;}
	@AuraEnabled public Datetime published {get; set;}
	@AuraEnabled public String title {get; set;}

	public ArbeidsplassenViewModel( ArbeidsplassenRawModel.Content content ) {

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
