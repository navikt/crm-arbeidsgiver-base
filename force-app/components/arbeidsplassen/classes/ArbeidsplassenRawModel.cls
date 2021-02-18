/**
 * The model that will be used to deserialize the json returned from the API
 */

public class ArbeidsplassenRawModel {
    public class OccupationCategories {
        public String level1 { get; set; }
        public String level2 { get; set; }

        public OccupationCategories(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'level1') {
                            level1 = parser.getText();
                        } else if (text == 'level2') {
                            level2 = parser.getText();
                        } else {
                            System.debug(
                                LoggingLevel.WARN,
                                'OccupationCategories consuming unrecognized property: ' + text
                            );
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }

    public class WorkLocations {
        public String address { get; set; }
        public String city { get; set; }
        public String country { get; set; }
        public String county { get; set; }
        public String municipal { get; set; }
        public String postalCode { get; set; }

        public WorkLocations(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'address') {
                            address = parser.getText();
                        } else if (text == 'city') {
                            city = parser.getText();
                        } else if (text == 'country') {
                            country = parser.getText();
                        } else if (text == 'county') {
                            county = parser.getText();
                        } else if (text == 'municipal') {
                            municipal = parser.getText();
                        } else if (text == 'postalCode') {
                            postalCode = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'WorkLocations consuming unrecognized property: ' + text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }

    public class Employer {
        public String description { get; set; }
        public String homepage { get; set; }
        public String name { get; set; }
        public String orgnr { get; set; }

        public Employer(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'description') {
                            description = parser.getText();
                        } else if (text == 'homepage') {
                            homepage = parser.getText();
                        } else if (text == 'name') {
                            name = parser.getText();
                        } else if (text == 'orgnr') {
                            orgnr = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Employer consuming unrecognized property: ' + text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }

    public class Content {
        public String applicationDue { get; set; }
        public String description { get; set; }
        public Employer employer { get; set; }
        public String engagementtype { get; set; }
        public String expires { get; set; }
        public String extent { get; set; }
        public String jobtitle { get; set; }
        public String link { get; set; }
        public List<OccupationCategories> occupationCategories { get; set; }
        public String positioncount { get; set; }
        public String published { get; set; }
        public String sector { get; set; }
        public String source { get; set; }
        public String sourceurl { get; set; }
        public String starttime { get; set; }
        public String title { get; set; }
        public String updated { get; set; }
        public String uuid { get; set; }
        public List<WorkLocations> workLocations { get; set; }

        public Content(JSONParser parser) {
            while (parser.nextToken() != System.JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'applicationDue') {
                            applicationDue = parser.getText();
                        } else if (text == 'description') {
                            description = parser.getText();
                        } else if (text == 'employer') {
                            employer = new Employer(parser);
                        } else if (text == 'engagementtype') {
                            engagementtype = parser.getText();
                        } else if (text == 'expires') {
                            expires = parser.getText();
                        } else if (text == 'extent') {
                            extent = parser.getText();
                        } else if (text == 'jobtitle') {
                            jobtitle = parser.getText();
                        } else if (text == 'link') {
                            link = parser.getText();
                        } else if (text == 'occupationCategories') {
                            occupationCategories = arrayOfOccupationCategories(parser);
                        } else if (text == 'positioncount') {
                            positioncount = parser.getText();
                        } else if (text == 'published') {
                            published = parser.getText();
                        } else if (text == 'sector') {
                            sector = parser.getText();
                        } else if (text == 'source') {
                            source = parser.getText();
                        } else if (text == 'sourceurl') {
                            sourceurl = parser.getText();
                        } else if (text == 'starttime') {
                            starttime = parser.getText();
                        } else if (text == 'title') {
                            title = parser.getText();
                        } else if (text == 'updated') {
                            updated = parser.getText();
                        } else if (text == 'uuid') {
                            uuid = parser.getText();
                        } else if (text == 'workLocations') {
                            workLocations = arrayOfWorkLocations(parser);
                        } else {
                            System.debug(LoggingLevel.WARN, 'Content consuming unrecognized property: ' + text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }

    public List<Content> content { get; set; }
    public Boolean first { get; set; }
    public Boolean last { get; set; }
    public Integer pageNumber { get; set; }
    public Integer pageSize { get; set; }
    public String sort_Z { get; set; } // in json: sort
    public Integer totalElements { get; set; }
    public Integer totalPages { get; set; }

    public ArbeidsplassenRawModel(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'content') {
                        content = arrayOfContent(parser);
                    } else if (text == 'first') {
                        first = parser.getBooleanValue();
                    } else if (text == 'last') {
                        last = parser.getBooleanValue();
                    } else if (text == 'pageNumber') {
                        pageNumber = parser.getIntegerValue();
                    } else if (text == 'pageSize') {
                        pageSize = parser.getIntegerValue();
                    } else if (text == 'sort') {
                        sort_Z = parser.getText();
                    } else if (text == 'totalElements') {
                        totalElements = parser.getIntegerValue();
                    } else if (text == 'totalPages') {
                        totalPages = parser.getIntegerValue();
                    } else {
                        System.debug(
                            LoggingLevel.WARN,
                            'ArbeidsplassenRawModel consuming unrecognized property: ' + text
                        );
                        consumeObject(parser);
                    }
                }
            }
        }
    }

    public static ArbeidsplassenRawModel parse(String json) {
        System.JSONParser parser = System.JSON.createParser(json);

        return new ArbeidsplassenRawModel(parser);
    }

    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || curr == System.JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == System.JSONToken.END_OBJECT || curr == System.JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }

    private static List<OccupationCategories> arrayOfOccupationCategories(System.JSONParser p) {
        List<OccupationCategories> res = new List<OccupationCategories>();
        if (p.getCurrentToken() == null)
            p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new OccupationCategories(p));
        }

        return res;
    }

    private static List<WorkLocations> arrayOfWorkLocations(System.JSONParser p) {
        List<WorkLocations> res = new List<WorkLocations>();
        if (p.getCurrentToken() == null)
            p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new WorkLocations(p));
        }

        return res;
    }

    private static List<Content> arrayOfContent(System.JSONParser p) {
        List<Content> res = new List<Content>();
        if (p.getCurrentToken() == null)
            p.nextToken();
        while (p.nextToken() != System.JSONToken.END_ARRAY) {
            res.add(new Content(p));
        }

        return res;
    }
}
