@isTest
global class ArbeidsplassenController_MockGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        System.assert(
            req.getEndpoint().startsWith('https://arbeidsplassen.nav.no/public-feed/api/v1/ads')
        );
        System.assertEquals('GET', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(ArbeidsplassenRawModel_Test.json);
        res.setStatusCode(200);

        return res;
    }
}
