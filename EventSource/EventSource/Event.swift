//
//  Event.swift
//  EventSource
//
//  Created by Christian Bator on 8/5/16.
//  Copyright © 2016 FarmLogs. All rights reserved.
//

import Foundation

let EventIDKey = "id"
let EventNameKey = "event"
let EventDataKey = "data"
let EventRetryKey = "retry"

let KeyValueDelimiter = ": "
let EventKeyValuePairSeparator = "\n"

let EventSeparatorLFLF = "\n\n"
let EventSeparatorCRCR = "\r\r"
let EventSeparatorCRLFCRLF = "\r\n\r\n"

public struct Event {
    public let ID: String?
    public let name: String?
    public let data: String?
    public let error: NSError?
    public let readyState: EventSourceState
    
    init(readyState: EventSourceState, ID: String? = nil, name: String? = nil, data: String? = nil, error: NSError? = nil) {
        self.ID = ID
        self.name = name
        self.data = data
        self.error = error
        self.readyState = readyState
    }
}

public typealias EventHandler = (Event) -> Void