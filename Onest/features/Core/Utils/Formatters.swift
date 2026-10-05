//
//  Formatters.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import Foundation

public enum CurrencyFormatter {
    private static let dopFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "RD$"
        formatter.currencyCode = "DOP"
        formatter.locale = Locale(identifier: "es_DO")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let dopNoDecimalsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "RD$"
        formatter.currencyCode = "DOP"
        formatter.locale = Locale(identifier: "es_DO")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public static func formatDOP(_ value: Double, includeDecimals: Bool = true) -> String {
        let formatter = includeDecimals ? dopFormatter : dopNoDecimalsFormatter
        return formatter.string(from: NSNumber(value: value)) ?? "RD$ \(String(format: "%.2f", value))"
    }

    public static func formatPercentage(_ value: Double) -> String {
        let percent = value * 100
        return String(format: "%.1f%%", percent)
    }
}

public enum AppDateFormatters {
    public static let standardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_DO")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    public static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_DO")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    public static func formatShort(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return standardDate.string(from: date)
    }

    public static func formatFull(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return fullDate.string(from: date)
    }
}
