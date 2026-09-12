# Accessibility — 2.0

What has been checked, what was fixed, and how to verify it by hand. The audit that
produced this ran over every SwiftUI file in `Gamoitsani` and `GamoitsaniDesign`.

## Where 2.0 already stood

Worth recording, because it means these are not open problems:

- **Dynamic Type works throughout.** Every bundled display font is declared
  `.custom(_:size:relativeTo:)` and every body style is a semantic text style, so text
  scales without a single fixed point size.
- **Reduce Motion is respected everywhere.** `Motion.card/control/celebrate` each take a
  `reduceMotion` flag and substitute a crossfade; 16 call sites read the environment.
- **The play screen is fully labelled** — answer buttons, arcade rows, the word card and
  the round timer all carry labels, values, traits and hints.
- **Nothing is tappable that is not a `Button`.** No `onTapGesture` anywhere, so Voice
  Control and Switch Control can reach every control.
- **Colour is never the only signal.** Selected states carry `.isSelected`; disabled
  controls are `.disabled`, not merely dimmed.

## What the audit changed

**The round and round-length steppers could not be adjusted the usual way.**
`StepperRow` combines into a single element, which puts its two buttons behind the
actions rotor — VoiceOver's swipe up and swipe down did nothing. Both settings are ones
every game touches. They now expose `accessibilityAdjustableAction`, which is how every
system stepper behaves.

**Four controls were below the 44pt minimum**, all drawn as 34pt circles: the two
steppers, discard and resume on the saved-game card, and the remove-ads dismiss. The last
mattered most — it sits beside a purchase target, so a missed tap bought something. The
glyphs are unchanged; the target around each is now 44pt, via `Sizing.minimumTarget`.

## Open, and deliberate

**The word card caps Dynamic Type at `accessibility1`** and allows
`minimumScaleFactor(0.4)`. A size that pushes the word off the card makes the game
unplayable, so the cap is a considered trade-off rather than an oversight — but a player
at `accessibility5` does not get the size they asked for. Worth revisiting if the card
can be made to grow instead.

The other seven `minimumScaleFactor` uses are correct and should stay: they wrap team
names typed by players and words drawn from a database in eleven languages, where
shrinking to fit is the behaviour, not a patch.

## Manual checks

Settings → Accessibility on a real device. The simulator does not model touch size.

### VoiceOver
1. Turn on VoiceOver. On setup, swipe to **Rounds**. It should read the label and the
   value together — "Rounds, 1".
2. **Swipe up and swipe down.** The value must change, with a haptic and the number
   animating. Repeat on **Length**. This is the fix; before it, nothing happened.
3. At the range ends the value should stop rather than wrap.
4. Swipe through the mode and difficulty options — each should announce as a button, and
   the chosen one as selected.
5. Start a game. The timer should read as a value, the word card should announce the word
   and whether it is a super word, and each answer button should announce what it is
   worth.

### Voice Control
6. Turn on Voice Control and say **"Show names"**. Every control should show a name, and
   it should match what is written on screen where there is visible text.
7. Say **"Tap Play"**, **"Tap Settings"**, and the name shown on the discard button.

### Switch Control
8. Turn on Switch Control and step through setup. Every control must be reachable,
   including the two stepper buttons and the saved-game card's actions.

### Touch targets
9. With Accessibility → Touch → **Touch Accommodations** off, tap the very edge of the
   stepper circles and the remove-ads dismiss. Each should activate from slightly outside
   the drawn circle.

### Dynamic Type
10. Set text to the largest accessibility size. Setup must stay usable — panels grow, no
    text is clipped, the Play button is still reachable.
11. Start a game at that size. The word must stay on the card. This is the one place that
    caps the range, so the word will not grow past `accessibility1`.

### Reduce Motion
12. Turn on Reduce Motion. Card deals, score bumps and the podium should crossfade rather
    than spring. Nothing should slide or scale.

## Regression risk

The target changes add 10pt of width per control. The stepper rows and the saved-game
card are the only layouts affected, and both absorb it through an existing `Spacer`.
Verified on iPhone and iPad; the drawn circles are unchanged at 34pt.

The adjustable action is additive — it changes nothing for a sighted user, and the two
buttons still work by direct tap.
