# Concentration
Swift memory game trying to use modern swift concurrency such as Task, Async, Await, Actor.  This is a work in progress. 

## Onboarding tips

The standalone `OnboardingView` is not connected to the game yet. Open its
named Xcode previews to explore the compact tutorial card. A host can
provide an app name, an array of `OBFeature` values, a tint color, and an
`onFinish` closure to dismiss the tips when the player skips or completes them.
Each tip plays a notification tone when shown, respecting the sound-effects
setting. The optional `onShowTip` closure can replace this behavior; previews
use it to stay silent. Other callers can play the same tone with
`AudioManager.shared.play(.tipNotification)`.
