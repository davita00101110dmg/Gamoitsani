//
//  GameShareView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameShareView: UIView {
    @IBOutlet weak var topLabel: GMLabel!
    @IBOutlet weak var appNameLabel: GMLabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var snapshot: GameTeamsSnapshot?
    private lazy var dataSource = GameTeamsDataSource(tableView: tableView) { tableView, indexPath, team in
        let cell: GameScoreboardTeamTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: .init(name: team.name, score: team.score))
        return cell
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color.withAlphaComponent(Constants.backgroundColorAlpha)
        layer.cornerRadius = Constants.viewCornerRadius
        
        appNameLabel.configure(with: L10n.App.title, textAlignment: .left)
        
        tableView.backgroundColor = Asset.secondary.color
        tableView.layer.cornerRadius = Constants.tableViewCornerRadius
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 44
        tableView.register(GameScoreboardTeamTableViewCell.self)
    }
    
    func configure(with model: GameOverViewModel) {
        topLabel.configure(with: L10n.Screen.Game.GameShareView.title(model.teamName, model.score.toString),
                           fontType: .bold,
                           fontSizeForPhone: Constants.appNameLabelFontSizeForPhone)
        
        let teams: [GameTeamCellItem] = GameStory.shared.teams.sorted { $0.value > $1.value }.map { .init(name: $0.key, score: $0.value) }
        
        snapshot = GameTeamsSnapshot()
        snapshot?.appendSections([0])
        snapshot?.appendItems(teams)
        dataSource.defaultRowAnimation = .automatic
        
        if let snapshot {
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}

// MARK: - View Constants
extension GameShareView {
    enum Constants {
        static let appNameLabelFontSizeForPhone: CGFloat = 18
        static let appNameLabelFontSizeForPad: CGFloat = 36
        static let tableViewCornerRadius: CGFloat = 8
        static let backgroundColorAlpha: CGFloat = 0.3
        static let viewCornerRadius: CGFloat = 10
    }
}
