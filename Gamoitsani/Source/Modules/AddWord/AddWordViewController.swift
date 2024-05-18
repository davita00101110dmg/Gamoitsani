//
//  AddWordViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class AddWordViewController: BaseViewController<AddWordCoordinator> {
    
    @IBOutlet weak var hintMessageLabel: GMLabel!
    @IBOutlet weak var wordTextField: GMTextField!
    @IBOutlet weak var addWordButton: GMButton!
    
    private var wordsToBeAdded: [String] = []
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sendWordsToDB()
    }
    
    override func setupUI() {
        super.setupUI()
        title = L10n.Screen.AddWord.title
        addWordButton.configure(with: L10n.Screen.AddWord.send)
        hintMessageLabel.configure(with: L10n.Screen.AddWord.hint)
        wordTextField.addPadding(padding: .equalSpacing(16))
    }
    
    private func sendWordsToDB() {
        if !wordsToBeAdded.isEmpty { FirebaseManager.shared.addWords(wordsToBeAdded) }
    }
    
    @IBAction func addWordAction(_ sender: Any) {
        guard let word = wordTextField.text, word != .empty else { return }
        wordsToBeAdded.append(word.removeExtraSpaces())
        wordTextField.text = .empty
    }
}
