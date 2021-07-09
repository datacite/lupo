import xml_encode
import json_post
from os import listdir
from os.path import isfile, join
import os
import json

# CONFIG data to be parsed
CONFIG_FILE = './xml_post_parser_config.json'
with open(CONFIG_FILE, "rb") as config_f:
    config = json.load(config_f)

server_port = config["server_port"]
bearer_auth_key = config["bearer_auth_key"]
prefix = config['prefix']
schema_url = config['schema_url']

xml_folder = config['xml_folder']
json_folder = config['json_folder']
processed_xml_folder = config['processed_xml_folder']
posted_json_folder = config['posted_json_folder']
post_failed_folder = config['post_failed_folder']


if not os.path.exists(xml_folder):
    raise Exception("SourceDirectory Not Found: {} not exists in the path".format(xml_folder))

if not os.path.exists(json_folder):
    os.makedirs(json_folder)
    
if not os.path.exists(processed_xml_folder):
    os.makedirs(processed_xml_folder)

if not os.path.exists(posted_json_folder):
    os.makedirs(posted_json_folder)

if not os.path.exists(post_failed_folder):
    os.makedirs(post_failed_folder)


# parse xml files and convert them into base64 string in json
files_input = [f for f in listdir(xml_folder) if isfile(join(xml_folder, f))]
for i in files_input:
    input_xml = join(xml_folder, i)
    processed = join(processed_xml_folder, i)
    output_json = join(json_folder, i) + '.json'

    # encode files and stored the converted jsons in json_folder
    XML_encoder = xml_encode.XML_encode(input_xml, output_json, prefix, schema_url)
    XML_encoder.encode()
    XML_encoder.write_json()
    os.rename(input_xml, processed)

# post new created json files to the given server port
files_input = [f for f in listdir(json_folder) if isfile(join(json_folder, f))]
for i in files_input:
    json_file = join(json_folder, i)
    posted_file = join(posted_json_folder, i)
    failed_file = join(post_failed_folder, i)

    with open(json_file, "rb") as json_f:
        json_object = json.load(json_f)

    # post json file to the server_port
    JSON_poster = json_post.JSON_post(server_port, json_object, bearer_auth_key)
    if JSON_poster.post() == True:
        print("POSTED {} to {}".format(json_file, server_port))
        os.rename(json_file, posted_file)
    else:
        os.rename(json_file, failed_file)
