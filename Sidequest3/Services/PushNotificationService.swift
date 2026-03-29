//
//  PushNotificationService.swift
//  Sidequest
//

import Foundation
import UserNotifications
import UIKit

@Observable
final class PushNotificationService: NSObject, UNUserNotificationCenterDelegate {
    var isAuthorized = false
    var deviceToken: String?

    private let profileService = ProfileService()

    // MARK: - Authorization

    /// Push-Berechtigung anfragen. Gibt true zurueck wenn erlaubt.
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted

            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Push authorization error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Token Upload

    /// Device Token an Backend senden via PUT /api/users/:id
    func uploadToken(userId: UUID, token: String) async {
        do {
            _ = try await profileService.updateProfile(
                userId: userId,
                body: ["fcm_token": token]
            )
            print("Device token uploaded successfully")
        } catch {
            print("Device token upload failed: \(error.localizedDescription)")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Notification im Vordergrund anzeigen
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    /// User hat auf Notification getippt
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped: \(userInfo)")
        // Deep-Linking kann hier spaeter ergaenzt werden
    }
}
