//
//  SceneDelegate.swift
//  Pulsometer
//
//  Created by Кизим Илья on 16.04.2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        window?.rootViewController = PulsometerViewController()
        window?.makeKeyAndVisible()
    }
}

