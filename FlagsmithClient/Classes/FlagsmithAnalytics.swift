//
//  FlagsmithAnalytics.swift
//  FlagsmithClient
//
//  Created by Daniel Wichett on 05/10/2021.
//

import Foundation

class FlagsmithAnalytics {
    
    let EVENTS_KEY = "events"
    unowned let apiManager: APIManager
    var events:[String:Int] = [:]
    var timer:Timer?
    var enableAnalytics: Bool = true
    
    init(apiManager: APIManager) {
        self.apiManager = apiManager
        events = UserDefaults.standard.dictionary(forKey: EVENTS_KEY) as? [String:Int] ?? [:]
        setupTimer()
    }
    
    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(Flagsmith.shared.analyticsFlushPeriod), target: self, selector: #selector(postAnalytics(_:)), userInfo: nil, repeats: true)
    }
    
    func trackEvent(flagName:String) {
        let current = events[flagName] ?? 0
        events[flagName] = current + 1
        saveEvents()
    }
    
    func reset() {
        events = [:]
        saveEvents()
    }
    
    func saveEvents() {
        UserDefaults.standard.set(events, forKey: EVENTS_KEY)
    }
    
    /// Send analytics to the api when enabled.
    @objc func postAnalytics(_ timer: Timer) {
        guard enableAnalytics else {
            return
        }
        
        guard !events.isEmpty else {
            return
        }
        
        apiManager.request(.postAnalytics(events: events), emptyResponse: true) { [weak self] (result: Result<String, Error>) in
            switch result {
            case .failure:
                print("Upload analytics failed")
            case .success:
                self?.reset()
            }
        }
    }
}
