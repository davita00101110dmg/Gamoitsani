//
//  PackListViewModel.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class PackListViewModel: ObservableObject {

    @Published var myPacks: [WordPackFirebase] = []
    @Published var featuredPacks: [WordPackFirebase] = []
    @Published var publicPacks: [WordPackFirebase] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedTab: PackTab = .myPacks
    @Published var sortOption: PackSortOption = .mostDownloaded
    @Published var showError = false
    @Published var errorMessage = ""

    weak var coordinator: WordPackCoordinator?
    private let firebaseManager = FirebaseManager.shared
    private let deviceId = DeviceIDManager.shared.deviceID
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSearchDebounce()
        loadPacks()
    }

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if !query.isEmpty {
                    self.searchPacks(query: query)
                } else {
                    self.loadPublicPacks()
                }
            }
            .store(in: &cancellables)

        $sortOption
            .dropFirst()
            .sink { [weak self] _ in
                self?.loadPublicPacks()
            }
            .store(in: &cancellables)
    }

    func loadPacks() {
        isLoading = true
        loadMyPacks()
        loadFeaturedPacks()
        loadPublicPacks()
    }

    private func loadMyPacks() {
        firebaseManager.fetchUserPacks(deviceId: deviceId) { [weak self] packs in
            DispatchQueue.main.async {
                self?.myPacks = packs
                self?.checkLoadingState()
            }
        }
    }

    private func loadFeaturedPacks() {
        firebaseManager.fetchFeaturedPacks { [weak self] packs in
            DispatchQueue.main.async {
                self?.featuredPacks = packs
                self?.checkLoadingState()
            }
        }
    }

    private func loadPublicPacks() {
        firebaseManager.fetchPublicPacks(sortBy: sortOption) { [weak self] packs in
            DispatchQueue.main.async {
                self?.publicPacks = packs
                self?.checkLoadingState()
            }
        }
    }

    private func searchPacks(query: String) {
        isLoading = true
        firebaseManager.searchPacks(query: query) { [weak self] packs in
            DispatchQueue.main.async {
                self?.publicPacks = packs
                self?.isLoading = false
            }
        }
    }

    private func checkLoadingState() {
        // Only stop loading when at least one category has loaded
        if !myPacks.isEmpty || !featuredPacks.isEmpty || !publicPacks.isEmpty {
            isLoading = false
        }
    }

    func createNewPack() {
        coordinator?.navigateToPackCreator()
    }

    func editPack(_ pack: WordPackFirebase) {
        coordinator?.navigateToPackCreator(packToEdit: pack)
    }

    func viewPackDetails(_ pack: WordPackFirebase) {
        coordinator?.navigateToPackDetails(pack)
    }

    func deletePack(_ pack: WordPackFirebase) {
        firebaseManager.deleteWordPack(packId: pack.id) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.myPacks.removeAll { $0.id == pack.id }
                }
            } else {
                DispatchQueue.main.async {
                    self?.showError(message: "Failed to delete pack")
                }
            }
        }
    }

    func sharePack(_ pack: WordPackFirebase) {
        AnalyticsManager.shared.logPackShared(packId: pack.id)
        coordinator?.showShareSheet(for: pack)
    }

    func downloadPack(_ pack: WordPackFirebase) {
        firebaseManager.incrementPackDownloadCount(packId: pack.id) { [weak self] success in
            if success {
                AnalyticsManager.shared.logPackDownloaded(packId: pack.id, packName: pack.packName)
                DispatchQueue.main.async {
                    self?.showError(message: "Pack downloaded! You can now use it in games.")
                }
                // TODO: Save pack locally for offline use
            }
        }
    }

    func ratePack(_ pack: WordPackFirebase, rating: Int) {
        firebaseManager.rateWordPack(packId: pack.id, rating: rating) { [weak self] success in
            if success {
                AnalyticsManager.shared.logPackRated(packId: pack.id, rating: rating)
                DispatchQueue.main.async {
                    self?.showError(message: "Thank you for rating!")
                    self?.loadPublicPacks() // Refresh to show updated rating
                }
            } else {
                DispatchQueue.main.async {
                    self?.showError(message: "Failed to submit rating")
                }
            }
        }
    }

    func reportPack(_ pack: WordPackFirebase) {
        firebaseManager.reportWordPack(packId: pack.id) { [weak self] success in
            if success {
                AnalyticsManager.shared.logPackReported(packId: pack.id)
                DispatchQueue.main.async {
                    self?.showError(message: "Pack reported. Thank you for keeping the community safe.")
                }
            } else {
                DispatchQueue.main.async {
                    self?.showError(message: "Failed to report pack")
                }
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - PackTab

enum PackTab: String, CaseIterable {
    case myPacks = "My Packs"
    case featured = "Featured"
    case discover = "Discover"
}
