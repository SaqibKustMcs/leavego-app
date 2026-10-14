# Google Calendar (direct — no TaskBulls API)

Calendar is linked **only between the app and Google**. No calls to `taskbulls.devbay.ai` for calendar.

## Flow

1. User logs in with email/password (unchanged).
2. **Profile → Google Calendar → Connect** → Google OAuth, scope `calendar.readonly`.
3. App calls **Google Calendar API v3** with a short-lived access token from `google_sign_in`.
4. Connection flag + Google email stored in **Flutter Secure Storage** (not OAuth tokens).
5. **Disconnect** revokes the Google session on device and clears local storage.

## Google Cloud Console

1. Enable **Google Calendar API**.
2. **OAuth consent screen** — add scope `https://www.googleapis.com/auth/calendar.readonly`.
3. **Android OAuth client** — package `com.devbay.taskbulls`, SHA-1 and SHA-256 (debug + release).
4. **iOS OAuth client** — bundle `com.devbay.taskbulls`, set `GIDClientID` + URL scheme in `Info.plist`.

## Flutter

Client IDs are in `lib/config/google_calendar_config.dart`. iOS also uses `Info.plist` (`GIDClientID` + URL scheme).

**Android (important):** `google_sign_in` 7 needs a **Web application** OAuth client ID as `GOOGLE_OAUTH_WEB_CLIENT_ID` (not the Android client ID). Your `google-services.json` has no web OAuth entry, so this is required. Register SHA-1/SHA-256 on the **Android** OAuth client for `com.devbay.taskbulls`.

Optional overrides:

```bash
flutter run \
  --dart-define=GOOGLE_OAUTH_IOS_CLIENT_ID=... \
  --dart-define=GOOGLE_OAUTH_ANDROID_CLIENT_ID=...
```

## Notes

- Access tokens are **not** logged or stored in SharedPreferences. The app keeps a
  **connected** flag + Google email in secure storage; short-lived access tokens come
  from `google_sign_in` 7.x on each fetch (silent refresh when possible).
- On HTTP **401**, stale tokens are cleared via `clearAuthorizationToken` and refreshed
  silently before prompting the user. Use **Sync events** (Profile) for interactive
  re-authorization if needed.
- A **backend refresh-token** flow is not required for the current read-only mobile
  client; use server-side OAuth only if you need unattended sync without the app open.
- App login and Google login are independent (same email does not auto-connect Calendar).
