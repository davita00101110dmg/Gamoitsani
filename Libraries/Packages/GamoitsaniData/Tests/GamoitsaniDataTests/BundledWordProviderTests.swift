//
//  BundledWordProviderTests.swift
//  GamoitsaniDataTests
//

import Testing
import Foundation
import GamoitsaniCore
@testable import GamoitsaniData

@Suite("Bundled word provider")
struct BundledWordProviderTests {

    /// Its own directory per case, so a test never reads or writes the real seen list.
    private func scratchSeenWords() -> SeenWords {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        return SeenWords(directory: directory)
    }

    // MARK: - Dealing

    @Test("a deck comes back full, unique, and playable")
    func dealsADeck() async throws {
        let deck = try await BundledWordProvider().deck(language: "ka", count: 375)
        #expect(deck.count == 375)

        let ids = deck.remainingIDs
        #expect(Set(ids).count == ids.count)
        // Ids must round-trip to Int, because that is how they are recorded as seen.
        #expect(ids.allSatisfy { Int($0) != nil })
    }

    @Test("a maximum-length game fits in every tier", arguments: WordDifficulty.allCases)
    func maximumGameFits(difficulty: WordDifficulty) async throws {
        // Five teams, five rounds, fifteen words a team-round — what startGame now asks for.
        let wanted = 5 * 5 * 15
        let provider = BundledWordProvider(difficulty: difficulty.range)
        let deck = try await provider.deck(language: "ka", count: wanted)
        #expect(deck.count == wanted)
    }

    @Test("the easy tier really is easier than the hard one")
    func tiersDiffer() async throws {
        let easy = try await BundledWordProvider(difficulty: WordDifficulty.easy.range)
            .deck(language: "ka", count: 300)
        let hard = try await BundledWordProvider(difficulty: WordDifficulty.hard.range)
            .deck(language: "ka", count: 300)

        #expect(Set(easy.remainingIDs).isDisjoint(with: Set(hard.remainingIDs)))
    }

    // MARK: - Language

    @Test("every offered language deals in its own words, not Georgian")
    func everyLanguageDealsItself() async throws {
        for language in ["ka", "en", "ru", "ja", "de", "tr"] {
            #expect(BundledWordProvider.resolvedLanguage(for: language) == language)
        }

        // Same word ids across files — they are the same source words — but different text.
        let english = try await BundledWordProvider().deck(language: "en", count: 30)
        let russian = try await BundledWordProvider().deck(language: "ru", count: 30)
        #expect(english.count == 30)
        #expect(russian.count == 30)
    }

    /// Only reachable for a code the app does not offer, now that all eleven ship a file.
    @Test("an unknown language falls back to Georgian rather than failing")
    func unknownLanguageFallsBack() async throws {
        #expect(BundledWordProvider.resolvedLanguage(for: "zz") == "ka")
        let deck = try await BundledWordProvider().deck(language: "zz", count: 20)
        #expect(deck.count == 20)
    }

    @Test("the difficulty selector is offered only where the data supports it")
    func difficultyAvailability() async {
        #expect(await BundledWordProvider.hasUsableDifficulty(language: "ka"))
        for language in ["en", "ru", "ja", "tr"] {
            #expect(await BundledWordProvider.hasUsableDifficulty(language: language) == false)
        }
    }

    // MARK: - Seen words

    @Test("words played before do not come back")
    func excludesSeen() async throws {
        let seen = scratchSeenWords()
        let first = try await BundledWordProvider(seen: seen).deck(language: "ka", count: 400)
        await seen.record(first.remainingIDs.compactMap(Int.init), language: "ka")

        let second = try await BundledWordProvider(seen: seen).deck(language: "ka", count: 400)
        #expect(second.count == 400)
        #expect(Set(second.remainingIDs).isDisjoint(with: Set(first.remainingIDs)))
    }

    /// Hard is the thinnest tier, so it is the one that would dead-end first if the list
    /// never reset. Sized off the real tier rather than a fixed number, since the database
    /// grows as review finishes.
    @Test("a pool worked through starts over rather than dealing a short deck")
    func clearsWhenExhausted() async throws {
        let seen = scratchSeenWords()
        let provider = BundledWordProvider(difficulty: WordDifficulty.hard.range, seen: seen)

        let whole = try await provider.deck(language: "ka", count: 100_000)
        let tier = whole.count

        // Leave fewer unseen words than a game needs, so the next draw has to reset.
        let wanted = tier / 2
        let alreadyPlayed = whole.remainingIDs.compactMap(Int.init).prefix(tier - wanted + 1)
        await seen.record(alreadyPlayed, language: "ka")
        #expect(await seen.ids(language: "ka").count == alreadyPlayed.count)

        let next = try await provider.deck(language: "ka", count: wanted)
        #expect(next.count == wanted)
        #expect(await seen.ids(language: "ka").isEmpty)
    }

    // MARK: - Topping up mid-game

    @Test("a top-up avoids the words already dealt into this game")
    func topUpAvoidsThisGame() async throws {
        let provider = BundledWordProvider()
        let opening = try await provider.deck(language: "ka", count: 200)
        let inPlay = Set(opening.remainingIDs.compactMap(Int.init))

        let more = try await provider.more(language: "ka", count: 100, excluding: inPlay)
        #expect(more.count == 100)
        #expect(Set(more.compactMap { Int($0.id) }).isDisjoint(with: inPlay))
    }

    /// A top-up is not a new game, so it must not wipe what earlier games have used.
    @Test("a top-up leaves the seen list alone")
    func topUpDoesNotResetSeen() async throws {
        let seen = scratchSeenWords()
        let provider = BundledWordProvider(difficulty: WordDifficulty.hard.range, seen: seen)

        let opening = try await provider.deck(language: "ka", count: 300)
        let inPlay = Set(opening.remainingIDs.compactMap(Int.init))
        await seen.record(inPlay, language: "ka")

        let more = try await provider.more(language: "ka", count: 100, excluding: inPlay)
        #expect(!more.isEmpty)
        #expect(await seen.ids(language: "ka").count == inPlay.count)
        #expect(Set(more.compactMap { Int($0.id) }).isDisjoint(with: inPlay))
    }

    @Test("a tier entirely in play has nothing left to give")
    func topUpOnExhaustedTier() async throws {
        let provider = BundledWordProvider(difficulty: WordDifficulty.hard.range)
        let everything = try await provider.deck(language: "ka", count: 100_000)

        let more = try await provider.more(
            language: "ka", count: 50,
            excluding: Set(everything.remainingIDs.compactMap(Int.init))
        )
        #expect(more.isEmpty)
    }

    @Test("the seen list is kept per language")
    func perLanguage() async throws {
        let seen = scratchSeenWords()
        await seen.record([1, 2, 3], language: "ka")
        #expect(await seen.ids(language: "ka") == [1, 2, 3])
        #expect(await seen.ids(language: "en").isEmpty)

        await seen.clear(language: "ka")
        #expect(await seen.ids(language: "ka").isEmpty)
    }

    @Test("the seen list survives being reopened")
    func persists() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        let seen = SeenWords(directory: directory)
        await seen.record([10, 20, 30], language: "ka")

        let reopened = SeenWords(directory: directory)
        #expect(await reopened.ids(language: "ka") == [10, 20, 30])
    }
}
