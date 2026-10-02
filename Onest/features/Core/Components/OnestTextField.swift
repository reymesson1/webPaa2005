//
//  OnestTextField.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct OnestTextField: View {
    public let label: String?
    public let placeholder: String
    public let icon: String
    public let isSecure: Bool
    @Binding public var text: String
    public var errorMessage: String?
    public var keyboardType: UIKeyboardType = .default
    public var autocapitalization: TextInputAutocapitalization = .never

    @State private var isShowingPassword: Bool = false

    public init(
        label: String? = nil,
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
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .leading) {
                // Outlined border container with pure white background
                RoundedRectangle(cornerRadius: 14)
                    .stroke(errorMessage != nil ? Color.red : OnestTheme.inputBorder, lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))

                // Field contents
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(OnestTheme.textPrimary)
                        .frame(width: 22)

                    if isSecure && !isShowingPassword {
                        SecureField(placeholder, text: $text)
                            .font(.system(size: 16))
                            .foregroundColor(OnestTheme.textPrimary)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled()
                            .keyboardType(keyboardType)
                    } else {
                        TextField(placeholder, text: $text)
                            .font(.system(size: 16))
                            .foregroundColor(OnestTheme.textPrimary)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled()
                            .keyboardType(keyboardType)
                    }

                    if isSecure {
                        Button(action: { isShowingPassword.toggle() }) {
                            Image(systemName: isShowingPassword ? "eye.slash" : "eye")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundColor(OnestTheme.mintGreen)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Notch / Embedded border label
                if let label = label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(errorMessage != nil ? .red : OnestTheme.inputLabel)
                        .padding(.horizontal, 6)
                        .background(Color.white)
                        .offset(x: 22, y: -27)
                }
            }
            .frame(height: 54)
            .padding(.top, label != nil ? 6 : 0)

            // Inline error message
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(errorMessage)
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
                .padding(.leading, 8)
                .padding(.top, 2)
            }
        }
    }
}
