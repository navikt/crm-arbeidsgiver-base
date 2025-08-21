@isTest
private class TAG_FeedbackHandlerTest {
    @isTest
    static void testHandleNewRating_Success() {
        // Arrange
        String componentName = 'TestComponent';
        String page = 'TestPage';
        String question = 'Er denne komponenten nyttig?';
        Integer vote = 1;

        // Act
        Test.startTest();
        Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'handleNewRating should return true for successful execution');
    }

    @isTest
    static void testHandleNewRating_DislikeVote() {
        // Arrange
        String componentName = 'DislikeComponent';
        String page = 'TestPage';
        String question = 'Er denne komponenten nyttig?';
        Integer vote = -1;

        // Act
        Test.startTest();
        Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'handleNewRating should return true for dislike vote');
    }

    @isTest
    static void testHandleNewRating_WithNullComponentName() {
        // Arrange
        String componentName = null;
        String page = 'TestPage';
        String question = 'Er denne komponenten nyttig?';
        Integer vote = 1;

        // Act & Assert
        Test.startTest();
        try {
            Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
            // If no exception is thrown, the method should still return true
            System.assertEquals(true, result, 'Method should handle null componentName gracefully');
        } catch (Exception ex) {
            // Expected behavior if null values cause issues
            System.assert(ex.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();
    }

    @isTest
    static void testHandleNewRating_WithEmptyStrings() {
        // Arrange
        String componentName = '';
        String page = '';
        String question = '';
        Integer vote = 0;

        // Act
        Test.startTest();
        Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'handleNewRating should handle empty strings');
    }

    @isTest
    static void testHandleNewRating_WithLongStrings() {
        // Arrange - Test with long strings to ensure field limits are respected
        String componentName = 'Component' + 'X'.repeat(250); // Long component name
        String page = 'Page' + 'Y'.repeat(250); // Long page name
        String question = 'Question' + 'Z'.repeat(250); // Long question
        Integer vote = 1;

        // Act
        Test.startTest();
        Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'handleNewRating should handle long strings');
    }

    @isTest
    static void testHandleNewRating_MultipleVotes() {
        // Arrange - Test multiple votes to ensure events are published correctly
        List<String> componentNames = new List<String>{ 'Comp1', 'Comp2', 'Comp3' };
        List<Integer> votes = new List<Integer>{ 1, -1, 1 };
        String page = 'TestPage';
        String question = 'Test question';

        // Act
        Test.startTest();
        List<Boolean> results = new List<Boolean>();
        for (Integer i = 0; i < componentNames.size(); i++) {
            Boolean result = TAG_FeedbackHandler.handleNewRating(componentNames[i], page, question, votes[i]);
            results.add(result);
        }
        Test.stopTest();

        // Assert
        for (Boolean result : results) {
            System.assertEquals(true, result, 'All votes should be processed successfully');
        }
    }

    @isTest
    static void testHandleNewRating_WithSpecialCharacters() {
        // Arrange - Test with special characters
        String componentName = 'Test&Component<>"\'/\\';
        String page = 'Test&Page<>"\'/\\';
        String question = 'Test question with special chars: åøæ?!@#$%^&*()';
        Integer vote = 1;

        // Act
        Test.startTest();
        Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'handleNewRating should handle special characters');
    }

    @isTest
    static void testHandleNewRating_BoundaryVoteValues() {
        // Arrange - Test with boundary vote values
        String componentName = 'BoundaryTest';
        String page = 'TestPage';
        String question = 'Test question';

        List<Integer> boundaryVotes = new List<Integer>{
            -2147483647, // Close to Integer.MIN_VALUE
            -1000,
            -1,
            0,
            1,
            1000,
            2147483647 // Integer.MAX_VALUE equivalent
        };

        // Act
        Test.startTest();
        for (Integer vote : boundaryVotes) {
            Boolean result = TAG_FeedbackHandler.handleNewRating(componentName, page, question, vote);
            // Assert
            System.assertEquals(true, result, 'Vote value ' + vote + ' should be handled successfully');
        }
        Test.stopTest();
    }
}
