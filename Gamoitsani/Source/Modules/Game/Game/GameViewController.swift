//
//  GameViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import GoogleMobileAds

final class GameViewController: BaseViewController<GameCoordinator> {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerView: GADBannerView!
    
    private var shouldShowInfoView: Bool = false
    private var gameStory = GameStory.shared
    
    private lazy var gameInfoView: GameInfoView? = {
        GameInfoView.loadFromNib()
    }()
    
    private lazy var gamePlayView: GamePlayView? = {
        GamePlayView.loadFromNib()
    }()
    
    private lazy var gameOverView: GameOverView? = {
        GameOverView.loadFromNib()
    }()
    
    private lazy var gameShareView: GameShareView? = {
        GameShareView.loadFromNib()
    }()
    
    private lazy var confettiLayer = CAEmitterLayer()
    private lazy var audioManager = AudioManager()
    
    private var interstitial: GADInterstitialAd?
    private var actionAfterAdDismissal: (() -> Void)?
    
    var viewModel: GameViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        setupBannerView(with: bannerView)
        setupAndLoadInterstitialAdUnit()
        showGameInfoView()
        configureAudioManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func setupBackButton() {
        let action = UIAction { [weak self] _ in
            self?.presentAlertOnBackButton()
        }
        
        navigationItem.backAction = action
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func setupAndLoadInterstitialAdUnit() {
        guard AppConstants.isAppInEnglish else { return }
        
        Task {
            await loadInterstitialAdUnit()
        }
    }
    
    private func loadInterstitialAdUnit() async {
        do {
            interstitial = try await GADInterstitialAd.load(
                withAdUnitID: AppConstants.AdMob.interstitialAdId, request: GADRequest())
            interstitial?.fullScreenContentDelegate = self
        } catch {
            dump("Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
    }
    
    private func configureAudioManager() {
        let operationQueue = OperationQueue()
        let audioSetupOperation = BlockOperation { [weak self] in
            self?.audioManager.setupSounds()
        }
        operationQueue.addOperation(audioSetupOperation)
    }
    
    private func showGameInfoView() {
        guard let gameInfoView,
              let viewModel else { return }
        gameInfoView.configure(with: .init(
            teamName: viewModel.currentTeamName,
            currentRound: viewModel.currentRound,
            currentExtraRound: viewModel.currentExtraRound),
                               delegate: self)
        
        gameInfoView.frame = mainView.bounds
        mainView.addSubview(gameInfoView)
    }
    
    private func showGamePlayView() {
        guard let gamePlayView else { return }
        gamePlayView.configure(with: .init(words: gameStory.words.removeFirstNItems(50),
                                           roundLength: gameStory.lengthOfRound,
                                           score: gameStory.teams.values[gameStory.currentTeamIndex]),
                               audioManager: audioManager,
                               delegate: self)
        gamePlayView.frame = mainView.bounds
        mainView.addSubview(gamePlayView)
    }
    
    private func showGameOverView(teamName: String, score: Int) {
        guard let gameOverView else { return }
        navigationController?.isNavigationBarHidden = true
        startConfettiAnimation()
        
        mainViewHeightConstraint.constant = ViewControllerConstants.mainViewHeightForGameOverView
        
        gameOverView.configure(with: .init(teamName: teamName,
                                           score: score),
                               delegate: self)
        gameOverView.frame = mainView.bounds
        
        UIView.transition(with: mainView,
                          duration: ViewControllerConstants.gameOverViewTransitionDuration,
                          options: [.transitionCrossDissolve, .allowUserInteraction],
                          animations: {
            self.mainView.addSubview(gameOverView)
        })
    }
    
    private func configureGameShareView(teamName: String, score: Int) {
        gameShareView?.configure(with: .init(teamName: teamName,
                                           score: score))
    }
    
    private func toggleGameView() {
        mainView.removeAllSubviews()
        
        if viewModel?.handleEndOfGame() ?? false {
            presentGameOverView()
            return
        }
        
        toggleInfoView()
    }
    
    private func toggleInfoView() {
        // TODO: Add game info enum and control which view to show from it
        shouldShowInfoView.toggle()
        if shouldShowInfoView {
            gameStory.playingSessionCount += 1
            showGamePlayView()
        } else {
            showGameInfoView()
        }
    }
    
    @objc private func presentAlertOnBackButton() {
        let alert = UIAlertController(title: L10n.Screen.Game.ConfirmationAlert.title,
                                      message: L10n.Screen.Game.ConfirmationAlert.message,
                                      preferredStyle: .alert)
        
        alert.addAction(.init(title: L10n.yesPolite,
                              style: .destructive) { [weak self] _ in
            guard let self else { return }
            gameStory.reset()
            self.coordinator?.pop()
        })
        
        alert.addAction(.init(title: L10n.no, style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentGameOverView() {
        guard let sortedTeams = viewModel?.sortedTeams,
              let winnerTeam = sortedTeams.first else { return }
        
        gameStory.finishedGamesCountInSession += 1
        showGameOverView(teamName: winnerTeam.key, score: winnerTeam.value)
        configureGameShareView(teamName: winnerTeam.key, score: winnerTeam.value)
    }
    
    private func startConfettiAnimation() {
        confettiLayer.emitterPosition = .init(x: view.center.x, y: UIApplication.shared.currentScene?.interfaceOrientation == .portrait ? -view.frame.height/2 : -view.frame.height)
        confettiLayer.opacity = 1
        
        let colors: [UIColor] = [
            Asset.color1.color,
            Asset.color2.color,
            Asset.color3.color,
            Asset.color4.color,
            Asset.color5.color,
            Asset.color6.color,
            Asset.color7.color,
            Asset.color8.color,
            Asset.color9.color,
            Asset.color10.color
        ]
        
        let cells: [CAEmitterCell] = colors.compactMap {
            let cell = CAEmitterCell()
            cell.scale = ViewControllerConstants.cellScale
            cell.scaleRange = ViewControllerConstants.cellScaleRange
            cell.emissionRange = .pi * 2
            cell.lifetime = ViewControllerConstants.cellLifetime
            cell.birthRate = ViewControllerConstants.cellBirthRate
            cell.velocity = ViewControllerConstants.cellVelocity
            cell.velocityRange = ViewControllerConstants.cellVelocityRange
            cell.spin = ViewControllerConstants.cellSpin
            cell.spinRange = ViewControllerConstants.cellSpinRange
            cell.color = $0.cgColor
            cell.contents = Asset.confetti.image.cgImage
            return cell
        }
        
        let birthRateAnimation = CABasicAnimation(keyPath: ViewControllerConstants.birthRateAnimation)
        birthRateAnimation.fromValue = ViewControllerConstants.birthRateStartFromValue
        birthRateAnimation.toValue = ViewControllerConstants.birthRateStartToValue
        birthRateAnimation.duration = ViewControllerConstants.birthRateStartDuration
        birthRateAnimation.isRemovedOnCompletion = false
        
        confettiLayer.add(birthRateAnimation, forKey: ViewControllerConstants.birthRateAnimationKey)
        confettiLayer.emitterCells = cells
        view.layer.addSublayer(confettiLayer)
    }
    
    private func stopConfettiAnimation() {
        confettiLayer.removeAllAnimations()
        confettiLayer.removeFromSuperlayer()
        confettiLayer.emitterCells = nil
    }
    
    private func resetGameViewController() {
        navigationController?.isNavigationBarHidden = false
        stopConfettiAnimation()
        mainViewHeightConstraint.constant = ViewControllerConstants.mainViewHeight
        gameStory.reset()
    }
    
    // TODO: Call it from share button
    private func shareBackgroundImage() {
        let appIDString = AppConstants.Meta.appId

        guard let backgroundImageData = gameShareView?.asImage().pngData() else {
            // TODO: Handle the case where the image couldn't be loaded (e.g., show an alert)
            print("Error: Failed to load background image")
            return
        }

        shareOnInstagramStories(backgroundImage: backgroundImageData, appID: appIDString)
    }
    
    private func shareOnInstagramStories(backgroundImage: Data, appID: String) {
        let urlSchemeString = "\(ViewControllerConstants.instagramStoriesURLScheme)\(appID)"
        
        guard let urlScheme = URL(string: urlSchemeString) else {
            // TODO: Handle invalid URL (e.g., log an error)
            print("Error: Invalid Instagram Stories URL scheme")
            return
        }

        if UIApplication.shared.canOpenURL(urlScheme) {
            var pasteboardItems: [String: Any] = ViewControllerConstants.shareImageBackgroundColors
            pasteboardItems[ViewControllerConstants.PasteboardKeys.stickerImage] = backgroundImage

            let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
                .expirationDate: Date().addingTimeInterval(60 * 5)
            ]

            UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
            UIApplication.shared.open(urlScheme)
        } else {
            // TODO: handle
            print("Error: Instagram Stories is not installed")
        }
    }
}

// MARK: - GameInfoViewDelegate Methods
extension GameViewController: GameInfoViewDelegate {
    func didPressStart() {
        toggleGameView()
    }
    
    func didPressShowScoreboard() {
        coordinator?.presentGameScoreboard()
    }
}

// MARK: - GamePlayViewDelegate Methods
extension GameViewController: GamePlayViewDelegate {
    func timerDidFinished(roundScore: Int) {
        guard let viewModel else { return }
        viewModel.updateGameInfo(with: roundScore)
        toggleGameView()
    }
}

// MARK: - GameOverDelegate Methods
extension GameViewController: GameOverViewDelegate {
    func didPressStartOver() {
        handleActionWithInterstitial { [weak self] in
            guard let self else { return }
            self.resetGameViewController()
            self.toggleGameView()
        }
    }
    
    func didPressGoBack() {
        handleActionWithInterstitial { [weak self] in
            guard let self else { return }
            self.stopConfettiAnimation()
            self.coordinator?.pop()
        }
    }
    
    func handleActionWithInterstitial(action: @escaping () -> Void) {
        guard let interstitial = interstitial else {
            print("Ad wasn't ready.")
            action()
            return
        }

        actionAfterAdDismissal = action
        interstitial.present(fromRootViewController: nil)
    }
    
    func didPressShowFullScoreboard() {
        coordinator?.presentGameScoreboard(with: [.large()])
    }
}

// MARK: - GADFullScreenContentDelegate
extension GameViewController: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        actionAfterAdDismissal?()
        actionAfterAdDismissal = nil
        setupAndLoadInterstitialAdUnit()
    }
}

// MARK: - ViewController Constants
extension GameViewController {
    enum ViewControllerConstants {
        
        enum PasteboardKeys {
            static let stickerImage = "com.instagram.sharedSticker.stickerImage"
            static let backgroundTopColor = "com.instagram.sharedSticker.backgroundTopColor"
            static let backgroundBottomColor = "com.instagram.sharedSticker.backgroundBottomColor"
        }
        
        static let mainViewHeight: CGFloat = 400
        static let mainViewHeightForGameOverView: CGFloat = 600
        static let gameOverViewTransitionDuration: TimeInterval = 0.5
        static let cellScale: CGFloat = 0.5
        static let cellScaleRange: CGFloat = 0.1
        static let cellLifetime: Float = 30
        static let cellBirthRate: Float = 5
        static let cellVelocity: CGFloat = 250
        static let cellVelocityRange: CGFloat = 150
        static let cellSpin: CGFloat = 5
        static let cellSpinRange: CGFloat = 2.5
        static let birthRateStartFromValue: Float = 1
        static let birthRateStartToValue: Float = 200
        static let birthRateStartDuration: CFTimeInterval = 5
        static let birthRateAnimation: String = "birthRate"
        static let birthRateAnimationKey: String = "birthRateAnimation"
        static let confettiColors: [UIColor] = [
            Asset.color1.color,
            Asset.color2.color,
            Asset.color3.color,
            Asset.color4.color,
            Asset.color5.color,
            Asset.color6.color,
            Asset.color7.color,
            Asset.color8.color,
            Asset.color9.color,
            Asset.color10.color
        ]
        static let instagramStoriesURLScheme = "instagram-stories://share?source_application="
        static let shareImageBackgroundColors: [String: Any] = [
            PasteboardKeys.backgroundTopColor: "#4D2E8D",
            PasteboardKeys.backgroundBottomColor: "#001242"
        ]
    }
}
