import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Background color matching app theme
            Color(red: 11/255, green: 19/255, blue: 43/255)
                .ignoresSafeArea()

            // Splash screen image
            Image("SplashScreen")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    LaunchScreen()
}
