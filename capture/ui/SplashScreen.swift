//
//  SplashScreen.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @AppStorage("isUserSignedIn") private var isUserSignedIn = false
    
    var body: some View {
        ZStack {
            // Background color (black to match your theme)
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // App logo or name
                Text("Capture")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding(.top, 30)
            }
        }
        .onAppear {
            // Wait for 3 seconds then check if user is signed in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            // Navigate based on sign-in status
            if isUserSignedIn {
                MainScreen()
            } else {
                OnboardingScreen()
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
