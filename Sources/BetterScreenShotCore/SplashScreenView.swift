import SwiftUI
import AppKit

public struct SplashScreenView: View {
    @AppStorage("showSplashOnLaunch") private var showSplashOnLaunch: Bool = true
    public var onDismiss: (() -> Void)?

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 22) {
            // App Branding Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 88, height: 88)
                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text("Better Screen Shot")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("Version 1.0.0 (Build 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Instant desktop & window capture straight to your clipboard buffer.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Quick Shortcut Cards
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bullseye Window Capture")
                            .font(.headline)
                        Text("Click or drag from the menubar onto any window, or press hotkey.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("⌘ ⇧ 2")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.tertiaryLabelColor).opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                HStack(spacing: 14) {
                    Image(systemName: "display")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full Display Capture")
                            .font(.headline)
                        Text("Instantly snap the active screen straight into your pasteboard.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("⌘ ⇧ 1")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.tertiaryLabelColor).opacity(0.2))
                        .cornerRadius(6)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(.horizontal, 10)

            Spacer()

            Divider()

            HStack {
                Toggle("Show at launch", isOn: $showSplashOnLaunch)
                    .toggleStyle(.checkbox)
                    .font(.footnote)

                Spacer()

                Button("Start Capturing") {
                    onDismiss?()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500, height: 460)
    }
}
