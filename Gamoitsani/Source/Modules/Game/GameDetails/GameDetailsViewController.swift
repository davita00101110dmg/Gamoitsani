//
//  GameDetailsViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import GoogleMobileAds

final class GameDetailsViewController: BaseViewController<GameDetailsCoordinator> {
    @IBOutlet weak var roundsAmountTitle: GMLabel!
    @IBOutlet weak var roundsStepper: UIStepper!
    @IBOutlet weak var roundsLengthTitle: GMLabel!
    @IBOutlet weak var roundsLengthStepper: UIStepper!
    @IBOutlet weak var teamsTitle: GMLabel!
    @IBOutlet weak var addTeamButton: GMButton!
    @IBOutlet weak var startGameButton: GMButton!
    @IBOutlet weak var tableView: GMTableView!
    @IBOutlet weak var bannerView: GADBannerView!
    
    private lazy var dataSource = GameDetailsDataSource(tableView: tableView) { [weak self] tableView, indexPath, team in
        guard let self else { return.init() }
        
        let cell: GameDetailsTeamTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: team.name)
        return cell
    }
    
    private var gameStory = GameStory.shared
    
    var viewModel: GameDetailsViewModel?
    
    override func viewDidLoad() {
        shouldUseCustomBackBarButtonItem = true
        super.viewDidLoad()
        viewModel?.delegate = self
        viewModel?.observeNetworkConnection()
        setupTableView()
        setupBannerView(with: bannerView)
#if DEBUG
        addMockedTeams()
#endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gameStory.reset()
        viewModel?.fetchWordsFromServer()
        presentAppReviewAlert()
    }
    
    override func setupUI() {
        super.setupUI()
        tableView.backgroundColor = Asset.secondary.color
        tableView.layer.cornerRadius = ViewControllerConstants.tableViewCornerRadius
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        roundsStepper.minimumValue = ViewControllerConstants.roundsStepperMinValue
        roundsStepper.maximumValue = ViewControllerConstants.roundsStepperMaxValue
        roundsStepper.value = ViewControllerConstants.roundsStepperDefaultValue
        roundsLengthStepper.minimumValue = ViewControllerConstants.roundsLengthStepperMinValue
        roundsLengthStepper.maximumValue = ViewControllerConstants.roundsLengthStepperMaxValue
        roundsLengthStepper.value = ViewControllerConstants.roundsLengthStepperDefaultValue
        roundsLengthStepper.stepValue = ViewControllerConstants.roundsLengthStepperStepValue
        
        addTeamButton.configure(with: L10n.add,
                                fontSizeForPhone: ViewControllerConstants.buttonTitleFontSizeForPhone)
        startGameButton.configure(with: L10n.Screen.GameDetails.StartGame.title)
    }
    
    override func setupLocalizedTexts() {
        super.setupLocalizedTexts()
        title = L10n.Screen.GameDetails.title
        roundsAmountTitle.configure(with: L10n.Screen.GameDetails.RoundsAmount.title(ViewControllerConstants.roundsStepperDefaultValue.toString()),
                                    textAlignment: .left)
        roundsLengthTitle.configure(with: L10n.Screen.GameDetails.RoundsLength.title(ViewControllerConstants.roundsLengthStepperDefaultValue.toString()),
                                    textAlignment: .left)
        teamsTitle.configure(with: L10n.Screen.GameDetails.Teams.title,
                             textAlignment: .left)
    }
    
    private func setupTableView() {
        tableView.register(GameDetailsTeamTableViewCell.self)
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.alwaysBounceVertical = true
    }
    
    private func presentAddTeamAlert() {
        let alertType = AlertType.addOrEditTeam(title: L10n.Screen.GameDetails.AddTeamAlert.title,
                                       message: nil,
                                       initialText: nil,
                                       delegate: self) { [weak self] teamName in
            guard let self,
                  let viewModel else { return }
            let teamName = teamName.removeExtraSpaces()
            if teamName == .empty {
                presentInvalidGameDetailsAlert(message: L10n.Screen.GameDetails.InvalidGameDetailsEmptyTeamName.message)
            } else {
                viewModel.addTeam(with: teamName.removeExtraSpaces())
            }
        }
        presentAlert(of: alertType)
    }
    
    private func presentUpdateTeamAlert(at index: Int) {
        guard let viewModel else { return }
        let initialText = viewModel.getTeam(at: index)
        
        let alertType = AlertType.addOrEditTeam(title: L10n.Screen.GameDetails.EditTeamNameAlert.title,
                                       message: nil,
                                       initialText: initialText,
                                       delegate: self) { teamName in
            viewModel.updateTeam(at: index, with: teamName)
        }
        presentAlert(of: alertType)
    }
    
    private func presentRemoveTeamAlert(at index: Int) {
        guard let viewModel else { return }
        
        let alertType = AlertType.deleteTeam(title: L10n.Screen.GameDetails.DeleteTeamAlert.title,
                                             message: nil) {
            viewModel.remove(at: index)
        }
        
        presentAlert(of: alertType)
    }
    
    private func presentInvalidGameDetailsAlert(title: String = L10n.Screen.GameDetails.InvalidParameter.title,
                                                   message: String) {
        let alertType = AlertType.info(title: title,
                                       message: message)
        presentAlert(of: alertType)
    }
    
    private func presentAppReviewAlert() {
        StoreReviewManager.checkAndAskForReview()
    }
    
    private func updateGameStory() {
        guard let viewModel else { return }
        
        gameStory.numberOfRounds = roundsStepper.value.toInt
        gameStory.lengthOfRound = roundsLengthStepper.value
        gameStory.teams = viewModel.getTeamsDictionary()
    }
    
    private func addMockedTeams() {
        viewModel?.addTeam(with: "Team 1")
        viewModel?.addTeam(with: "Team 2")
    }
}

// MARK: - Actions
extension GameDetailsViewController {
    @IBAction func roundsStepperAction(_ sender: UIStepper) {
        roundsAmountTitle.text = L10n.Screen.GameDetails.RoundsAmount.title(sender.value.toString())
    }
    
    @IBAction func roundsLengthStepperAction(_ sender: UIStepper) {
        roundsLengthTitle.text = L10n.Screen.GameDetails.RoundsLength.title(sender.value.toString())
    }
    
    @IBAction func addTeamAction(_ sender: Any) {
        if let viewModel, viewModel.getTeamsCount() < ViewControllerConstants.maximumNumberOfTeams {
            presentAddTeamAlert()
        } else {
            presentInvalidGameDetailsAlert(message: L10n.Screen.GameDetails.InvalidGameDetailsMaximumTeams.message)
        }
    }
    
    @IBAction func startGameAction(_ sender: Any) {
        guard let viewModel else { return }
        
        if viewModel.getTeamsCount() < ViewControllerConstants.minimumNumberOfTeams {
            presentInvalidGameDetailsAlert(message: L10n.Screen.GameDetails.InvalidGameDetailsNotEnoughTeams.message)
        } else if viewModel.teamsAreUnique() {
            presentInvalidGameDetailsAlert(message: L10n.Screen.GameDetails.InvalidGameDetailsNotUniqueTeams.message)
        } else {
            startGame()
        }
    }
    
    private func startGame() {
        updateGameStory()
        coordinator?.navigateToGame()
    }
}

// MARK: - GameDetailsViewModelDelegate Methods
extension GameDetailsViewController: GameDetailsViewModelDelegate {
    func applySnapshot(_ snapshot: GameDetailsSnapshot, animatingDifferences: Bool) {
        dataSource.defaultRowAnimation = .automatic
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

// MARK: - UITextFieldDelegate Methods
extension GameDetailsViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let currentText = textField.text,
            let range = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: range, with: string)
            return updatedText.count <= ViewControllerConstants.maximumCharactersOfTeamAlert
        }
        
        return true
    }
}

// MARK: - UITableView Delegate Methods
extension GameDetailsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive,
                                        title: nil) { [weak self] _, _, completion in
            guard let self,
                  let viewModel else { return }
            
            viewModel.remove(at: indexPath.row)
            completion(true)
        }
        
        let edit = UIContextualAction(style: .normal,
                                      title: nil) { [weak self] _, _, completion  in
            guard let self else { return }
            
            presentUpdateTeamAlert(at: indexPath.row)
            completion(true)
        }
        
        edit.image = UIImage(systemName: "square.and.pencil")
        edit.backgroundColor = .orange
        
        delete.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ -> UIMenu? in
            guard let self,
                  let viewModel else { return .init() }
            
            let editAction = UIAction(title: L10n.edit,
                                      image: UIImage(systemName: "square.and.pencil")) { _ in
                self.presentUpdateTeamAlert(at: indexPath.row)
            }
            
            let deleteAction = UIAction(title: L10n.delete,
                                        image: UIImage(systemName: "square.and.pencil"),
                                        attributes: .destructive) { _ in
                viewModel.remove(at: indexPath.row)
            }
            
            return UIMenu(title: .empty, children: [editAction, deleteAction])
        }
    }
}

// MARK: - UITableViewDragDelegate Delegate Methods
extension GameDetailsViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return [] }
        
        let itemProvider = NSItemProvider(object: item.id.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        
        let newOrder = dataSource.snapshot().itemIdentifiers
        
        viewModel?.updateOrder(with: newOrder)
    }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let param = UIDragPreviewParameters()
        param.backgroundColor = .clear
        return param
    }
}

// MARK: - UITableViewDropDelegate Delegate Methods
extension GameDetailsViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
    }
}

// MARK: - ViewController Constants
extension GameDetailsViewController {
    enum ViewControllerConstants {
        static let tableViewCornerRadius: CGFloat = 8
        static let roundsStepperMinValue: Double = 1
        static let roundsStepperMaxValue: Double = 5
        static let roundsStepperDefaultValue: Double = 1
        static let roundsLengthStepperMinValue: Double = 15
        static let roundsLengthStepperMaxValue: Double = 75
        static let roundsLengthStepperDefaultValue: Double = 45
        static let roundsLengthStepperStepValue: Double = 5
        static let buttonTitleFontSizeForPhone: CGFloat = 16
        static let minimumNumberOfTeams: Int = 2
        static let maximumNumberOfTeams: Int = 5
        static let maximumCharactersOfTeamAlert: Int = 20
    }
}
