//
//  NotificationsManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import UserNotifications

final class NotificationsManager {
    static let shared = NotificationsManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard let self else { return }
            if granted {
                scheduleWeeklyNotificationIfNeeded()
            }
        }
    }
    
    private func scheduleWeeklyNotificationIfNeeded() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            if !requests.contains(where: { $0.identifier == AppConstants.Notifications.weeklyNotificationIdentifier }) {
                scheduleWeeklyNotification()
            }
            
            notificationCenter.getPendingNotificationRequests { notifications in
                notifications.forEach { dump($0) }
            }
        }
    }
    
    private func scheduleWeeklyNotification() {
        notificationCenter.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        let randomIndex = Int.random(in: 0..<AppConstants.Notifications.notificationTitles.count)
        content.title = AppConstants.Notifications.notificationTitles[randomIndex]
        content.body = AppConstants.Notifications.notificationMessages[randomIndex]
        content.sound = UNNotificationSound.default
        
        let randomHour = Int.random(in: 18...23)
        let randomMinute = Int.random(in: 0...59)
        let randomDay = Int.random(in: 1...7)
        
        var dateComponents = DateComponents()
        dateComponents.weekday = randomDay
        dateComponents.hour = randomHour
        dateComponents.minute = randomMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: AppConstants.Notifications.weeklyNotificationIdentifier, content: content, trigger: trigger)

        notificationCenter.add(request)
    }
}

