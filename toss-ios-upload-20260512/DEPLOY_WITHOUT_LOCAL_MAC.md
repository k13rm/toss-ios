# Deploy Toss Without Owning a Mac

You cannot build or publish an iOS app with no Apple toolchain anywhere. This repo is prepared for the practical route: build on Codemagic's cloud Mac machines from GitHub.

## Recommended Path

1. Create a GitHub repo named `toss-ios`.
2. Push this folder to that repo.
3. Create an Apple Developer account.
4. In Apple Developer / App Store Connect:
   - Create bundle ID: `com.kerem.toss`
   - Create an App Store Connect app named `Toss`
   - Enable Sign in with Apple for the app ID
5. In Firebase:
   - Create a Firebase project
   - Enable Apple and Google auth
   - Enable Firestore and Storage
   - Download `GoogleService-Info.plist` and add it to `Toss/` in Xcode later
6. In Codemagic:
   - Connect the GitHub repo
   - Select the `toss-ios-testflight` workflow from `codemagic.yaml`
   - Connect App Store Connect API integration
   - Configure iOS signing for `com.kerem.toss`
   - Add an environment group named `app_store_connect`
7. Run the workflow.
8. Install the uploaded build from TestFlight on your iPhone.

## Backend AI Setup

The native app currently works with a local fallback AI. To use real AI:

1. Deploy `backend/functions` to Firebase.
2. Set `OPENAI_API_KEY` as a Firebase Functions secret.
3. Copy the deployed `tossAI` function URL.
4. Paste it into `TossConfig.aiFunctionURL` in `Toss/FunctionalMVP.swift`.

## Important

- `GoogleService-Info.plist`, signing certificates, `.p12`, and provisioning profiles are ignored by Git on purpose.
- If you use a different Apple bundle ID, update both `codemagic.yaml` and the Xcode project bundle ID.
- The Windows browser mirror is only for visual preview. App Store/TestFlight builds must use the native SwiftUI project.
