import base64
import json

class XML_encode:
    def __init__(self, input_xml, output_json, prefix, schema_url):
        self.input_xml = input_xml
        self.output_json = output_json
        self.prefix = prefix
        self.schema_url = schema_url
    
    def encode(self):
        # convert file content to base64 encoded string
        with open(self.input_xml, "rb") as xml_file:
            encoded = base64.b64encode(xml_file.read()).decode("utf-8")
            
        # append the required fields into json envelop
        ''' Format of the json envelop
        .
        `-- "data"
            |--"type"
            |--"relationships"
                |--"client"
                    |--"data"
                        |--"type"
                        |--"id"
            |--"attributes"
                |--"prefix"
                |--"url"
                |--"xml"
        '''
        json_envelop = {"data":{}}
        data = json_envelop["data"]
        data["type"] = "dois" 

        data["relationships"] = {}
        relationships = data["relationships"]
        relationships["client"] = {}
        relationships["client"]["data"] = {"type":"clients", "id": "datacite.test"}

        data["attributes"] = {}
        attributes = data["attributes"]
        attributes["prefix"] = self.prefix
        attributes["url"] = self.schema_url
        attributes["xml"] = encoded

        self.json_data = json.dumps(json_envelop, indent=2)


    def write_json(self):
        # write the json file
        with open(self.output_json, "w") as json_file:
            json_file.write(self.json_data)


def encode_example(input_xml, output_json):
    XML_encoder = XML_encode(input_xml, output_json)
    XML_encoder.extract_json_fields()
    XML_encoder.encode()
    XML_encoder.write_json()

