//
//  Theme.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public enum OnestTheme {
    // MARK: - Brand Identity Colors (From Design Spec)
    /// Mint Green accent used in "Iniciar Sesión" text, input borders, and icons
    public static let mintGreen = Color(red: 117/255, green: 209/255, blue: 159/255) // #75D19F / #81D4A5
    
    /// Vibrant primary brand green
    public static let primary = Color(red: 75/255, green: 181/255, blue: 119/255) // #4BB577
    public static let primaryDark = Color(red: 24/255, green: 24/255, blue: 24/255) // #181818
    public static let primaryLight = Color(red: 230/255, green: 243/255, blue: 228/255) // #E6F3E4 Pastel mint
    
    /// Logo Lime underline accent
    public static let limeAccent = Color(red: 178/255, green: 225/255, blue: 123/255) // #B2E17B
    
    /// Complementary Brand Accent
    public static let secondary = Color(red: 178/255, green: 225/255, blue: 123/255) // #B2E17B
    public static let secondaryDark = Color(red: 140/255, green: 195/255, blue: 85/255)
    
    /// Neutral & Surface Colors
    public static let backgroundTop = Color(red: 247/255, green: 249/255, blue: 247/255) // #F7F9F7
    public static let backgroundMid = Color(red: 228/255, green: 240/255, blue: 226/255) // #E4F0E2 Soft mint pastel
    public static let backgroundBottom = Color(red: 232/255, green: 242/255, blue: 230/255) // #E8F2E6
    public static let background = Color(red: 245/255, green: 248/255, blue: 245/255)
    
    public static let cardBackground = Color.white
    public static let inputBorder = Color(red: 117/255, green: 209/255, blue: 159/255) // #75D19F
    public static let inputLabel = Color(red: 124/255, green: 130/255, blue: 138/255) // #7C828A
    
    public static let buttonDisabled = Color(red: 226/255, green: 226/255, blue: 226/255) // #E2E2E2
    public static let buttonText = Color(red: 24/255, green: 24/255, blue: 24/255) // #181818
    
    public static let textPrimary = Color(red: 24/255, green: 24/255, blue: 24/255) // #181818
    public static let textSecondary = Color(red: 110/255, green: 115/255, blue: 120/255)
    public static let linkColor = Color(red: 90/255, green: 140/255, blue: 114/255) // #5A8C72
    public static let divider = Color(red: 230/255, green: 233/255, blue: 236/255)

    // MARK: - Gradient Background Spec
    public static var appBackgroundGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: backgroundTop, location: 0.0),
                .init(color: backgroundMid, location: 0.45),
                .init(color: backgroundBottom, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Status Badge Colors
    public static func statusForeground(for status: LoanStatus) -> Color {
        switch status {
        case .enRevision:
            return Color(red: 217/255, green: 119/255, blue: 6/255) // Amber
        case .aprobado:
            return Color(red: 37/255, green: 99/255, blue: 235/255) // Blue
        case .desembolsado:
            return Color(red: 34/255, green: 140/255, blue: 81/255) // Emerald
        case .rechazado:
            return Color(red: 220/255, green: 38/255, blue: 38/255) // Red
        case .pagado:
            return Color(red: 71/255, green: 85/255, blue: 105/255) // Slate
        }
    }

    public static func statusBackground(for status: LoanStatus) -> Color {
        switch status {
        case .enRevision:
            return Color(red: 254/255, green: 243/255, blue: 199/255)
        case .aprobado:
            return Color(red: 239/255, green: 246/255, blue: 255/255)
        case .desembolsado:
            return Color(red: 230/255, green: 243/255, blue: 228/255)
        case .rechazado:
            return Color(red: 254/255, green: 242/255, blue: 242/255)
        case .pagado:
            return Color(red: 241/255, green: 245/255, blue: 249/255)
        }
    }

    public static func installmentStatusColor(for status: InstallmentStatus) -> (fg: Color, bg: Color) {
        switch status {
        case .pagado:
            return (Color(red: 34/255, green: 140/255, blue: 81/255), Color(red: 230/255, green: 243/255, blue: 228/255))
        case .pendiente:
            return (Color(red: 37/255, green: 99/255, blue: 235/255), Color(red: 239/255, green: 246/255, blue: 255/255))
        case .vencido:
            return (Color(red: 220/255, green: 38/255, blue: 38/255), Color(red: 254/255, green: 242/255, blue: 242/255))
        }
    }
}
