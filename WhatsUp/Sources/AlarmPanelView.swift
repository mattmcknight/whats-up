import SwiftUI

struct AlarmPanelView: View {
    let event: CalendarEvent
    let zoomLink: URL?
    let controller: AlarmController

    @State private var flashOn = true

    var body: some View {
        VStack(spacing: 16) {
            // Meeting type badge
            HStack {
                Image(systemName: zoomLink != nil ? "video.fill" : "person.2.fill")
                Text(zoomLink != nil ? "Zoom Meeting" : "In-Person Meeting")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white.opacity(0.9))

            // Title
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Time info
            let mins = event.minutesSinceStart
            Text(mins == 0 ? "Starting NOW" : "Started \(mins)m ago")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            // Action buttons
            HStack(spacing: 12) {
                if let url = zoomLink {
                    Button(action: { controller.joinZoom(url: url) }) {
                        Label("Join Zoom", systemImage: "video.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.red)
                    .controlSize(.large)
                } else {
                    Button(action: { controller.acknowledge() }) {
                        Label("On My Way", systemImage: "figure.walk")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.red)
                    .controlSize(.large)
                }

                Button(action: { controller.skip() }) {
                    Text("Skip")
                        .frame(maxWidth: 60)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.7))
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(flashOn ? Color.red : Color.red.opacity(0.7))
        )
        .onAppear {
            startFlashing()
        }
    }

    private func startFlashing() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    flashOn.toggle()
                }
            }
        }
    }
}
