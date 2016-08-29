//
//  ViewController.swift
//  EventSource
//
//  Created by Christian Bator on 8/2/16.
//  Copyright © 2016 FarmLogs. All rights reserved.
//

import UIKit
import EventSource

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var statusView: UIView!
    @IBOutlet var statusLabel: UILabel!
    
    private var eventSource: EventSource?
    private var events: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupEventSource()
        tableView.reloadData()
    }
    
    func setupEventSource() {
        guard let url = NSURL(string: "http://127.0.0.1:8000/stream") else {
            return
        }
        
        eventSource = EventSource(url: url)

        eventSource?.onOpen { event in
            self.updateStatusView(event)
        }
        
        eventSource?.onMessage { event in
            self.updateStatusView(event)
            self.handleMessage(event)
        }
        
        eventSource?.onClose { event in
            self.updateStatusView(event)
        }
        
        eventSource?.onError { event in
            self.updateStatusView(event)
        }
    }
    
    func updateStatusView(event: Event) {
        if let _ = event.error {
            statusLabel.text = "Error"
            statusView.backgroundColor = UIColor.orangeColor()
        }
        else {
            statusLabel.text = event.readyState.rawValue
            statusView.backgroundColor = event.readyState.color()
        }
    }
    
    func handleMessage(event: Event) {
        guard let message = event.data?.toDictionary(),
            let text = message["text"],
            let timestamp = message["timestamp"] else {
                return
        }
        
        self.events.insert("[\(timestamp)] \(text)", atIndex: 0)
        
        let nextIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([nextIndexPath], withRowAnimation: .Top)
        self.tableView.endUpdates()
    }
    
    @IBAction func openConnection() {
        eventSource?.open()
    }
    
    @IBAction func closeConnection() {
        eventSource?.close()
    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = events[indexPath.row]
        
        return cell
    }
    
}

extension String {
    
    func toDictionary() -> [String: AnyObject]? {
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String: AnyObject]
                return json
            }
            catch {
                debugPrint(error)
            }
        }
        
        return nil
    }
    
}

extension EventSourceState {
    
    func color() -> UIColor {
        switch self {
        case .Open:
            return UIColor.greenColor()
        case .Closed:
            return UIColor.redColor()
        }
    }
    
}
