//
//  EventSourceTests.swift
//  EventSourceTests
//
//  Created by Christian Bator on 8/29/16.
//  Copyright © 2016 jcbator. All rights reserved.
//

import XCTest
@testable import EventSource

class EventSourceTests: XCTestCase {
    
    // TODO: - Tests :)
    
    var eventSource = EventSource(url: URL(string: "http://localhost:8000/stream")!)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test() {
        
    }
    
}
