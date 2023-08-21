//
//  Coordinator.swift
//  TattooScaner
//
//  Created by macbook pro max on 21/08/2023.
//

import UIKit

protocol Coordinatable {
    var window: UIWindow { get }
    var rootViewController: UIViewController? { get }
    var navigationController: UINavigationController? { get }
    
    func start()
}

class MainCoordinator: Coordinatable {
    var window: UIWindow
    var rootViewController: UIViewController?
    var navigationController: UINavigationController?
    
    private var storyboard: UIStoryboard
    private var homeViewController: (UIViewController & HomeViewControllerRepresentable)?
    private var newAnalysisController: UIViewController?
    
    init(window: UIWindow) {
        self.window = window
        storyboard = UIStoryboard(name: "Main", bundle: nil)
    }
    
    func start() {
        showHome()
        window.rootViewController = navigationController
    }
    
    private func showHome() {
        let homeController = createHomeViewController()
        navigationController = UINavigationController(rootViewController: homeController)
    }
    
    private func showNewAnalysis() {
        let newAnalysisController = createNewAnalysisController()
        navigationController?.pushViewController(newAnalysisController, animated: true)
    }
    
    private func createHomeViewController() -> UIViewController {
        guard var homeViewController = storyboard.instantiateViewController(withIdentifier: "Home") as? (UIViewController & HomeViewControllerRepresentable) else {
            fatalError("Unable to instantiate HomeVC from storyboard")
        }
        
        homeViewController.newAnalysisButtonTapCallback = { [weak self] in
            self?.showNewAnalysis()
        }
        
        return homeViewController
    }
    
    private func createNewAnalysisController() -> UIViewController {
        newAnalysisController = SwiftUIViewController {
            TestView()
        }
        return newAnalysisController!
    }
}
