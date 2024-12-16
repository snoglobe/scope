import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case dataLoadFailed
    case saveFailed
    case healthKitAccessDenied
    case aiAnalysisFailed
    case backupFailed
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed:
            return "Failed to load your health data"
        case .saveFailed:
            return "Failed to save your changes"
        case .healthKitAccessDenied:
            return "Unable to access HealthKit data"
        case .aiAnalysisFailed:
            return "AI analysis failed"
        case .backupFailed:
            return "Failed to create backup"
        case .restoreFailed:
            return "Failed to restore from backup"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataLoadFailed:
            return "Try closing and reopening the app"
        case .saveFailed:
            return "Check your device's available storage"
        case .healthKitAccessDenied:
            return "Check your privacy settings in the Settings app"
        case .aiAnalysisFailed:
            return "Try again or check your internet connection"
        case .backupFailed:
            return "Check your iCloud settings and available storage"
        case .restoreFailed:
            return "Make sure the backup file is not corrupted"
        }
    }
}

class ErrorHandler {
    static func handle(_ error: Error, retryAction: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: "\(error.localizedDescription)\n\n\(getRecoverySuggestion(for: error))",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let retry = retryAction {
                alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                    retry()
                })
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    private static func getRecoverySuggestion(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.recoverySuggestion ?? ""
        }
        return "Please try again later"
    }
} 
