//
//  AddWordCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class AddWordCoordinator: BaseCoordinator, ObservableObject {
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        super.init()
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let addWordView = AddWordView()
            .environmentObject(self)
        
        let hostingController = AddWordHostingController(rootView: addWordView)
        hostingController.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.present(hostingController, animated: true)
    }
}

final class AddWordHostingController<Content>: UIHostingController<Content> where Content: View {

}
