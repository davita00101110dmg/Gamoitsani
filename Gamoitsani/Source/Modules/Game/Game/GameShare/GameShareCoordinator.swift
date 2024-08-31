//
//  GameShareCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 27/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class GameShareCoordinator: BaseCoordinator, ObservableObject {
    private var image: UIImage = UIImage()
    
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController, image: UIImage) {
        super.init()
        self.image = image
        self.navigationController = navigationController
    }
    
    override func start() {
        guard let navigationController else { return }
        let gameShareView = GameShareView(viewModel: GameShareViewModel(),
                                          image: image)
            .environmentObject(self)
        
        let hostingController = GameShareHostingController(rootView: gameShareView)
        hostingController.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.present(hostingController, animated: true)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true)
    }
}

final class GameShareHostingController<Content>: UIHostingController<Content> where Content: View {

    override func viewDidLoad() {
        super.viewDidLoad()
        lockOrientation(.portrait, andRotateTo: .portrait)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lockOrientation(.allButUpsideDown)
    }
}
