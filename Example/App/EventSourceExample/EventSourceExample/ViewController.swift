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
    
    fileprivate var eventSource: EventSource?
    fileprivate var events: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupEventSource()
        tableView.reloadData()
    }
    
    func setupEventSource() {
        let url = URL(string: "http://localhost:8000/stream")!
        
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
    
    func updateStatusView(_ event: Event) {
        statusLabel.text = event.readyState.rawValue.capitalized
        statusView.backgroundColor = event.readyState.color()
    }
    
    func handleMessage(_ event: Event) {
        guard let message = event.data?.toDictionary(),
            let text = message["text"],
            let timestamp = message["timestamp"] else {
                return
        }
        
        self.events.insert("[\(timestamp)] \(text)", at: 0)
        
        let nextIndexPath = IndexPath(row: 0, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [nextIndexPath], with: .top)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = events[(indexPath as NSIndexPath).row]
        
        return cell
    }
    
}

extension String {
    
    func toDictionary() -> [String: AnyObject]? {
        if let data = self.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
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
            return UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1)
        case .Closed:
            return UIColor.red
        case .Error:
            return UIColor.orange
        default:
            return UIColor.clear
        }
    }
    
}
