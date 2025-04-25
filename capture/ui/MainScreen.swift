import SwiftUI
struct MainScreen: View {
    @AppStorage("isUserSignedIn") private var isUserSignedIn = true
    @State private var selectedTab = 0
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CreateScreen()
            }
            .tabItem {
                Image(systemName: "plus.square")
                Text("Create")
            }
            .tag(0)
            
            CameraScreen()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(1)
            
            SettingScreen()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue) // Color of selected tab
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
