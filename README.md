# Shift Tracker

Personal shift tracker: punch in/out, pay-period totals, calendar, trends.

## What changed from the original

- Hours show as hours and minutes (`9h 46m`), worked out from the minutes on screen. Stray seconds are ignored.
- A 30-minute unpaid break is taken off every workday. All totals are paid time. You can change the break length in Settings.
- Long-press any date on the Calendar and choose **Payday**. That date and every 14 days after it get an amber ring. Long-press again to remove it.

## Getting the APK

GitHub builds it automatically. Every push to `main` runs **Actions → Build APK**. When a run finishes, download **shift-tracker-apk** from the bottom of that run's page, unzip it, and install `app-release.apk` on your phone.

To build on your own computer instead:

```
flutter create --org com.chief --project-name shift_tracker --platforms android .
flutter pub get
python3 tool/patch_android.py
flutter build apk --release
```

## Signing key

`android/keystore/release.jks` signs every build. Keep this repo **private**, and keep the key. As long as each build uses the same key, a new version installs over the old one and your shifts are kept.
