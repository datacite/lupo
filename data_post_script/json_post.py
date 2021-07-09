import requests

class JSON_post:
    def __init__(self, server_port, json_object, bearer_auth_key):
        self.server_port = server_port
        self.json_object = json_object
        self.bearer_auth_key = bearer_auth_key

    def post(self):
        headers = {"Authorization": "Bearer " + self.bearer_auth_key}
        try:
            r = requests.post(self.server_port, json=self.json_object, headers=headers)
            return True
        except Exception as e:
            print("POSTed failed: {}".format(e))
            return False

def post_example(server_port, json_object):
    JSON_poster = JSON_post(server_port, json_object)
    print(JSON_poster.post())