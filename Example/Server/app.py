#
# app.py - Event Source Prototype
#

import datetime
import flask
import redis
import json
from pprint import pprint

app = flask.Flask(__name__)
app.secret_key = 'EventSource'
red = redis.StrictRedis()

@app.route('/publish')
def post():
    now = datetime.datetime.now().replace(microsecond=0).time()

    response = {'text' : 'Event', 'timestamp' : now.isoformat()}
    red.publish('events', json.dumps(response))
    
    return flask.Response(status=200, response=json.dumps(response))

@app.route('/stream')
def stream():
    return flask.Response(event_stream(), mimetype="text/event-stream")

def event_stream():
    pubsub = red.pubsub()
    pubsub.subscribe('events')
    for message in pubsub.listen():
        print "\nMessage:"
        pprint(message)
        print "\n"

        yield 'data: %s\n\n' % message['data']

if __name__ == '__main__':
    app.debug = True
    app.run(host='0.0.0.0')