//
//  AppDelegate.swift
//  JSNestedScrollExample
//
//  Created by jiasong on 2022/11/7.
//

import UIKit
import QMUIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.configureWindow()
        return true
    }

}

extension AppDelegate {
    
    func configureWindow() -> Void {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = QMUINavigationController(rootViewController: NestedScrollViewController())
        self.window?.makeKeyAndVisible()
    }
    
}
