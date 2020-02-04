public with sharing class TAG_ActivityTimelineDataProviderHelper {
	public static List<Object> slice( List<Object> input, Integer start, Integer endAmount ) {
		List<Object> output = input.clone();
		for ( Integer i = 0; i < start; i++ ) output.remove( 0 );
		Integer elements = endAmount - start;
		while ( output.size() > elements ) output.remove( elements );

		return output;
	}

	// public static List<TAG_ActivityTimelineModel> sortByDate( TAG_ActivityTimelineModel wrapped ) {

	// 	Map<Integer, TAG_ActivityTimelineModel> modelMap = new Map<Integer, TAG_ActivityTimelineModelList>();
	// 	Map<Integer, DateTime> dateMap = new Map<Integer, DateTime>();
	// 	Map<Integer, TAG_ActivityTimelineModel> sortedModelMap = new Map<Integer, TAG_ActivityTimelineModelList>();


	// 	Integer i = 0;
	// 	for ( TAG_ActivityTimelineModel model : wrapped.models ) {
	// 		modelMap.put( i, model );
	// 		dateMap.put( i, model.record.dateValueDb );
	// 		i++;
	// 	}


	// }
}
