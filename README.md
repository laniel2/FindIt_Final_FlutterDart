# FindIt – School Lost & Found (Flutter / Dart)

A mobile app where students report **lost** items and post **found** items, with photos.
**No MySQL** – data is stored on the device (SharedPreferences JSON + image files in the app folder).

## Features
- Create account / Login / Logout (passwords are salted + SHA-256 hashed, session is remembered)
- First-time **Profile setup** (photo, student ID, course, contact) + **Edit profile**
- **Report Lost / Found item** with photo (camera or gallery), category, location, description, contact
- Browse all reports, **search**, filter (All / Lost / Found), pull-to-refresh
- **My Reports** tab, mark as **Resolved**, **Delete** (with confirmation dialog)
- **API integration**: starter reports are fetched from `https://dummyjson.com` (REST API) and saved locally
- Loading spinner, error screen with *Try again*, empty-state screen, form validation, SnackBar feedback

## Where each required topic is
| # | Topic | Where |
|---|-------|-------|
| 1 | AppBar & titles | `theme.dart` (AppBarTheme), every screen has an `AppBar` title |
| 2 | Text & colors | `theme.dart` (`AppColors`: blue = brand, orange = lost, green = found) |
| 3 | Fonts & assets | Poppins font in `assets/fonts`, `assets/images/logo.png`, `empty.png`, Material icons |
| 4 | Stateless / Stateful | Stateless: `ItemCard`, `TypeBadge`, `InfoRow`, `ProfileTab`… Stateful: `LoginScreen`, `ItemsView`, `AddItemScreen`… |
| 5 | Custom widgets | `lib/widgets/` (AppTextField, PrimaryButton, ItemCard, TypeBadge, ItemImage, UserAvatar, ImagePickerBox, state views) |
| 6 | ListView.builder | `screens/items_view.dart` |
| 7 | API integration | `services/item_repository.dart` → `_fetchFromApi()` |
| 8 | Delete | `widgets/dialogs.dart` → `confirmAndDeleteItem()` (card menu + detail screen) |
| 9 | Navigation | Named routes in `main.dart`, bottom `NavigationBar`, `Navigator.push` to details |
| 10 | Interaction / state | Forms, chips, search, filters, buttons with loading state |
| 11 | Error & loading | `widgets/state_views.dart` (LoadingView, ErrorView, EmptyView) |
| 12 | Extras | Auth, profile, search, filter, resolve, image upload, validation, pull-to-refresh |

## How to run
1. Install Flutter (stable) and open a terminal in this folder.
2. Generate the Android/iOS platform folders (they are not in the zip):
   ```
   flutter create . --project-name findit --platforms=android,ios
   flutter pub get
   ```
3. **Android** – open `android/app/src/main/AndroidManifest.xml` and add, above `<application>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   (needed for the API when you build a release APK)
4. **iOS** – open `ios/Runner/Info.plist` and add inside `<dict>`:
   ```xml
   <key>NSCameraUsageDescription</key><string>Take photos of lost or found items.</string>
   <key>NSPhotoLibraryUsageDescription</key><string>Choose photos of lost or found items.</string>
   ```
5. Run: `flutter run`

The first time you open the app **with internet**, it downloads a few sample reports from the API.
Without internet you will see the error screen (with *Try again*) until it succeeds, or your own reports if you already added some.

## Project structure
```
lib/
  main.dart            routes + app
  theme.dart           colors + theme
  models/              AppUser, Item
  services/            AuthService (login/register), ItemRepository (storage + API)
  screens/             splash, login, register, profile setup, home, items list, detail, add item, profile
  widgets/             reusable custom widgets
```
