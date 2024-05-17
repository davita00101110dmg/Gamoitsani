//
//  HomeViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//

import UIKit

final class HomeViewController: BaseViewController<HomeCoordinator> {
    
    @IBOutlet weak var titleLabel: GMLabel!
    @IBOutlet weak var gameButton: GMButton!
    @IBOutlet weak var rulesButton: GMButton!
    @IBOutlet weak var addWordButton: GMButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRightBarButtonItem()
    }
    
    override func setupLocalizedTexts() {
        super.setupLocalizedTexts()
        titleLabel.configure(with: L10n.App.title, fontSize: 40)
        gameButton.configure(text: L10n.Screen.Home.PlayButton.title)
        rulesButton.configure(text: L10n.Screen.Home.RulesButton.title)
        addWordButton.configure(text: L10n.Screen.Home.AddWordButton.title)
    }
    
    private func setupRightBarButtonItem() {
        let menuHandler: UIActionHandler = { action in
            
            let languageIdentifier = action.title == "ქართული" ? AppConstants.Language.georgian.identifier : AppConstants.Language.english.identifier
            
            UserDefaults.appLanguage = languageIdentifier
            
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
        
        let barButtonMenu = UIMenu(title: "Language", children: [
            UIAction(title: "ქართული", handler: menuHandler),
            UIAction(title: "English", handler: menuHandler)
        ])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "globe"), primaryAction: nil, menu: barButtonMenu)
    }
}
 
// MARK: - Actions
extension HomeViewController {
    @IBAction func gameButtonClicked(_ sender: Any) {
        coordinator?.navigateToGameDetails()
    }
    
    @IBAction func rulesButtonClicked(_ sender: Any) {
        coordinator?.navigateToRules()
    }
    
    @IBAction func addWordButtonClicked(_ sender: Any) {
        coordinator?.navigateToAddWord()
    }
}
