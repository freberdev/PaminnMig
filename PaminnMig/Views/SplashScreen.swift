import SwiftUI

struct SplashScreen: View {
    @State private var isRinging = false
    @State private var showContent = false
    @State private var finished = false

    var body: some View {
        ZStack {
            AppTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App Icon
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                    .rotationEffect(.degrees(isRinging ? 8 : 0))
                    .animation(
                        isRinging ?
                        Animation
                            .easeInOut(duration: 0.08)
                            .repeatCount(12, autoreverses: true) :
                            .default,
                        value: isRinging
                    )

                // App name
                Text("Påminn mig!")
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(-0.8)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.top, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // Developer
                Text("freber.dev")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 6)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Spacer()
            }
        }
        .onAppear {
            // Start ring animation after a brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isRinging = true
            }

            // Show text content
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showContent = true
            }

            // End ring and dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                isRinging = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    finished = true
                }
            }
        }
        .opacity(finished ? 0 : 1)
        .allowsHitTesting(!finished)
    }

    var isFinished: Bool { finished }
}
