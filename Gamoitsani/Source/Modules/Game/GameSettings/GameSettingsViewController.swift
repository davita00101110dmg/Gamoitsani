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
    @IBOutlet weak var teamsStepper: UIStepper!
    @IBOutlet weak var startGameButton: GMButton!
    
    @IBOutlet weak var tableView: GMTableView!
    
    var viewModel: GameSettingsViewModel?
    
    private var snapshot: GameSettingsSnapshot?
    
    private lazy var dataSource = GameSettingsDataSource(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
        guard let self else { return.init() }
        
        switch itemIdentifier {
        case .teams(let model, _):
            let cell: GameSettingsTeamTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(with: model)
            return cell
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func setupUI() {
        super.setupUI()
        tableView.backgroundColor = Asset.secondary.color
        tableView.layer.cornerRadius = 8
        tableView.showsVerticalScrollIndicator = false
        roundsStepper.minimumValue = 0
        roundsStepper.maximumValue = 5
        roundsStepper.value = 1
        roundsStepper.stepValue = 1
        roundsLengthStepper.minimumValue = 15
        roundsLengthStepper.maximumValue = 75
        roundsLengthStepper.value = 45
        roundsLengthStepper.stepValue = 5
        teamsStepper.value = 0
        teamsStepper.minimumValue = 0
        teamsStepper.maximumValue = 6
        teamsStepper.stepValue = 1
        [roundsAmountTitle, roundsLengthTitle, teamsTitle].forEach {
            $0.font = F.BPGNinoMtavruli.bold.font(size: 16)
            $0.textColor = Asset.tintColor.color
        }
        // TODO: Localization
        startGameButton.configure(text: "თამაშის დაწყება")
    }
    
    override func setupLocalizedTexts() {
        super.setupLocalizedTexts()
        title = L10n.Screen.GameSettings.title
        roundsAmountTitle.text = L10n.Screen.GameSettings.RoundsAmount.title(1.toString())
        roundsLengthTitle.text = L10n.Screen.GameSettings.RoundsLength.title(45.toString())
        teamsTitle.text = L10n.Screen.GameSettings.Teams.title
    }
    
    private func setupTableView() {
        tableView.register(GameSettingsTeamTableViewCell.self)
        tableView.delegate = self
    }
    
    private func configureDataSource() {
        viewModel?.teamsPublished
            .sink { teams in
                self.snapshot = GameSettingsSnapshot()
                self.snapshot?.appendSections([0])
                self.snapshot?.appendItems(teams)
                
                if let snapshot = self.snapshot {
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
            }.store(in: &subscribers)
    }
    
    @IBAction func roundsStepperAction(_ sender: UIStepper) {
        roundsAmountTitle.text = L10n.Screen.GameSettings.RoundsAmount.title(sender.value.toString())
    }
    
    @IBAction func roundsLengthStepperAction(_ sender: UIStepper) {
        roundsLengthTitle.text = L10n.Screen.GameSettings.RoundsLength.title(sender.value.toString())
    }
    
    // TODO: Add localization
    @IBAction func teamsStepper(_ sender: UIStepper) {
        if sender.value.toInt < viewModel?.getTeamsCount() ?? 0 {
            viewModel?.removeLastTeam()
        } else {
            let alert = UIAlertController(title: "დაამატე გუნდი!", message: "ჩაწერე გუნდის სახელი", preferredStyle: .alert)
            
            alert.addTextField()
            
            alert.addAction(.init(title: "დამატება", style: .default) { [weak self] _ in
                guard let self,
                      let textFields = alert.textFields,
                      let teamName = textFields[0].text else { return }
                
                self.viewModel?.addTeam(with: teamName)
            })
            
            alert.addAction(.init(title: "გაუქმება", style: .cancel) { [weak self] _ in
                guard let self else { return }
                teamsStepper.value -= 1
            })
            
            present(alert, animated: true)
        }
    }
    
    @IBAction func startGameAction(_ sender: Any) {
        let gameSettingsModel = GameSettingsModel(numberOfRounds: roundsStepper.value.toInt, lengthOfRound: roundsLengthStepper.value, words: [], teams: ["ხარება და გოგია": 0])
        coordinator?.navigateToGame(gameSettingsModel)
    }
}

// MARK: - UITableView Extensions
extension GameSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] action, _, completion in
            guard let self else { return }
            
            viewModel?.remove(at: indexPath.row)
            completion(true)
        }
    
        delete.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
