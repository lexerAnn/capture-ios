//
//  MainScreen.swift
//  capture
//
//  Created by Leslie Annan on 21/04/2025.
//

import SwiftUI

struct MainScreen: View {
    @AppStorage("isUserSignedIn") private var isUserSignedIn = true
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Create Screen Tab
            NavigationStack {
                CreateScreen()
            }
            .tabItem {
                Image(systemName: "plus.square")
                Text("Create")
            }
            .tag(0)
            
            // Camera Screen Tab
            CameraScreen()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(1)
            
            // Settings Screen Tab
            SettingScreen()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue) // Color of selected tab
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
