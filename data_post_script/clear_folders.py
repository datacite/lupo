import os
import json

# load folders to be cleared
CONFIG_FILE = './xml_post_parser_config.json'
with open(CONFIG_FILE, "rb") as config_f:
    config = json.load(config_f)

clear_folders = [config["json_folder"], config["processed_xml_folder"], config["posted_json_folder"], config["post_failed_folder"]]

for folder in clear_folders:
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
        except Exception as e:
            print("Failed to delete %s. Reason: %s" % (file_path, e))
