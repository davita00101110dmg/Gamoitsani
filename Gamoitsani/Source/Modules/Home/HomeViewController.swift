//
//  HomeViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//

import UIKit

final class HomeViewController: BaseViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var wandLabel: UILabel!
    @IBOutlet weak var gameButton: GMButton!
    @IBOutlet weak var rulesButton: GMButton!
    
    weak var coordinator: MainCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.isHidden = true
        navigationController?.navigationBar.prefersLargeTitles = true
    
        setupRightBarButtonItem()
    }

    override func setupUI() {
        super.setupUI()
        titleLabel.textColor = UIColor.tintColor
        
        wandLabel.text = "🪄"
        wandLabel.font = UIFont.systemFont(ofSize: 175)
    }
    
    override func setupLocalizedTexts() {
        super.setupLocalizedTexts()
        title = "app.title".localized
        titleLabel.text = "app.title".localized
        gameButton.configure(text: "screen.home.play_button.title".localized)
        rulesButton.configure(text: "screen.home.rules_button.title".localized)
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
    
    @IBAction func gameButtonClicked(_ sender: Any) {
        
    }
    
    @IBAction func rulesButtonClicked(_ sender: Any) {
        coordinator?.navigateToRules()
    }
}
