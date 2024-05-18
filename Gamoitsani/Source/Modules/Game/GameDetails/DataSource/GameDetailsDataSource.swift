//
//  GameDetailsDataSource.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameDetailsDataSource: UITableViewDiffableDataSource<Int, GameDetailsTeamCellItem> {
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let fromTeam = itemIdentifier(for: sourceIndexPath),
              sourceIndexPath != destinationIndexPath else { return }
        
        var snapshot = snapshot()
        snapshot.deleteItems([fromTeam])
        
        if let toTeam = itemIdentifier(for: destinationIndexPath) {
            let isAfter = destinationIndexPath.row > sourceIndexPath.row
            
            if isAfter {
                snapshot.insertItems([fromTeam], afterItem: toTeam)
            } else {
                snapshot.insertItems([fromTeam], beforeItem: toTeam)
            }
        } else {
            snapshot.appendItems([fromTeam], toSection: sourceIndexPath.section)
        }
        
        apply(snapshot, animatingDifferences: false)
    }
}
