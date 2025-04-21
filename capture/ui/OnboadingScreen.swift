//
//  OnboadingScreen.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

struct OnboardingScreen: View {
    @State private var isLoading = false
    @State private var isSignedIn = false
    @AppStorage("isUserSignedIn") private var isUserSignedIn = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background color (black to match screenshot)
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Sign in with Google button
                Button(action: signInWithGoogle) {
                    HStack {
                        Image("google_logo") // Assuming you have a google logo image in assets
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("Sign in with Google")
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
            
            // Loading indicator
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .onChange(of: isSignedIn) { newValue in
            if newValue {
                // Navigate to main screen
                isUserSignedIn = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func signInWithGoogle() {
        isLoading = true
        
        // Configure Google Sign-In
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            isLoading = false
            showToast(message: "Error configuring Google Sign-In")
            return
        }
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Request the scopes needed for Google Drive
        let scopes = ["https://www.googleapis.com/auth/drive"]
        
        // Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                isLoading = false
                showToast(message: "Sign-in error: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                isLoading = false
                showToast(message: "Failed to get ID token")
                return
            }
            
            // Create Firebase credential with Google ID token
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // Sign in with Firebase using the Google credential
            Auth.auth().signIn(with: credential) { authResult, error in
                isLoading = false
                
                if let error = error {
                    print("Firebase auth error: \(error.localizedDescription)")
                    showToast(message: "Authentication error: \(error.localizedDescription)")
                    return
                }
                
                // Save user info if needed
                if let user = authResult?.user {
                    let userModel = [
                        "name": user.displayName ?? "",
                        "email": user.email ?? "",
                        "profileImage": user.photoURL?.absoluteString ?? "",
                        "uid": user.uid
                    ]
                    
                    // Store user model in UserDefaults or other storage
                    if let encoded = try? JSONEncoder().encode(userModel) {
                        UserDefaults.standard.set(encoded, forKey: "userModel")
                    }
                }
                
                // Set signed in state to true
                isSignedIn = true
                showToast(message: "Sign in successful")
            }
        }
    }
    
    func showToast(message: String) {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first
        
        if let window = keyWindow {
            let toast = UILabel()
            toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            toast.textColor = .white
            toast.textAlignment = .center
            toast.font = UIFont.systemFont(ofSize: 14)
            toast.text = message
            toast.numberOfLines = 0
            toast.alpha = 0
            toast.layer.cornerRadius = 10
            toast.clipsToBounds = true
            toast.frame = CGRect(x: 20, y: window.frame.height - 100, width: window.frame.width - 40, height: 50)
            
            window.addSubview(toast)
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                toast.alpha = 1
            }, completion: { _ in
                UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseOut, animations: {
                    toast.alpha = 0
                }, completion: { _ in
                    toast.removeFromSuperview()
                })
            })
        }
    }
}

// MARK: - Extensions
extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }
        
        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        
        return root
    }
}

struct OnboardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreen()
    }
}
