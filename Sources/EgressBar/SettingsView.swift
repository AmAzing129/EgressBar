import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: IPStatusModel

    @State private var tokenDraft: String

    init(model: IPStatusModel) {
        self.model = model
        _tokenDraft = State(initialValue: model.token)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Form {
                SecureField("IPinfo token", text: $tokenDraft)

                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
            }

            HStack {
                Button("Refresh Now") {
                    apply()
                }

                Spacer()

                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }

                Button("Apply") {
                    apply()
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            model.refreshLaunchAtLoginStatus()
        }
    }

    private func apply() {
        model.updateConfiguration(token: tokenDraft)
    }
}
