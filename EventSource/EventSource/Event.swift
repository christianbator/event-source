//
//  Event.swift
//  EventSource
//
//  Created by Christian Bator on 8/5/16.
//  Copyright © 2017 Christian Bator. All rights reserved.
//

import Foundation

public struct Event {
    
    public let readyState: EventSourceState
    
    public let id: String?
    public let name: String?
    public let data: String?
    public let error: NSError?
    
    init(readyState: EventSourceState, id: String? = nil, name: String? = nil, data: String? = nil, error: NSError? = nil) {
        self.readyState = readyState
        
        self.id = id
        self.name = name
        self.data = data
        self.error = error
    }
}

public typealias EventHandler = (Event) -> Void
