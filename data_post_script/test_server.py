from flask import Flask, request, jsonify, redirect
from collections import defaultdict
app = Flask(__name__)

data = defaultdict(list)

@app.route('/data', methods=['GET'])
def add_message_get():
    return data

@app.route('/', methods=['POST'])
def add_message_post():
    jsonData = request.get_json()
    print(jsonData)
    data['POSTed_data'].append(jsonData)
    return jsonify(success=True,data=jsonData)

if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1')