//
//  LoanStatusBadge.swift
//  Onest
//
//  Created by Ricardo Messon on 10/1/26.
//

import SwiftUI

public struct LoanStatusBadge: View {
    public let status: LoanStatus

    public init(status: LoanStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.systemIcon)
                .font(.system(size: 11, weight: .semibold))
            Text(status.title)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundColor(OnestTheme.statusForeground(for: status))
        .background(OnestTheme.statusBackground(for: status))
        .clipShape(Capsule())
    }
}

public struct InstallmentStatusBadge: View {
    public let status: InstallmentStatus

    public init(status: InstallmentStatus) {
        self.status = status
    }

    public var body: some View {
        let colors = OnestTheme.installmentStatusColor(for: status)
        Text(status.title)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(colors.fg)
            .background(colors.bg)
            .clipShape(Capsule())
    }
}
