//
//  GameScoreboardViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameScoreboardViewController: BaseViewController<GameScoreboardCoordinator> {
    
    @IBOutlet weak var titleLabel: GMLabel!
    @IBOutlet weak var tableView: UITableView!
    
    private var snapshot: GameTeamsSnapshot?
    private lazy var dataSource = GameTeamsDataSource(tableView: tableView) { tableView, indexPath, team in
        let cell: GameScoreboardTeamTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: .init(name: team.name, score: team.score))
        return cell
    }
    
    var viewModel: GameScoreboardViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSwipeGestureRecogniser()
        setupTableView()
        configureDataSource()
        viewModel?.fetchTeams()
    }
    
    override func setupUI() {
        shouldApplyGradientBackground = false
        super.setupUI()
        titleLabel.configure(with: L10n.scoreboard, fontSizeForPhone: ViewControllerConstants.titleFontSize)
        
        view.backgroundColor = Asset.secondary.color
        tableView.backgroundColor = Asset.secondary.color
        tableView.layer.cornerRadius = ViewControllerConstants.tableViewCornerRadius
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func addSwipeGestureRecogniser() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
         
    private func setupTableView() {
        tableView.rowHeight = 44
        tableView.register(GameScoreboardTeamTableViewCell.self)
    }
    
    private func configureDataSource() {
        viewModel?.teamsPublished
            .sink { [weak self] teams in
                guard let self else { return }
                
                self.snapshot = GameTeamsSnapshot()
                self.snapshot?.appendSections([0])
                self.snapshot?.appendItems(teams)
                self.dataSource.defaultRowAnimation = .automatic
                
                if let snapshot {
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
            }.store(in: &subscribers)
    }
                                           
    @objc private func swipeAction() {
        coordinator?.dismiss()
    }
}

// MARK: - ViewController Constants
extension GameScoreboardViewController {
    enum ViewControllerConstants {
        static let titleFontSize: CGFloat = 20
        static let tableViewCornerRadius: CGFloat = 8
    }
}
