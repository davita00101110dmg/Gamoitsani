//
//  GameDetailsModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import SwiftUICore

typealias GameDetailsSnapshot = NSDiffableDataSourceSnapshot<Int, GameDetailsTeam>

enum GameDetailsTeamSectionMode {
    case teams
    case players
    
    struct Collection {
        var teams: [GameDetailsTeam]
        var players: [GameDetailsPlayer]
        
        mutating func append(_ name: String, for mode: GameDetailsTeamSectionMode) {
            switch mode {
            case .teams:
                teams.append(.init(name: name))
            case .players:
                players.append(.init(name: name))
            }
        }
        
        mutating func update(at index: Int, with name: String, for mode: GameDetailsTeamSectionMode) -> Bool {
            guard isValidIndex(index, for: mode) else { return false }
            
            switch mode {
            case .teams:
                teams[index].name = name
            case .players:
                players[index].name = name
            }
            return true
        }
        
        mutating func remove(at index: Int, for mode: GameDetailsTeamSectionMode) -> Bool {
            guard isValidIndex(index, for: mode) else { return false }
            
            switch mode {
            case .teams:
                teams.remove(at: index)
            case .players:
                players.remove(at: index)
            }
            return true
        }
        
        private func isValidIndex(_ index: Int, for mode: GameDetailsTeamSectionMode) -> Bool {
            switch mode {
            case .teams:
                return teams.indices.contains(index)
            case .players:
                return players.indices.contains(index)
            }
        }
    }
}

struct GameDetailsTeam: Hashable {
    let id = UUID()
    var name: String
}

struct GameDetailsPlayer: Hashable {
    let id = UUID()
    var name: String
}

enum AlertType: Equatable {
    case add
    case edit(String, Int)
    case remove(String, Int)
    case info(String, String)
}

enum GameDetailsConstants {
    enum Game {
        static let defaultRoundsAmount: Double = 1
        static let defaultRoundLength: Double = 45
        static let roundsRange: ClosedRange<Double> = 1...5
        static let roundsLengthRange: ClosedRange<Double> = 15...75
        static let roundsLengthStep: Double = 5
        static let minimumTeams = 2
        static let maximumTeams = 5
        static let minimumPlayers = 2
        static let maximumPlayers = 10
        static let arcadeWordCount = 5  
    }
    
    enum Validation {
        static let maxTeamNameLength = 30
        static let maxPlayerNameLength = 15
    }
    
    enum Animation {
        static let addSpringResponse: Double = 0.5
        static let addSpringDamping: Double = 0.7
        static let updateSpringResponse: Double = 0.3
        static let updateSpringDamping: Double = 0.7
    }
    
    enum Layout {
        static let sectionSpacing: CGFloat = 24
        static let managementSpacing: CGFloat = 16
        static let bottomSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let dividerOpacity: Double = 0.2
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 16
        static let fontSize: CGFloat = 16
        static let addButtonPadding = EdgeInsets(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
    }
}
