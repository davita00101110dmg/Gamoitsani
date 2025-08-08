//
//  GameDetailsCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import Combine

final class GameDetailsCoordinator: BaseCoordinator, ObservableObject {
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
        let gameDetailsView = GameDetailsView()
            .environmentObject(self)
        
        let hostingController = UIHostingController(rootView: gameDetailsView)
        hostingController.title = L10n.Screen.GameDetails.title
        
        recordingButton = createRecordingButton()
        hostingController.navigationItem.rightBarButtonItem = recordingButton
        
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    private func createRecordingButton() -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: recordingButtonImage(),
            style: .plain,
            target: self,
            action: #selector(toggleRecordingWithFeedback)
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
    
    @objc private func toggleRecordingWithFeedback() {
        impactFeedback.impactOccurred()
        GameRecordingManager.shared.isRecordingEnabled.toggle()
        impactFeedback.prepare()
    }
    
    func navigateToGame() {
        guard let navigationController else { return }
        let gameCoordinator = GameCoordinator(navigationController: navigationController)
        coordinate(to: gameCoordinator)
    }
}
