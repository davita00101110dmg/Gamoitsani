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
    @Environment(Haptics.self) private var haptics
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var localization = l10n
        @Bindable var sound = sound
        @Bindable var haptics = haptics

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                SetupPanel(title: l10n("settings.sound")) {
                    toggle(l10n("settings.sound.effects"), isOn: $sound.isEnabled)
                    Divider().overlay(Tokens.cardEdge.color)
                    toggle(l10n("settings.haptics"), isOn: $haptics.isEnabled)
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
                                    // A flag emoji is announced by name, which is noise
                                    // before the language it sits beside.
                                    .accessibilityHidden(true)

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
                                        .accessibilityHidden(true)
                                }
                            }
                            .padding(.vertical, Spacing.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(
                            l10n.language == language ? [.isButton, .isSelected] : .isButton
                        )
                        .haptics(.selection, trigger: l10n.language)

                        if index < AppLanguage.allCases.count - 1 {
                            Divider().overlay(Tokens.cardEdge.color)
                        }
                    }
                }

                SetupPanel(title: l10n("settings.support")) {
                    // A deliberate tap deserves the review sheet, not a prompt iOS may
                    // decide to swallow.
                    link(l10n("settings.rate"), symbol: "star") { openURL(AppInfo.writeReview) }

                    Divider().overlay(Tokens.cardEdge.color)

                    ShareLink(item: AppInfo.appStore) {
                        row(l10n("settings.share"), symbol: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)

                    if let feedback = AppInfo.feedback {
                        Divider().overlay(Tokens.cardEdge.color)
                        link(l10n("settings.feedback"), symbol: "envelope") { openURL(feedback) }
                    }
                }

                SetupPanel(title: l10n("settings.about")) {
                    value(l10n("settings.version"), AppInfo.version)
                    Divider().overlay(Tokens.cardEdge.color)
                    value(l10n("settings.build"), AppInfo.build)
                }
            }
            .padding(Spacing.md)
        }
        .background(Tokens.surface.color.ignoresSafeArea())
        .navigationTitle(l10n("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(Tokens.accent.color)
            .font(Typography.rowTitle)
            .foregroundStyle(Tokens.onSurface.color)
            .padding(.vertical, Spacing.sm)
    }

    private func value(_ title: String, _ detail: String) -> some View {
        HStack {
            Text(title)
                .font(Typography.rowTitle)
                .foregroundStyle(Tokens.onSurface.color)
            Spacer()
            Text(detail)
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private func link(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { row(title, symbol: symbol) }
            .buttonStyle(.plain)
    }

    private func row(_ title: String, symbol: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Tokens.accent.color)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(Typography.rowTitle)
                .foregroundStyle(Tokens.onSurface.color)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Tokens.onSurfaceMuted.color)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }
}
