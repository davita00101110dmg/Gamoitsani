//
//  SettingsView.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// Settings.
struct SettingsView: View {
    @Environment(Localization.self) private var l10n
    @Environment(SoundPlayer.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var localization = l10n
        @Bindable var sound = sound

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SetupPanel(title: l10n("settings.sound")) {
                    Toggle(l10n("settings.sound.effects"), isOn: $sound.isEnabled)
                        .tint(Tokens.accent.color)
                        .font(Typography.rowTitle)
                        .foregroundStyle(Tokens.onSurface.color)
                        .padding(.vertical, Spacing.sm)
                }

                SetupPanel(title: l10n("settings.language")) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { index, language in
                        Button {
                            withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                                localization.language = language
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(language.flag)
                                    .font(.title3)

                                // The endonym: someone looking for Georgian is looking
                                // for "ქართული", not for "Georgian".
                                Text(language.endonym)
                                    .font(Typography.rowTitle)
                                    .foregroundStyle(Tokens.onSurface.color)

                                Spacer()

                                if l10n.language == language {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Tokens.accent.color)
                                }
                            }
                            .padding(.vertical, Spacing.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: l10n.language)

                        if index < AppLanguage.allCases.count - 1 {
                            Divider().overlay(Tokens.cardEdge.color)
                        }
                    }
                }

                SetupPanel(title: l10n("settings.about")) {
                    HStack {
                        Text(l10n("settings.version"))
                            .font(Typography.rowTitle)
                            .foregroundStyle(Tokens.onSurface.color)
                        Spacer()
                        Text(Self.version)
                            .font(Typography.label)
                            .foregroundStyle(Tokens.onSurfaceMuted.color)
                    }
                    .padding(.vertical, Spacing.sm)
                }
            }
            .padding(Spacing.md)
        }
        .background(Tokens.surface.color.ignoresSafeArea())
        .navigationTitle(l10n("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}
