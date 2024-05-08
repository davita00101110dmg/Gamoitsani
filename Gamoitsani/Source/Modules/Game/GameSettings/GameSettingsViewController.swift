//
//  GameSettingsViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameSettingsViewController: BaseViewController<GameSettingsCoordinator> {
    
    @IBOutlet weak var roundsAmountTitle: UILabel!
    @IBOutlet weak var roundsStepper: UIStepper!
    @IBOutlet weak var roundsLengthTitle: UILabel!
    @IBOutlet weak var roundsLengthStepper: UIStepper!
    @IBOutlet weak var teamsTitle: UILabel!
    @IBOutlet weak var addTeamButton: GMButton!
    @IBOutlet weak var startGameButton: GMButton!
    @IBOutlet weak var tableView: GMTableView!
    
    private var snapshot: GameSettingsSnapshot?
    var viewModel: GameSettingsViewModel?
    
    private lazy var dataSource = GameSettingsDataSource(tableView: tableView) { [weak self] tableView, indexPath, team in
        guard let self else { return.init() }
        
        let cell: GameSettingsTeamTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: team.name)
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GameStory.shared.reset()
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
        
        addTeamButton.configure(text: L10n.add, fontSize: ViewControllerConstants.buttonTitleFontValue)
        startGameButton.configure(text: L10n.Screen.GameSettings.StartGame.title)
        
        [roundsAmountTitle, roundsLengthTitle, teamsTitle].forEach {
            $0.font = F.BPGNinoMtavruli.bold.font(size: ViewControllerConstants.buttonTitleFontValue)
            $0.textColor = Asset.tintColor.color
        }
    }
    
    override func setupLocalizedTexts() {
        super.setupLocalizedTexts()
        title = L10n.Screen.GameSettings.title
        roundsAmountTitle.text = L10n.Screen.GameSettings.RoundsAmount.title(ViewControllerConstants.roundsStepperDefaultValue.toString())
        roundsLengthTitle.text = L10n.Screen.GameSettings.RoundsLength.title(ViewControllerConstants.roundsLengthStepperDefaultValue.toString())
        teamsTitle.text = L10n.Screen.GameSettings.Teams.title
    }
    
    private func setupTableView() {
        tableView.register(GameSettingsTeamTableViewCell.self)
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        tableView.alwaysBounceVertical = true
    }
    
    private func configureDataSource() {
        viewModel?.teamsPublished
            .sink { [weak self] items in
                guard let self else { return }
                
                self.snapshot = GameSettingsSnapshot()
                self.snapshot?.appendSections([0])
                self.snapshot?.appendItems(items)
                self.dataSource.defaultRowAnimation = .automatic
                
                if let snapshot = self.snapshot {
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
                
            }.store(in: &subscribers)
    }
    
    private func presentAddTeamAlert() {
        let alertType = AlertType.team(title: L10n.Screen.GameSettings.AddTeamAlert.title,
                                       message: L10n.Screen.GameSettings.AddTeamAlert.message,
                                       initialText: nil,
                                       addActionTitle: L10n.addIt) { [weak self] teamName in
            guard let self,
                  let viewModel else { return }
            viewModel.addTeam(with: teamName.removeExtraSpaces())
        }
        presentAlert(of: alertType)
    }
    
    private func presentUpdateTeamAlert(at index: Int) {
        guard let viewModel else { return }
        let initialText = viewModel.getTeam(at: index)
        
        let alertType = AlertType.team(title: L10n.Screen.GameSettings.UpdateTeamNameAlert.title,
                                       message: nil,
                                       initialText: initialText,
                                       addActionTitle: L10n.change) { teamName in
            viewModel.updateTeam(at: index, with: teamName)
        }
        presentAlert(of: alertType)
    }
    
    private func presentIncorrectGameSettingsAlert(message: String) {
        let alertType = AlertType.info(title: L10n.Screen.GameSettings.IncorrectParameter.title,
                                       message: message)
        presentAlert(of: alertType)
    }
    
    private func updateGameStory() {
        guard let viewModel else { return }
        
        GameStory.shared.numberOfRounds = roundsStepper.value.toInt
        GameStory.shared.lengthOfRound = roundsLengthStepper.value
        GameStory.shared.words = AppConstants.randomWords // TODO: Should give real API words
        GameStory.shared.teams = viewModel.getTeamsDictionary()
        GameStory.shared.maxTotalSessions = roundsStepper.value.toInt * viewModel.getTeamsCount()
    }
}

// MARK: Actions
extension GameSettingsViewController {
    @IBAction func roundsStepperAction(_ sender: UIStepper) {
        roundsAmountTitle.text = L10n.Screen.GameSettings.RoundsAmount.title(sender.value.toString())
    }
    
    @IBAction func roundsLengthStepperAction(_ sender: UIStepper) {
        roundsLengthTitle.text = L10n.Screen.GameSettings.RoundsLength.title(sender.value.toString())
    }
    
    @IBAction func addTeamAction(_ sender: Any) {
        presentAddTeamAlert()
    }
    
    @IBAction func startGameAction(_ sender: Any) {
        guard let viewModel else { return }
        
        if viewModel.getTeamsCount() < 2 {
            presentIncorrectGameSettingsAlert(message: L10n.Screen.GameSettings.IncorrectGameSettingsNotEnoughTeams.message)
        } else if viewModel.teamsAreUnique() {
            presentIncorrectGameSettingsAlert(message: L10n.Screen.GameSettings.IncorrectGameSettingsNotUniqueTeams.message)
        } else {
            startGame()
        }
    }
    
    private func startGame() {
        updateGameStory()
        coordinator?.navigateToGame()
    }
}

// MARK: - UITableView Delegate Methods
extension GameSettingsViewController: UITableViewDelegate {
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
extension GameSettingsViewController: UITableViewDragDelegate {
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
}

// MARK: - UITableViewDropDelegate Delegate Methods
extension GameSettingsViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
    }
}

// MARK: - ViewController Constants
extension GameSettingsViewController {
    enum ViewControllerConstants {
        static let tableViewCornerRadius: CGFloat = 8
        static let roundsStepperMinValue: Double = 1
        static let roundsStepperMaxValue: Double = 5
        static let roundsStepperDefaultValue: Double = 1
        static let roundsLengthStepperMinValue: Double = 15
        static let roundsLengthStepperMaxValue: Double = 75
        static let roundsLengthStepperDefaultValue: Double = 45
        static let roundsLengthStepperStepValue: Double = 5
        static let buttonTitleFontValue: CGFloat = 16
    }
}
