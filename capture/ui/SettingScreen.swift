//
//  SettingScreen.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import SwiftUI

struct SettingScreen: View {
    @AppStorage("isUserSignedIn") private var isUserSignedIn = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.horizontal)
            
            List {
                Section(header: Text("Account")) {
                    Button(action: {
                        // Sign out functionality
                        isUserSignedIn = false
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Toggle("Enable Notifications", isOn: .constant(true))
                    Toggle("Dark Mode", isOn: .constant(false))
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct SettingScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingScreen()
    }
}
