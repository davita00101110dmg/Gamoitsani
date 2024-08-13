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
    @IBOutlet weak var icon: UIImageView!
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
        setupTableView()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color.withAlphaComponent(Constants.backgroundColorAlpha)
        layer.cornerRadius = Constants.viewCornerRadius
        
        appNameLabel.configure(with: L10n.App.title, textAlignment: .left)
        
        tableView.backgroundColor = Asset.secondary.color
        tableView.layer.cornerRadius = Constants.tableViewCornerRadius
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupTableView() {
        tableView.rowHeight = 44
        tableView.register(GameScoreboardTeamTableViewCell.self)
    }
    
    func configure(with model: GameOverViewModel) {
        topLabel.configure(with: "გამარჯვებული გუნდია: \(model.teamName) \(model.score) ქულით🥳")
        
        let teams: [GameTeamCellItem] = GameStory.shared.teams.map { .init(name: $0.key, score: $0.value) }
        
        self.snapshot = GameTeamsSnapshot()
        self.snapshot?.appendSections([0])
        self.snapshot?.appendItems(teams)
        self.dataSource.defaultRowAnimation = .automatic
        
        if let snapshot {
            self.dataSource.apply(snapshot, animatingDifferences: true)
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
