# Toss Backend Scaffold

This folder is the Firebase/OpenAI backend path for the native Toss app.

## What it provides

- `tossAI` HTTPS Cloud Function
- `mode: "analyze"` for photo analysis
- `mode: "chat"` for item-aware chat
- Firestore memory writes when the model returns `memoryUpdate`
- Firestore rules that restrict `/users/{uid}` data to the signed-in user

## Required setup

1. Create a Firebase project.
2. Enable Authentication providers for Apple and Google.
3. Enable Firestore and Storage.
4. Set function secrets:

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

5. Optionally set `OPENAI_MODEL`, defaulting to `gpt-5-mini`.
6. Deploy:

```bash
cd backend/functions
npm install
npm run deploy
```

7. Paste the deployed function URL into `TossConfig.aiFunctionURL` in `Toss/FunctionalMVP.swift`.
