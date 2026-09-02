---
name: run-on-device
description: Build, install and launch Gamoitsani2 on the paired physical iPhone over the network. Use before every commit that changes anything the user can see, and whenever asked to "run it on my device", "show me on my phone", or to verify UI on real hardware.
---

# Run on device

The user reviews UI on their physical iPhone, not in the simulator. Do this before
committing any visible change.

## 1. Confirm the device is reachable

```sh
xcrun devicectl list devices
```

Look for state `available (paired)`. The phone is paired over the network, so no cable is
needed — but it must be awake and on the same network.

## 2. Get the destination UDID

**The `-destination` UDID is not the identifier `devicectl list devices` prints.** That
one is a CoreDevice UUID. Using it in `-destination` fails with an unhelpful error.

```sh
xcodebuild -showdestinations -workspace Gamoitsani.xcworkspace -scheme Gamoitsani2 \
  | grep -i "platform:iOS," | grep -v Simulator
```

At the time of writing the phone is `00008140-001A682611E2801C`, but re-derive it rather
than assuming — it changes if they use a different device.

## 3. Build, install, launch

```sh
UDID=00008140-001A682611E2801C
DD=<scratchpad>/DDdev

xcodebuild build -workspace Gamoitsani.xcworkspace -scheme Gamoitsani2 \
  -destination "platform=iOS,id=$UDID" \
  -derivedDataPath "$DD" -allowProvisioningUpdates

APP=$(find "$DD/Build/Products" -name "*.app" -maxdepth 3 | head -1)
xcrun devicectl device install app --device "$UDID" "$APP"
xcrun devicectl device process launch --device "$UDID" <bundle-id>
```

`-allowProvisioningUpdates` is required — without it signing fails on a target whose
profile has not been generated yet.

## Notes

- Signing uses the existing team `V9DL6T6A4K` and the wildcard
  "iOS Team Provisioning Profile: *". Nothing new is registered in the developer account.
- Builds are Debug, so slower than release, and the profile expires in about a week.
- `Gamoitsani2` installs as bundle id `davitikhvedelidze.Gamoitsani2`, separate from the
  shipping v1 app, so both live on the phone at once. Do not "fix" this by reusing v1's
  bundle id — it would overwrite the real app.
- There is no `simctl`-style tap primitive for physical devices. To verify interaction
  rather than appearance, write a UI test; otherwise ask the user what they see.
- Tell the user to look at their phone once it launches, and say what specifically to
  check — they cannot see your terminal.

## Clean up

Delete the DerivedData directory afterwards. Device builds are large and this machine has
run out of disk mid-session before.
