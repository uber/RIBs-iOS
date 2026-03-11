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
    private var urlHandler: UrlHandler?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let appComponent = AppComponent()

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let result = RootBuilder(dependency: appComponent).build()
        launchRouter = result.launchRouter
        urlHandler = result.urlHandler
        result.launchRouter.launch(from: window)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            urlHandler?.handle(url)
        }
    }
}
