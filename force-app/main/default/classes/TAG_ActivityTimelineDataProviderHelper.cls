public with sharing class TAG_ActivityTimelineDataProviderHelper {
	public static List<Object> slice( List<Object> input, Integer start, Integer endAmount ) {
		List<Object> output = input.clone();
		for ( Integer i = 0; i < start; i++ ) output.remove( 0 );
		Integer elements = endAmount - start;
		while ( output.size() > elements ) output.remove( elements );

		return output;
	}
}
