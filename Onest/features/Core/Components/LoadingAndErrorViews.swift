//
//  LoadingAndErrorViews.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct OnestLoadingView: View {
    public let message: String

    public init(message: String = "Cargando...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .progressViewStyle(CircularProgressViewStyle(tint: OnestTheme.primary))
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(OnestTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OnestTheme.background)
    }
}

public struct OnestErrorView: View {
    public let title: String
    public let message: String
    public let retryAction: (() -> Void)?

    public init(
        title: String = "Ha ocurrido un error",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 229/255, green: 57/255, blue: 53/255))

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(OnestTheme.textPrimary)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(OnestTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reintentar")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(OnestTheme.primary)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(OnestTheme.background)
    }
}

public struct OnestEmptyStateView: View {
    public let title: String
    public let message: String
    public let icon: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        title: String,
        message: String,
        icon: String = "tray.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(OnestTheme.secondary)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(OnestTheme.textPrimary)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(OnestTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(OnestTheme.primary)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
