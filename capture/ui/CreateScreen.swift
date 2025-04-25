//
//  CreateScreen.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import SwiftUI
struct CreateScreen: View {
    @State private var occasionText = ""
    @State private var buttonEnabled = false
    @State private var navigateToEventDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Text field for occasion input positioned at bottom, above button
                    TextField("What's the occasion?", text: $occasionText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .onChange(of: occasionText) { newValue in
                            // Enable button if text field is not empty
                            buttonEnabled = !newValue.isEmpty
                        }
                    
                    // Continue button
                    Button(action: {
                        // Navigate to event details screen
                        print("Navigate to event details with occasion: \(occasionText)")
                        navigateToEventDetails = true
                    }) {
                        Text(buttonEnabled ? "Continue" : "Enter occasion")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(buttonEnabled ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                    }
                    .disabled(!buttonEnabled)
                }
            }
            .navigationDestination(isPresented: $navigateToEventDetails) {
                EventDetailsScreen(eventName: occasionText)
            }
        }
    }
    
    struct CreateScreen_Previews: PreviewProvider {
        static var previews: some View {
            CreateScreen()
        }
    }
}
