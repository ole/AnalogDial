import UIKit

let store = Store()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var timer: Timer? = nil

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//    store.state.speed = 25
    timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { t in
      let speedChange: Double
      switch store.state.speed {
      case ...20: speedChange = Double.random(in: -1...3)
      case 40...: speedChange = Double.random(in: -3...1)
      default: speedChange = Double.random(in: -2...2)
      }
      store.state.speed = max(0, min(store.state.speed + speedChange, 60))
    }
    return true
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
}
