//
//  AddWordViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import GoogleMobileAds

final class AddWordViewController: BaseViewController<AddWordCoordinator> {
    
    @IBOutlet weak var hintMessageLabel: GMLabel!
    @IBOutlet weak var wordTextField: GMTextField!
    @IBOutlet weak var addWordButton: GMButton!
    @IBOutlet weak var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addHideKeyboardTapGestureRecogniser()
        setupBannerView(with: bannerView)
        #if DEBUG
        configureAdInspector()
        #endif
    }
    
    override func setupUI() {
        super.setupUI()
        title = L10n.Screen.AddWord.title
        addWordButton.configure(with: L10n.Screen.AddWord.send)
        hintMessageLabel.configure(with: L10n.Screen.AddWord.hint, textAlignment: .left)
        wordTextField.addPadding(padding: .equalSpacing(16))
    }
    
    private func addHideKeyboardTapGestureRecogniser() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func configureAdInspector() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(presentAdInspector))
        view.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func addWordAction(_ sender: Any) {
        guard let word = wordTextField.text, word != .empty else { return }
        FirebaseManager.shared.addWordToSuggestions(word.removeExtraSpaces()) { success in
            // TODO: Add some UI here
            if success {
                dump("Word succesfully sent to suggestions")
            } else {
                dump("Word wasn't sent to suggestions")
            }
        }
        wordTextField.text = .empty
    }
}
