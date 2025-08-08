//
//  GameCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import Combine

final class GameCoordinator: BaseCoordinator, ObservableObject {
    
    var navigationController: UINavigationController?
    
    var isRecordingEnabled: Bool {
        GameRecordingManager.shared.isRecordingEnabled
    }
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private var recordingCancellable: AnyCancellable?
    private var recordingButton: UIBarButtonItem?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
        setupRecordingObserver()
        impactFeedback.prepare()
    }
    
    deinit {
        recordingCancellable?.cancel()
    }
    
    override func start() {
        guard let navigationController else { return }
        let viewModel = GameViewModel()
        let gameView = GameView(viewModel: viewModel)
            .environmentObject(self)
        
        let hostingController = UIHostingController(rootView: gameView)
        hostingController.navigationItem.leftBarButtonItem = BackBarButtonItem(image: UIImage(systemName: AppConstants.SFSymbol.flagCheckeredTwoCrossed)!, style: .plain, target: self, action: #selector(presentGoBackAlert))
        
        recordingButton = createRecordingButton()
        hostingController.navigationItem.rightBarButtonItem = recordingButton
        
        hostingController.modalPresentationStyle = .fullScreen
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func createRecordingButton() -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: recordingButtonImage(),
            style: .plain,
            target: self,
            action: #selector(handleRecordingButtonTap)
        )
        
        return button
    }
    
    private func recordingButtonImage() -> UIImage? {
        let symbolConfiguration = UIImage.SymbolConfiguration(
            paletteColors: [isRecordingEnabled ? .gmRed : .white, .white, .white]
        )
        return UIImage(
            systemName: AppConstants.SFSymbol.personCropSquareBadgeVideo,
            withConfiguration: symbolConfiguration
        )
    }
    
    private func setupRecordingObserver() {
        recordingCancellable = GameRecordingManager.shared.$isRecordingEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRecordingButton()
            }
    }
    
    private func updateRecordingButton() {
        recordingButton?.image = recordingButtonImage()
        objectWillChange.send()
    }
    
    @objc private func handleRecordingButtonTap() {
        impactFeedback.impactOccurred()
        
        if GameRecordingManager.shared.isRecording {
            presentStopRecordingAlert()
        } else {
            GameRecordingManager.shared.setRecordingEnabled(true)
            GameRecordingManager.shared.startGameRecording()
        }
        
        impactFeedback.prepare()
    }
    
    private func presentStopRecordingAlert() {
        let alert = UIAlertController(
            title: L10n.Screen.GamePlay.Alert.StopRecording.title,
            message: L10n.Screen.GamePlay.Alert.StopRecording.message,
            preferredStyle: .alert
        )
        
        alert.addAction(.init(title: L10n.yesPolite, style: .destructive) { _ in
            GameRecordingManager.shared.stopGameRecording()
            GameRecordingManager.shared.setRecordingEnabled(false)
        })
        
        alert.addAction(.init(title: L10n.cancel, style: .cancel))
        
        navigationController?.present(alert, animated: true)
    }
    
    @objc func presentGoBackAlert() {
        let alert = UIAlertController(
            title: L10n.Screen.Game.ConfirmationAlert.title,
            message: L10n.Screen.Game.ConfirmationAlert.message,
            preferredStyle: .alert)
        
        alert.addAction(.init(title: L10n.yesPolite, style: .destructive) { [weak self] _ in
            self?.pop()
        })
        
        alert.addAction(.init(title: L10n.no, style: .cancel))

        navigationController?.present(alert, animated: true)
    }
    
    func pop() {
        guard let navigationController else { return }
        navigationController.popViewController(animated: true)
    }
    
    func presentGameScoreboard(with detents: [UISheetPresentationController.Detent] = [.large()]) {
        guard let navigationController else { return }
        
        let detentsToUse: [UISheetPresentationController.Detent] = GameStory.shared.isGameFinished
            ? [.large()]
            : [.medium()]
        
        let gameScoreboardCoordinator = GameScoreboardCoordinator(
            navigationController: navigationController,
            detents: detentsToUse
        )
        coordinate(to: gameScoreboardCoordinator)
    }
    
    func presentGameShareView(with image: UIImage) {
        guard let navigationController else { return }
        
        AnalyticsManager.shared.logGameResultsShared()
        
        let coordinator = GameShareCoordinator(navigationController: navigationController, image: image)
        coordinate(to: coordinator)
    }
}
