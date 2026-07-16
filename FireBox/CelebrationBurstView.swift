import SwiftUI

struct CelebrationBurstView: View {
    let text: String
    let maximumEDRHeadroom: Float

    @State private var isVisible = false

    var body: some View {
        Text(text)
            .font(.system(size: 72, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .foregroundStyle(.white)
            .colorEffect(
                ShaderLibrary.hdrText(
                    .float(maximumEDRHeadroom)
                )
            )
            .shadow(color: .white.opacity(0.9), radius: 6)
            .shadow(color: .orange.opacity(0.85), radius: 24)
            .padding(.horizontal, 24)
            .scaleEffect(isVisible ? 1 : 0.55)
            .opacity(isVisible ? 1 : 0)
            .blur(radius: isVisible ? 0 : 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .drawingGroup(opaque: false, colorMode: .extendedLinear)
            .task {
                await Task.yield()
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                    isVisible = true
                }

                try? await Task.sleep(nanoseconds: 950_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.55)) {
                    isVisible = false
                }
            }
            .accessibilityHidden(true)
    }
}
