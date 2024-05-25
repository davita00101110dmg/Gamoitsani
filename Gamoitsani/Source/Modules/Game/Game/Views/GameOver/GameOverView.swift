//
//  GameOverView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

protocol GameOverViewDelegate: AnyObject {
    func didPressStartOver()
    func didPressGoBack()
    func didPressShowFullScoreboard()
}

final class GameOverView: UIView {

    @IBOutlet weak var winLabel: GMLabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var teamNameLabel: GMLabel!
    @IBOutlet weak var descriptionLabel: GMLabel!
    @IBOutlet weak var repeatButton: GMButton!
    @IBOutlet weak var goBackButton: GMButton!
    @IBOutlet weak var showFullScoreboardButton: GMButton!
    
    private weak var delegate: GameOverViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color.withAlphaComponent(Constants.backgroundColorAlpha)
        layer.cornerRadius = Constants.viewCornerRadius
        
        winLabel.configure(with: L10n.Screen.Game.WinningView.title,
                           fontSizeForPhone: Constants.winLabelFontSizeForPhone,
                           fontSizeForPad: Constants.winLabelFontSizeForPad,
                           textAlignment: .center)
        repeatButton.configure(with: L10n.Screen.Game.WinningView.repeat)
        goBackButton.configure(with: L10n.Screen.Game.WinningView.GameDetails.title)
        showFullScoreboardButton.configure(with: L10n.scoreboard)
    }
    
    func configure(with model: GameOverViewModel, delegate: GameOverViewDelegate) {
        self.delegate = delegate
        teamNameLabel.configure(with: model.teamName,
                                fontSizeForPhone: Constants.teamLabelFontSizeForPhone,
                                fontSizeForPad: Constants.teamLabelFontSizeForPad,
                                textAlignment: .center)
        descriptionLabel.configure(with: L10n.Screen.Game.WinningView.description(model.score.toString),
                                   fontSizeForPhone: Constants.descriptionLabelFontSizeForPhone,
                                   fontSizeForPad: Constants.descriptionLabelFontSizeForPad,
                                   textAlignment: .center)
    }
}

// MARK: - Actions
extension GameOverView {
    @IBAction func startOver(sender: Any) {
        delegate?.didPressStartOver()
    }
    
    @IBAction func goBack(sender: Any) {
        delegate?.didPressGoBack()
    }
    
    @IBAction func showFullScoreboard() {
        delegate?.didPressShowFullScoreboard()
    }
}

// MARK: - View Constants
extension GameOverView {
    enum Constants {
        static let winLabelFontSizeForPhone: CGFloat = 40
        static let winLabelFontSizeForPad: CGFloat = 74
        static let teamLabelFontSizeForPhone: CGFloat = 22
        static let teamLabelFontSizeForPad: CGFloat = 40
        static let descriptionLabelFontSizeForPhone: CGFloat = 18
        static let descriptionLabelFontSizeForPad: CGFloat = 32
        static let backgroundColorAlpha: CGFloat = 0.3
        static let viewCornerRadius: CGFloat = 10
    }
}
