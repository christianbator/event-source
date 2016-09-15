//
//  EventSource.swift
//  EventSource
//
//  Created by Christian Bator on 8/2/16.
//  Copyright © 2016 FarmLogs. All rights reserved.
//

import Foundation

public let EventIDKey = "id"
public let EventNameKey = "event"
public let EventDataKey = "data"
public let EventRetryKey = "retry"

private let KeyValueDelimiter = ": "
private let EventKeyValuePairSeparator = "\n"

private let EventSeparatorLFLF = "\n\n"
private let EventSeparatorCRCR = "\r\r"
private let EventSeparatorCRLFCRLF = "\r\n\r\n"

public enum EventSourceState: String {
    case Default = "default"
    case Connecting = "connecting"
    case Open = "open"
    case Closed = "closed"
    case Error = "error"
}

open class EventSource: NSObject {
    
    open let url: URL
    open fileprivate(set) var state: EventSourceState = .Default
    
    fileprivate var currentTask: URLSessionDataTask?
    fileprivate var session: Foundation.URLSession?
    
    fileprivate var openHandler: EventHandler?
    fileprivate var messageHandler: EventHandler?
    fileprivate var closeHandler: EventHandler?
    fileprivate var errorHandler: EventHandler?
    
    fileprivate var handlers: [String : [EventHandler]] = [:]
    
    fileprivate var timeoutInterval: TimeInterval = DBL_MAX
    fileprivate var retryInterval: TimeInterval = 3
    fileprivate var retryTimer: Timer?
    
    fileprivate var lastEventID: String?
    
    public init(url: URL) {
        self.url = url
        super.init()
    }
    
    open func open() {
        guard state != .Connecting && state != .Open else {
            return
        }
        
        state = .Connecting
        
        currentTask?.cancel()
        session?.invalidateAndCancel()
        
        let configuration = URLSessionConfiguration.default
        session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
        
        if let lastEventID = self.lastEventID {
            request.setValue(lastEventID, forHTTPHeaderField: "Last-Event-ID")
        }
        
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        currentTask = session?.dataTask(with: request)
        currentTask?.resume()
    }
    
    open func close() {
        guard state != .Closed else {
            return
        }
        
        state = .Closed
        
        retryTimer?.invalidate()
        
        currentTask?.cancel()
        session?.invalidateAndCancel()
        
        let event = Event(readyState: state, data: "\(Date().timeIntervalSince1970)")
        
        DispatchQueue.main.async {
            self.closeHandler?(event)
        }
    }
    
    open func addHandler(_ eventName: String, handler: @escaping EventHandler) {
        if handlers[eventName] == nil {
            handlers[eventName] = []
        }
        
        handlers[eventName]?.append(handler)
    }
    
    open func onOpen(_ handler: @escaping EventHandler) {
        openHandler = handler
    }
    
    open func onMessage(_ handler: @escaping EventHandler) {
        messageHandler = handler
    }
    
    open func onClose(_ handler: @escaping EventHandler) {
        closeHandler = handler
    }
    
    open func onError(_ handler: @escaping EventHandler) {
        errorHandler = handler
    }
    
}


extension EventSource: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if state != .Open {
            handleOpen()
        }
        else {
            handleData(data)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        handleError(error as NSError?)
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        handleError(error as NSError?)
    }
    
}


extension EventSource {
    
    fileprivate func handleOpen() {
        state = .Open
        
        retryTimer?.invalidate()
        
        let event = Event(readyState: state, data: "\(Date().timeIntervalSince1970)")
        
        DispatchQueue.main.async {
            self.openHandler?(event)
        }
    }
    
    fileprivate func handleData(_ data: Data) {
        guard let eventString = String(data: data, encoding: String.Encoding.utf8) else {
            return
        }
        
        guard eventString.hasSuffix(EventSeparatorLFLF) ||
            eventString.hasSuffix(EventSeparatorCRCR) ||
            eventString.hasSuffix(EventSeparatorCRLFCRLF) else {
                return
        }
        
        var ID: String?
        var name: String?
        var data: String?
        
        let trimmedEventString = eventString.trimmingCharacters(in: CharacterSet.newlines)
        let components = trimmedEventString.components(separatedBy: EventKeyValuePairSeparator) as [NSString]
        
        for component in components {
            guard component.length > 0 else {
                continue
            }
            
            let delimiterIndex = component.range(of: KeyValueDelimiter).location
            if delimiterIndex == NSNotFound || delimiterIndex == (component.length - KeyValueDelimiter.characters.count) {
                continue
            }
            
            let key = component.substring(to: delimiterIndex)
            let value = component.substring(from: delimiterIndex + KeyValueDelimiter.characters.count)
            
            if key == EventIDKey {
                ID = value
            }
            else if key == EventNameKey {
                name = value
            }
            else if key == EventDataKey {
                data = value
            }
            else if key == EventRetryKey {
                if let timeIntervalValue = TimeInterval(value) {
                    self.retryInterval = timeIntervalValue
                }
            }
        }
        
        lastEventID = ID
        
        let event = Event(readyState: state, id: ID, name: name, data: data)
        
        DispatchQueue.main.async {
            self.messageHandler?(event)
        }
        
        if let eventName = event.name,
            let namedEventhandlers = handlers[eventName] {
            
            for handler in namedEventhandlers {
                DispatchQueue.main.async {
                    handler(event)
                }
            }
        }
    }
    
    fileprivate func handleError(_ sessionError: NSError?) {
        guard state != .Closed else {
            return
        }
        
        state = .Error
        
        let error = sessionError != nil ? sessionError : NSError(domain: "com.jcbator.eventsource", code: -1, userInfo: ["message" : "Unknown Error"])
        let event = Event(readyState: state, data: "\(Date().timeIntervalSince1970)", error: error)
        
        DispatchQueue.main.async {
            self.errorHandler?(event)
            
            if self.retryTimer == nil || !self.retryTimer!.isValid {
                self.retryTimer = Timer.scheduledTimer(timeInterval: self.retryInterval, target: self, selector: #selector(EventSource.open), userInfo: nil, repeats: true)
            }
        }
    }
    
}
