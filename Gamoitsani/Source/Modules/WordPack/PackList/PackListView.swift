//
//  PackListView.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PackListView: View {

    @ObservedObject var viewModel: PackListViewModel

    var body: some View {
        ZStack {
            Asset.gmPrimary.swiftUIColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab Picker
                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(PackTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Search & Sort (only for Discover tab)
                if viewModel.selectedTab == .discover {
                    HStack {
                        GMTextFieldView(
                            text: $viewModel.searchText,
                            placeholder: "Search packs...",
                            fontSizeForPhone: 16,
                            fontSizeForPad: 20
                        )

                        Menu {
                            ForEach(PackSortOption.allCases, id: \.self) { option in
                                Button(option.rawValue) {
                                    viewModel.sortOption = option
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Content
                if viewModel.isLoading && allPacksEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            switch viewModel.selectedTab {
                            case .myPacks:
                                myPacksSection
                            case .featured:
                                featuredPacksSection
                            case .discover:
                                discoverPacksSection
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .alert("Info", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - My Packs Section

    private var myPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Packs")
                    .font(.appFont(type: .bold, size: 24))
                    .foregroundColor(.white)

                Spacer()

                GMButtonView(
                    text: "+ Create",
                    fontSizeForPhone: 14,
                    fontSizeForPad: 18,
                    backgroundColor: Asset.gmSecondary.swiftUIColor,
                    height: 36
                ) {
                    viewModel.createNewPack()
                }
                .frame(width: 100)
            }

            if viewModel.myPacks.isEmpty {
                emptyStateView(message: "You haven't created any packs yet")
            } else {
                ForEach(viewModel.myPacks) { pack in
                    PackCardView(
                        pack: pack,
                        showActions: true,
                        onTap: { viewModel.viewPackDetails(pack) },
                        onEdit: { viewModel.editPack(pack) },
                        onDelete: { viewModel.deletePack(pack) },
                        onShare: { viewModel.sharePack(pack) }
                    )
                }
            }
        }
    }

    // MARK: - Featured Packs Section

    private var featuredPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Packs")
                .font(.appFont(type: .bold, size: 24))
                .foregroundColor(.white)

            if viewModel.featuredPacks.isEmpty {
                emptyStateView(message: "No featured packs available")
            } else {
                ForEach(viewModel.featuredPacks) { pack in
                    PackCardView(
                        pack: pack,
                        showActions: false,
                        onTap: { viewModel.viewPackDetails(pack) },
                        onDownload: { viewModel.downloadPack(pack) },
                        onRate: { rating in viewModel.ratePack(pack, rating: rating) }
                    )
                }
            }
        }
    }

    // MARK: - Discover Packs Section

    private var discoverPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Packs")
                .font(.appFont(type: .bold, size: 24))
                .foregroundColor(.white)

            if viewModel.publicPacks.isEmpty {
                emptyStateView(message: "No packs found")
            } else {
                ForEach(viewModel.publicPacks) { pack in
                    PackCardView(
                        pack: pack,
                        showActions: false,
                        onTap: { viewModel.viewPackDetails(pack) },
                        onDownload: { viewModel.downloadPack(pack) },
                        onRate: { rating in viewModel.ratePack(pack, rating: rating) },
                        onReport: { viewModel.reportPack(pack) }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text(message)
                .font(.appFont(type: .regular, size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var allPacksEmpty: Bool {
        viewModel.myPacks.isEmpty && viewModel.featuredPacks.isEmpty && viewModel.publicPacks.isEmpty
    }
}

// MARK: - Pack Card View

struct PackCardView: View {

    let pack: WordPackFirebase
    let showActions: Bool
    let onTap: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onDownload: (() -> Void)? = nil
    var onRate: ((Int) -> Void)? = nil
    var onReport: (() -> Void)? = nil

    @State private var showDeleteConfirmation = false
    @State private var showReportConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.packName)
                        .font(.appFont(type: .bold, size: 18))
                        .foregroundColor(.white)

                    Text(pack.description)
                        .font(.appFont(type: .regular, size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }

                Spacer()

                if pack.isFeatured {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                }
            }

            // Stats
            HStack(spacing: 16) {
                Label("\(pack.wordCount)", systemImage: "doc.text")
                Label("\(pack.downloadCount)", systemImage: "arrow.down.circle")

                if pack.ratingStats.totalRatings > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", pack.ratingStats.averageRating))
                    }
                }

                Spacer()

                if !pack.isPublic {
                    Label("Private", systemImage: "lock.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                } else if pack.status == .pendingReview {
                    Label("Pending", systemImage: "clock")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .font(.appFont(type: .regular, size: 12))
            .foregroundColor(.white.opacity(0.8))

            // Actions
            if showActions {
                HStack(spacing: 8) {
                    smallButton("Edit", icon: "pencil") {
                        onEdit?()
                    }

                    smallButton("Share", icon: "square.and.arrow.up") {
                        onShare?()
                    }

                    Spacer()

                    smallButton("Delete", icon: "trash", color: .red) {
                        showDeleteConfirmation = true
                    }
                }
                .padding(.top, 4)
            } else {
                HStack(spacing: 8) {
                    if let onDownload = onDownload {
                        smallButton("Download", icon: "arrow.down.circle") {
                            onDownload()
                        }
                    }

                    if let onReport = onReport {
                        Spacer()

                        smallButton("Report", icon: "exclamationmark.triangle", color: .red) {
                            showReportConfirmation = true
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Asset.gmSecondary.swiftUIColor.opacity(0.3))
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
        .confirmationDialog("Delete Pack?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog("Report Pack?", isPresented: $showReportConfirmation) {
            Button("Report", role: .destructive) {
                onReport?()
            }
        } message: {
            Text("This will flag the pack for review.")
        }
    }

    private func smallButton(_ text: String, icon: String, color: Color = .white) -> some View {
        Button {
            // Action handled in the modifier
        } label: {
            Label(text, systemImage: icon)
                .font(.appFont(type: .semiBold, size: 12))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func smallButton(_ text: String, icon: String, color: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(text, systemImage: icon)
                .font(.appFont(type: .semiBold, size: 12))
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
        }
    }
}
