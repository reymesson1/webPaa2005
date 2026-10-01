//
//  OnestButton.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public enum OnestButtonStyle {
    case primary
    case secondary
    case outline
    case destructive
}

public struct OnestButton: View {
    public let title: String
    public let icon: String?
    public let style: OnestButtonStyle
    public let isLoading: Bool
    public let isEnabled: Bool
    public let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        style: OnestButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: style == .outline ? 1.5 : 0)
            )
            .cornerRadius(14)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return OnestTheme.primary
        case .secondary:
            return OnestTheme.primaryLight
        case .outline:
            return Color.clear
        case .destructive:
            return Color(red: 229/255, green: 57/255, blue: 53/255)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return OnestTheme.primaryDark
        case .outline:
            return OnestTheme.primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .outline:
            return OnestTheme.primary
        default:
            return .clear
        }
    }
}
