import AppKit
import SwiftUI

struct StatusMenu: View {
    @ObservedObject var model: IPStatusModel
    let settingsWindow: SettingsWindowController

    var body: some View {
        Text("IP: \(model.displayIP ?? "Unknown")")
        Text("Network: \(model.networkStatusText)")
        Text("Location: \(model.locationTitle ?? "Unknown")")
        Text("Country: \(model.displayCountryCode ?? "Unknown")")
        Text("City: \(model.displayCity ?? "Unknown")")
        Text("Region: \(model.info.region ?? "Unknown")")
        Text("ASN: \(model.info.asn ?? "Unknown")")
        Text("ISP: \(model.info.isp ?? "Unknown")")
        Text("Last updated: \(model.lastUpdatedText)")

        if let errorMessage = model.errorMessage {
            Divider()
            Text("Error: \(errorMessage)")
        }

        Divider()

        Button(model.isRefreshing ? "Refreshing..." : "Refresh") {
            Task {
                await model.refresh()
            }
        }
        .disabled(model.isRefreshing)

        Button("Copy Current IP") {
            model.copyIP()
        }
        .disabled(model.info.ip == nil)

        Button("Settings...") {
            settingsWindow.show(model: model)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
