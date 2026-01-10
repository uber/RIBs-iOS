//
//  SceneDelegate.swift
//  RIBsAppExample2
//
//  Created by Alex Bush on 1/10/26.
//

import UIKit
import RIBs

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private var launchRouter: LaunchRouting?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        
        let appComponent = AppComponent()
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let launchRouter = RootBuilder(dependency: appComponent).build()
        self.launchRouter = launchRouter
        launchRouter.launch(from: window)
    }
}
