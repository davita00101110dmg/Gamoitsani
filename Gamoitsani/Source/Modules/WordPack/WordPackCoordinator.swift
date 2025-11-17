//
//  WordPackCoordinator.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import SwiftUI

final class WordPackCoordinator: Coordinator {

    var navigationController: UINavigationController
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        navigateToPackList()
    }

    func navigateToPackList() {
        let viewModel = PackListViewModel()
        viewModel.coordinator = self
        let view = PackListView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = "Word Packs"
        navigationController.pushViewController(hostingController, animated: true)
    }

    func navigateToPackCreator(packToEdit: WordPackFirebase? = nil) {
        let viewModel = PackCreatorViewModel(packToEdit: packToEdit)
        viewModel.coordinator = self
        let view = PackCreatorView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = packToEdit == nil ? "Create Pack" : "Edit Pack"
        navigationController.pushViewController(hostingController, animated: true)
    }

    func navigateToWordBrowser(onWordsSelected: @escaping ([Word]) -> Void) {
        let viewModel = WordBrowserViewModel(onWordsSelected: onWordsSelected)
        viewModel.coordinator = self
        let view = WordBrowserView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = "Browse Words"
        navigationController.pushViewController(hostingController, animated: true)
    }

    func navigateToPackDetails(_ pack: WordPackFirebase) {
        let viewModel = PackDetailsViewModel(pack: pack)
        viewModel.coordinator = self
        let view = PackDetailsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = pack.packName
        navigationController.pushViewController(hostingController, animated: true)
    }

    func popViewController() {
        navigationController.popViewController(animated: true)
    }

    func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func showShareSheet(for pack: WordPackFirebase) {
        let shareText = "Check out this word pack: \(pack.packName)\nPack ID: \(pack.id)\n\nDownload Gamoitsani: \(AppConstants.appStoreLink)"
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = navigationController.view
            popoverController.sourceRect = CGRect(
                x: navigationController.view.bounds.midX,
                y: navigationController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        navigationController.present(activityViewController, animated: true)
    }
}
