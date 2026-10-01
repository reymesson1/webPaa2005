//
//  Theme.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public enum OnestTheme {
    // Primary Brand Colors
    public static let primary = Color(red: 10/255, green: 104/255, blue: 71/255) // #0A6847 Emerald
    public static let primaryDark = Color(red: 6/255, green: 71/255, blue: 48/255)
    public static let primaryLight = Color(red: 232/255, green: 245/255, blue: 233/255) // #E8F5E9 Mint tint
    public static let secondary = Color(red: 122/255, green: 186/255, blue: 120/255) // #7ABA78

    // Neutral Colors
    public static let background = Color(red: 248/255, green: 249/255, blue: 250/255) // #F8F9FA
    public static let cardBackground = Color(red: 255/255, green: 255/255, blue: 255/255)
    public static let textPrimary = Color(red: 18/255, green: 30/255, blue: 49/255) // #121E31
    public static let textSecondary = Color(red: 108/255, green: 117/255, blue: 125/255)
    public static let divider = Color(red: 233/255, green: 236/255, blue: 239/255)

    // Status Colors
    public static func statusForeground(for status: LoanStatus) -> Color {
        switch status {
        case .enRevision:
            return Color(red: 230/255, green: 81/255, blue: 0/255) // Orange
        case .aprobado:
            return Color(red: 21/255, green: 101/255, blue: 192/255) // Blue
        case .desembolsado:
            return Color(red: 46/255, green: 125/255, blue: 50/255) // Green
        case .rechazado:
            return Color(red: 198/255, green: 40/255, blue: 40/255) // Red
        case .pagado:
            return Color(red: 69/255, green: 90/255, blue: 100/255) // Slate
        }
    }

    public static func statusBackground(for status: LoanStatus) -> Color {
        switch status {
        case .enRevision:
            return Color(red: 255/255, green: 243/255, blue: 224/255)
        case .aprobado:
            return Color(red: 227/255, green: 242/255, blue: 253/255)
        case .desembolsado:
            return Color(red: 232/255, green: 245/255, blue: 233/255)
        case .rechazado:
            return Color(red: 255/255, green: 235/255, blue: 238/255)
        case .pagado:
            return Color(red: 236/255, green: 239/255, blue: 241/255)
        }
    }

    public static func installmentStatusColor(for status: InstallmentStatus) -> (fg: Color, bg: Color) {
        switch status {
        case .pagado:
            return (Color(red: 46/255, green: 125/255, blue: 50/255), Color(red: 232/255, green: 245/255, blue: 233/255))
        case .pendiente:
            return (Color(red: 21/255, green: 101/255, blue: 192/255), Color(red: 227/255, green: 242/255, blue: 253/255))
        case .vencido:
            return (Color(red: 198/255, green: 40/255, blue: 40/255), Color(red: 255/255, green: 235/255, blue: 238/255))
        }
    }
}
