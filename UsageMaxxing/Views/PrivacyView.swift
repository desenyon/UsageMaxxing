import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Local only", systemImage: "lock.shield")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }

            Text("UsageMaxxing runs locally and reads installed-app usage through OpenUsage-compatible local plugins. It has no cloud backend and does not display fabricated, manual, hardcoded, or estimated usage.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Only installed apps with exact plugin output appear as usage cards.", systemImage: "checkmark.circle")
                Label("Existing app credentials are read only when the local plugin needs them.", systemImage: "key")
                Label("Unsupported or expired-auth services are marked unavailable.", systemImage: "exclamationmark.triangle")
                Label("Secrets are not logged by the app.", systemImage: "terminal")
            }
            .font(.system(size: 13))

            Spacer()
        }
        .padding(22)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}
