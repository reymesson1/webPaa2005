//
//  OnestTextField.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct OnestTextField: View {
    public let label: String
    public let placeholder: String
    public let icon: String
    public let isSecure: Bool
    @Binding public var text: String
    public var errorMessage: String?
    public var keyboardType: UIKeyboardType = .default
    public var autocapitalization: TextInputAutocapitalization = .never

    @State private var isShowingPassword: Bool = false

    public init(
        label: String,
        placeholder: String,
        icon: String,
        isSecure: Bool = false,
        text: Binding<String>,
        errorMessage: String? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .never
    ) {
        self.label = label
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self._text = text
        self.errorMessage = errorMessage
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(OnestTheme.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(errorMessage != nil ? .red : OnestTheme.primary)
                    .frame(width: 20)

                if isSecure && !isShowingPassword {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                }

                if isSecure {
                    Button(action: { isShowingPassword.toggle() }) {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(OnestTheme.textSecondary)
                    }
                } else if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(OnestTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorMessage != nil ? Color.red : OnestTheme.divider, lineWidth: 1.5)
            )
            .cornerRadius(12)

            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
                .padding(.leading, 4)
            }
        }
    }
}
