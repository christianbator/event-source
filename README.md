# EventSource
A simple Swift event source for fun and profit

![Swift](https://img.shields.io/badge/Swift-4.0-orange.svg)
![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)

EventSource is based on the [EventSource Web API](https://developer.mozilla.org/en-US/docs/Web/API/EventSource) to enable [Server Sent Events](https://en.wikipedia.org/wiki/Server-sent_events).

If you're unfamiliar with this one-way streaming protocol - [Start Here](https://hpbn.co/server-sent-events-sse/).

Under the hood, EventSource is built on top of `NSURLSession` and has zero third-party dependencies.

Enjoy!
<br/>
<br/>

## Usage
An `Event` looks like this
```swift
struct Event {

  let readyState: EventSourceState // The EventSourceState at the time of the event's creation

  let id: String?
  let name: String?
  let data: String?
  let error: NSError?
}
```

You create an `EventSource` with an `NSURL`
```swift
import EventSource

let url = NSURL(string: "http://localhost:8000/stream")!
        
let eventSource = EventSource(url: url)
```

### Opening and closing the connection
```swift
eventSource.open()
eventSource.close()
```

### Adding standard event handlers
```swift
eventSource.onOpen { event in
  debugPrint(event)
}

eventSource.onMessage { event in
  debugPrint(event)
}

eventSource.onClose { event in
  debugPrint(event)
}

eventSource.onError { event in
  debugPrint(event)
}
```

### Adding named event handlers
```swift
eventSource.addHandler("tweet.create") { event in
  debugPrint(event.data)
}
```
<br/>

## Example
In the Example directory, you'll find the Server and EventSourceExample directories. The Server directory contains a simple python server that sends events to any connected clients, and the EventSourceExample directory contains a simple iOS app to display recent events from that server.

### Server Setup
The server uses [Redis](http://redis.io) to setup pub / sub channels, and it uses [Flask](http://flask.pocoo.org) deployed with [Gunicorn](http://gunicorn.org) to serve events to connected clients.

Install the following packages to run the simple python server
```
brew install redis
pip install flask redis gevent gunicorn
```

Start redis and deploy the server (in two separate terminal tabs)
```
redis-server
gunicorn --worker-class=gevent -b 0.0.0.0:8000 app:app
```

### Client Setup
Open the `EventSourceExample` Xcode project and run the app in the simulator <br/>
Tap the "Open" button in the app to open a connection to the server

### Sending Events
Now you can visit `http://localhost:8000/publish` in your browser to start sending events

<br/>

## Demo
If all goes well, you should get a nice stream of events in your simulator

![alt tag](/Example/Presentation/EventSourceExample.gif)

<br/>

## Heads Up

### API Decisions
EventSource deviates slightly from the Web API where it made sense for a better iOS API. For example, an `Event` has a `name` property so you can subscribe to specific, named events like `tweet.create`. This is in lieu of the Web API's `event` property of an `Event` (because who wants to write `let event = event.event`? Not me... 😞).

### Auto-Reconnect
An `EventSource` will automatically reconnect to the server if it enters an `Error` state, and based on the protocol, a server can send a `retry` event with an interval indicating how frequently the `EventSource` should retry the connection after encountering an error. Be warned: an `EventSource` expects this interval to be in **seconds** - not milliseconds as described by the Web API.

<br/>

## Installation

### Carthage

Add the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```
github "jcbator/EventSource"
```

Then run 
```
carthage update --platform iOS
```
