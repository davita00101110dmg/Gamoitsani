//
//  SampleWords.swift
//  Gamoitsani2
//
import Foundation
import GamoitsaniCore

/// A small bilingual word list, enough to play several full games.
struct SampleWordProvider: WordProvider {

    func deck(language: String, count: Int) async throws -> Deck {
        let entries = SampleWords.all
        let words = entries.shuffled().prefix(count).map { entry in
            DeckWord(id: entry.id, text: entry.text(for: language))
        }
        return Deck(words: Array(words))
    }
}

enum SampleWords {

    struct Entry {
        let id: String
        let ka: String
        let en: String

        func text(for language: String) -> String {
            language == "ka" ? ka : en
        }
    }

    static let all: [Entry] = [
        .init(id: "1", ka: "ბროწეული", en: "pomegranate"),
        .init(id: "2", ka: "საზამთრო", en: "watermelon"),
        .init(id: "3", ka: "მთვარე", en: "moon"),
        .init(id: "4", ka: "მატარებელი", en: "train"),
        .init(id: "5", ka: "ბიბლიოთეკა", en: "library"),
        .init(id: "6", ka: "ქოლგა", en: "umbrella"),
        .init(id: "7", ka: "ზღვა", en: "sea"),
        .init(id: "8", ka: "კიბე", en: "ladder"),
        .init(id: "9", ka: "სარკე", en: "mirror"),
        .init(id: "10", ka: "თოვლი", en: "snow"),
        .init(id: "11", ka: "ვირთხა", en: "rat"),
        .init(id: "12", ka: "ღრუბელი", en: "cloud"),
        .init(id: "13", ka: "პიანინო", en: "piano"),
        .init(id: "14", ka: "მზარეული", en: "chef"),
        .init(id: "15", ka: "ველოსიპედი", en: "bicycle"),
        .init(id: "16", ka: "ციხე", en: "castle"),
        .init(id: "17", ka: "ხიდი", en: "bridge"),
        .init(id: "18", ka: "სათვალე", en: "glasses"),
        .init(id: "19", ka: "პეპელა", en: "butterfly"),
        .init(id: "20", ka: "ჩანთა", en: "backpack"),
        .init(id: "21", ka: "მაცივარი", en: "fridge"),
        .init(id: "22", ka: "გიტარა", en: "guitar"),
        .init(id: "23", ka: "ფოსტალიონი", en: "postman"),
        .init(id: "24", ka: "ვულკანი", en: "volcano"),
        .init(id: "25", ka: "თაფლი", en: "honey"),
        .init(id: "26", ka: "კუ", en: "turtle"),
        .init(id: "27", ka: "ტელესკოპი", en: "telescope"),
        .init(id: "28", ka: "ქარიშხალი", en: "storm"),
        .init(id: "29", ka: "ბალიში", en: "pillow"),
        .init(id: "30", ka: "მაისური", en: "t-shirt"),
        .init(id: "31", ka: "ნიანგი", en: "crocodile"),
        .init(id: "32", ka: "საათი", en: "clock"),
        .init(id: "33", ka: "ფანჯარა", en: "window"),
        .init(id: "34", ka: "კოცონი", en: "bonfire"),
        .init(id: "35", ka: "რუკა", en: "map"),
        .init(id: "36", ka: "ზარმაცი", en: "lazy"),
        .init(id: "37", ka: "სამზარეულო", en: "kitchen"),
        .init(id: "38", ka: "ფრინველი", en: "bird"),
        .init(id: "39", ka: "მოგზაურობა", en: "journey"),
        .init(id: "40", ka: "ბაღი", en: "garden"),
        .init(id: "41", ka: "ჩირაღდანი", en: "torch"),
        .init(id: "42", ka: "მელა", en: "fox"),
        .init(id: "43", ka: "სოკო", en: "mushroom"),
        .init(id: "44", ka: "კიბორჩხალა", en: "crab"),
        .init(id: "45", ka: "ქუდი", en: "hat"),
        .init(id: "46", ka: "ავტობუსი", en: "bus"),
        .init(id: "47", ka: "ბროლი", en: "crystal"),
        .init(id: "48", ka: "ლაბირინთი", en: "maze"),
        .init(id: "49", ka: "პინგვინი", en: "penguin"),
        .init(id: "50", ka: "ხმაური", en: "noise"),
        .init(id: "51", ka: "სასწაული", en: "miracle"),
        .init(id: "52", ka: "თოკი", en: "rope"),
        .init(id: "53", ka: "ბუხარი", en: "fireplace"),
        .init(id: "54", ka: "ჟოლო", en: "raspberry"),
        .init(id: "55", ka: "დელფინი", en: "dolphin"),
        .init(id: "56", ka: "ქარხანა", en: "factory"),
        .init(id: "57", ka: "ბუ", en: "owl"),
        .init(id: "58", ka: "მარილი", en: "salt"),
        .init(id: "59", ka: "სკამი", en: "chair"),
        .init(id: "60", ka: "ჯადოქარი", en: "wizard"),
    ]
}
