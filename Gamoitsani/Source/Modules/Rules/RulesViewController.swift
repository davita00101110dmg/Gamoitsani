//
//  RulesViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class RulesViewController: BaseViewController<RulesCoordinator> {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: RulesViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Screen.Rules.title
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RuleTableViewCell.self)
    }
}

// MARK: - UITableView Delegate and DataSource Methods
extension RulesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let viewModel {
            return viewModel.numberOfItems()
        }

        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else { return nil }
        let headerView = UIView()
        headerView.backgroundColor = UIColor.red
        return headerView
    }
     
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RuleTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        let rule = viewModel?.rule(at: indexPath.section)
        cell.configure(with: rule)
        return cell
    }
}
