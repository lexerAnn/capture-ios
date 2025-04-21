import SwiftUI

struct MainScreen: View {
    @AppStorage("isUserSignedIn") private var isUserSignedIn = true
    @State private var selectedTab = 0
    
    init() {
        // Make the tab bar background opaque and clean
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().backgroundColor = UIColor.white
        
        // Remove default tab bar top separator line
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        // Add a custom top border (optional)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.white
        
        // Remove the tab bar top shadow
        tabBarAppearance.shadowColor = UIColor.clear
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
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
            
            // Camera Screen Tab - Using the improved camera screen
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
        // Disable content insets so content can extend to the edges
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
