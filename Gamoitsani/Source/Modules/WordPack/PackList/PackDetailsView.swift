//
//  PackDetailsView.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

final class PackDetailsViewModel: ObservableObject {
    @Published var pack: WordPackFirebase
    @Published var selectedRating: Int = 0
    @Published var showRatingConfirmation = false

    weak var coordinator: WordPackCoordinator?

    init(pack: WordPackFirebase) {
        self.pack = pack
    }

    func submitRating() {
        guard selectedRating > 0 else { return }
        FirebaseManager.shared.rateWordPack(packId: pack.id, rating: selectedRating) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.showRatingConfirmation = true
                }
            }
        }
    }

    func downloadPack() {
        FirebaseManager.shared.incrementPackDownloadCount(packId: pack.id) { success in
            if success {
                log(.info, "Pack downloaded: \(self.pack.id)")
            }
        }
    }
}

struct PackDetailsView: View {

    @ObservedObject var viewModel: PackDetailsViewModel

    var body: some View {
        ZStack {
            Asset.gmPrimary.swiftUIColor
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Pack Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(viewModel.pack.packName)
                                .font(.appFont(type: .bold, size: 28))
                                .foregroundColor(.white)

                            Spacer()

                            if viewModel.pack.isFeatured {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 24))
                            }
                        }

                        Text(viewModel.pack.description)
                            .font(.appFont(type: .regular, size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Stats Row
                    HStack(spacing: 20) {
                        statItem(icon: "doc.text", value: "\(viewModel.pack.wordCount)", label: "Words")
                        statItem(icon: "arrow.down.circle", value: "\(viewModel.pack.downloadCount)", label: "Downloads")
                        statItem(icon: "play.circle", value: "\(viewModel.pack.playCount)", label: "Plays")

                        if viewModel.pack.ratingStats.totalRatings > 0 {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", viewModel.pack.ratingStats.averageRating))
                                        .font(.appFont(type: .bold, size: 18))
                                        .foregroundColor(.white)
                                }
                                Text("\(viewModel.pack.ratingStats.totalRatings) ratings")
                                    .font(.appFont(type: .regular, size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Languages
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Languages")
                            .font(.appFont(type: .semiBold, size: 16))
                            .foregroundColor(.white)

                        HStack {
                            ForEach(viewModel.pack.languages, id: \.self) { lang in
                                Text(lang.uppercased())
                                    .font(.appFont(type: .regular, size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Asset.gmSecondary.swiftUIColor.opacity(0.5))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Words Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Words Preview")
                            .font(.appFont(type: .semiBold, size: 16))
                            .foregroundColor(.white)

                        ForEach(Array(viewModel.pack.words.prefix(10)), id: \.id) { word in
                            wordPreviewRow(word)
                        }

                        if viewModel.pack.words.count > 10 {
                            Text("+ \(viewModel.pack.words.count - 10) more words")
                                .font(.appFont(type: .regular, size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 4)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Rating Section
                    if viewModel.pack.status == .approved {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rate This Pack")
                                .font(.appFont(type: .semiBold, size: 16))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { rating in
                                    Image(systemName: viewModel.selectedRating >= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 32))
                                        .onTapGesture {
                                            viewModel.selectedRating = rating
                                        }
                                }
                            }

                            if viewModel.selectedRating > 0 {
                                GMButtonView(
                                    text: "Submit Rating",
                                    backgroundColor: Asset.gmSecondary.swiftUIColor
                                ) {
                                    viewModel.submitRating()
                                }
                            }
                        }
                    }

                    // Download Button
                    GMButtonView(
                        text: "Download & Use Pack",
                        backgroundColor: Asset.gmSecondary.swiftUIColor
                    ) {
                        viewModel.downloadPack()
                    }
                }
                .padding()
            }
        }
        .alert("Thank You!", isPresented: $viewModel.showRatingConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your rating has been submitted!")
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(value)
                    .font(.appFont(type: .bold, size: 18))
            }
            .foregroundColor(.white)

            Text(label)
                .font(.appFont(type: .regular, size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private func wordPreviewRow(_ word: PackWord) -> some View {
        HStack {
            Text(word.baseWord)
                .font(.appFont(type: .regular, size: 16))
                .foregroundColor(.white)

            Spacer()

            // Show first translation as example
            if let firstTranslation = word.translations.first?.value.word {
                Text(firstTranslation)
                    .font(.appFont(type: .regular, size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Asset.gmSecondary.swiftUIColor.opacity(0.2))
        .cornerRadius(8)
    }
}
