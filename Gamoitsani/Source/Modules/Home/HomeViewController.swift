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
        titleLabel.configure(with: L10n.App.title,
                             fontType: .bold,
                             fontSizeForPhone: ViewControllerConstants.titleLabelFontSizeForPhone,
                             fontSizeForPad: ViewControllerConstants.titleLabelFontSizeForPad)
        gameButton.configure(with: L10n.Screen.Home.PlayButton.title)
        rulesButton.configure(with: L10n.Screen.Home.RulesButton.title)
        addWordButton.configure(with: L10n.Screen.Home.AddWordButton.title)
    }
    
    private func setupRightBarButtonItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(rightBarButtonClicked))
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
    
    @objc private func rightBarButtonClicked() {
        coordinator?.presentSettings()
    }
}

// MARK: - ViewController Constants
extension HomeViewController {
    enum ViewControllerConstants {
        static let titleLabelFontSizeForPhone: CGFloat = 40
        static let titleLabelFontSizeForPad: CGFloat = 74
    }
}
