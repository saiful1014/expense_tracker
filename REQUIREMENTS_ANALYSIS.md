# Requirements Analysis — Expense Tracker (`expense_tracker`)

> **Package name:** `test_new_things`  
> **App title:** Daily Expenses  
> **Platform:** Flutter (Android primary, iOS configured, Web minimal)  
> **SDK:** Dart 3.9

---

## 1. Core Problem & Value Proposition

Daily Expenses is a **personal expense tracking app** that allows users to record, categorize, and manage daily spending alongside borrow/lend transactions. It supports **local-first storage** with optional **cloud sync via Firebase** and **Google Sign-in**, enabling multi-device access while preserving offline functionality.

---

## 2. Functional Requirements (FR)

### 2.1 Expense Tracking

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-01 | User can add an expense with description, amount, date/time, category | Must | 7 categories: Food, Transport, Shopping, Bills, Entertainment, Health, Other |
| FR-02 | User can edit an existing expense | Must | Pre-fills all fields on AddExpenseScreen |
| FR-03 | User can delete an expense | Must | Confirmation dialog; requires internet + sign-in |
| FR-04 | Amount must be positive, max 2 decimal places | Must | Input formatter enforces regex `^\d+\.?\d{0,2}` |
| FR-05 | Description must be non-empty | Must | Validated on save |
| FR-06 | Date range filtering (start + end date pickers) | Should | Filters visible totals and list; "Today" label switches to "Date Range" |
| FR-07 | User can clear active date filter | Should | Reset button visible only when filter is active |
| FR-08 | Pull-to-refresh on home screen | Should | Triggers full `loadExpenses()` |
| FR-09 | No future dates allowed | Must | Date picker limits: 2020–today |

### 2.2 Borrow & Lend Tracking (Deferred Feature)

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-10 | User can mark a transaction as "You Owe" or "Owed to You" | Must | Segmented control on AddBorrowLendScreen |
| FR-11 | User can add a borrow/lend transaction | Must | Person name (required), amount, date, description (optional) |
| FR-12 | User can edit a borrow/lend transaction | Must | Pre-fills all fields on AddBorrowLendScreen |
| FR-13 | User can delete a borrow/lend transaction | Must | Same cloud-first delete strategy as expenses |
| FR-14 | User can mark transaction as Completed | Should | Available on active borrow/lend cards; confirmation dialog |
| FR-15 | User can mark completed transaction back to Pending | Should | Available on Completed tab only |
| FR-16 | 3-tab UI: "You Owe", "Owed to You", "Completed" | Must | Each tab filters by type and completed flag |
| FR-17 | Summary cards showing total borrowed / total lent | Should | Gradient cards above the transaction list |

### 2.3 Cloud Sync & Authentication

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-18 | User can sign in with Google | Must | Google Sign-In + Firebase Auth |
| FR-19 | User can sign out (disable cloud sync) | Should | From Cloud Sync Setup screen |
| FR-20 | App works fully offline (local-only mode) | Must | Works even when Firebase fails to initialize |
| FR-21 | Automatic sync when connectivity is restored | Should | OfflineSyncService listens to connectivity stream |
| FR-22 | Manual sync from cloud to local | Should | `syncFromCloud()` inserts records not yet local |
| FR-23 | Firestore user-scoped data isolation | Must | `users/{userId}/expenses/` and `users/{userId}/borrow_lend/` |

### 2.4 Data Filtering & Display

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-24 | Home screen shows Total, Today, and (optionally) Date Range totals | Must | Calculated from local SQLite |
| FR-25 | Expense list ordered by date descending | Must | `ORDER BY date DESC` in all queries |
| FR-26 | Completed borrow/lend transactions visually distinguished | Should | Green border, strikethrough, "Completed" badge |

### 2.5 Splash / Onboarding

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-27 | App shows splash screen on launch | Must | Animated 1.5s + 2s delay → navigates to Home |
| FR-28 | Splash auto-navigates to HomeScreen | Must | No user gesture required |

---

## 3. Non-Functional Requirements (NFR)

| ID | Requirement | Priority |
|---|---|---|
| NFR-01 | App must be responsive / work on phones | Must |
| NFR-02 | SQLite reads must complete in < 100ms | Should |
| NFR-03 | Cloud sync must not block UI | Should | Long operations should be backgrounded |
| NFR-04 | App must gracefully handle all network failures | Must | Snackbar feedback; no crash |
| NFR-05 | Data must not be lost if cloud sync fails | Must | Local-first insertion confirms this |

---

## 4. Data Models

### 4.1 Expense (local + cloud)

```dart
class Expense {
  int? id;              // PK in SQLite; Firestore doc ID
  String description;   // Required
  double amount;        // Required, > 0
  DateTime date;        // ISO 8601 string
  String category;      // Required: Food|Transport|Shopping|Bills|Entertainment|Health|Other
  bool synced;          // Local only; default false
}
```

### 4.2 BorrowLend (local + cloud)

```dart
class BorrowLend {
  int? id;              // PK in SQLite; Firestore doc ID
  String personName;    // Required
  double amount;        // Required, > 0
  DateTime date;        // ISO 8601 string
  String type;          // 'borrow' or 'lend'
  String? description;  // Optional
  bool completed;      // Default false
  bool synced;          // Local only; default false
}
```

---

## 5. Storage Architecture

### 5.1 Local SQLite (`expenses.db`)

| Table | Version Added | Fields |
|---|---|---|
| `expenses` | v1 | id (PK), description, amount, date, category, synced |
| `borrow_lend` | v2 | id (PK), person_name, amount, date, type, description, completed, synced |

Migrations:
- v1 → v2: Add `borrow_lend` table
- v2 → v3: Add `completed` column to `borrow_lend`
- v3 → v4: Add `synced` columns to both tables

Key behaviors:
- Update operations force `synced = 0` (marks unsynced after edit)
- Mark-completed / mark-pending also force `synced = 0`
- All queries order by `date DESC`
- `delete` does **not** orphan-check — relies on FK-free design

### 5.2 Cloud Firestore

```
users/{userId}/
  ├── expenses/
  │   └── {expenseId}          // description, amount, date, category, lastUpdated
  └── borrow_lend/
  │   └── {transactionId}      // person_name, amount, date, type, description, completed, lastUpdated
```

Notes:
- Document IDs: local SQLite `id` for existing; `DateTime.now().millisecondsSinceEpoch` for new cloud
- `lastUpdated` is stored but **never read or queried**
- `synced` flag is **not** stored in Firestore (only local)
- Document ID collision risk on multi-device creation at same millisecond

### 5.3 Shared Preferences

- `shared_preferences` dependency declared but **not used** in Dart code.
- No persisted app settings identified.

---

## 6. Authentication & Authorization

### 6.1 Auth Flow

1. User taps "Sign In with Google" on Cloud Sync Setup screen
2. Native Google account picker (`google_sign_in` package)
3. On success: exchange credential → `_auth.signInWithCredential()`
4. Firebase Auth SDK handles local persistence (no custom session storage)
5. If user cancels: returns false silently
6. On any error: shown orange snackbar "No internet connection" or generic failure message

### 6.2 Authorization (Client-side Guards)

| Action | Guard |
|---|---|
| Delete expense | Requires internet AND signed in |
| Delete borrow/lend | Requires internet AND signed in |
| Cloud sync | Requires signed in |

### 6.3 Firestore Security Rules (Documented, Not Deployed)

```javascript
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**Gap:** Rules currently in **test mode**. Must be deployed before production.

---

## 7. State Management

### 7.1 Controllers (ChangeNotifier)

| Controller | Scope | State Held |
|---|---|---|
| `ExpenseController` | Per-instance (HomeScreen) | `_expenses`, `_totalExpenses`, `_todayExpenses`, `_selectedDateTotal`, `_isLoading`, `_startDate`, `_endDate`, `_errorMessage` |
| `BorrowLendController` | Per-instance (BorrowLendScreen) | `_borrowedList`, `_lentList`, `_completedList`, `_totalBorrowed`, `_totalLent`, `_isLoading`, `_errorMessage` |

Both controllers:
- Created in `initState()` of their respective screens
- Not global singletons
- Call UseCases which in turn call Repositories

### 7.2 Singletons

| Service | Purpose |
|---|---|
| `OfflineSyncService` | Background sync on connectivity restored |
| `ConnectivityService` | Network connectivity monitoring |
| `DatabaseHelper` | SQLite operations |

---

## 8. Network & Offline Behavior

### 8.1 Connectivity

- Uses `connectivity_plus` to detect mobile/wifi/ethernet
- **Does NOT verify actual internet reachability** (only checks connection type, not HTTP)
- Streams connectivity changes to trigger auto-sync

### 8.2 Sync Strategy (Local-First)

| Operation | Flow |
|---|---|
| Add/Edit | Insert/update local → `synced=0` → attempt cloud push |
| Delete | Delete from cloud first → delete local (both succeed or neither) |
| Sync from cloud | Query all cloud docs → insert missing by ID match → mark synced |
| Background sync | On connectivity restored → iterate unsynced records → push individually |

### 8.3 Conflict Resolution

**No explicit conflict resolution.** Rules:
- `syncFromCloud()` inserts only if ID not found locally — never overwrites local
- If a record was modified on two devices: **last writer wins with no merge**
- Cross-device ID collision: IDs created with millisecond timestamps on the cloud cannot be matched to local auto-increment IDs, causing **duplicate records on import**

---

## 9. Deferred Components

**borrowLendComponent** is configured as a deferred (on-demand) component using `loadLibrary()`:
- Reduces initial APK size by splitting Borrow/Lend feature module
- Loads on first tap of Wallet icon on Home AppBar
- Static `_isLoaded` flag prevents re-download within the same session
- Implication: **Google Play distribution required** — deferred components need Play Feature Delivery

---

## 10. Build & Deployment

### 10.1 Platform Configuration

| Platform | Status |
|---|---|
| Android | Configured (`com.dailyexpenses.app`, minSdk 24, dynamic feature module) |
| iOS | Default Flutter config; no custom modifications visible |
| Web | Minimal; no service worker / PWA enhancements |

### 10.2 Build Flavors

**None.** No `--dart-define`, no flavor configuration, no environment-specific endpoints.

### 10.3 Pre-Release Requirements

| Requirement | Status |
|---|---|
| Firebase config files (`google-services.json`, `GoogleService-Info.plist`) | Must be added |
| Firestore security rules deployed | Must (currently test mode) |
| Debug signing config changed to release signing | Must (current build uses debug keystore) |
| SHA-1 fingerprint added to Firebase Console | Must (for Android Google Sign-In) |
| App store listings / Play Store / App Store Connect setup | Must for publish |

---

## 11. Testing

**No tests exist.** `test/` directory is empty. `flutter_test` SDK is declared but unused.

| Type | Coverage |
|---|---|
| Unit tests | 0% |
| Widget tests | 0% |
| Integration tests | 0% |

---

## 12. Observability

| Component | Status |
|---|---|
| Logging | `debugPrint` only; no structured framework |
| Crash reporting | None (no Crashlytics, Sentry, etc.) |
| Analytics | None |
| Error boundaries | No global `FlutterError.onError` override |

---

## 13. Dependencies & Risk Assessment

| Dependency | Version | Risk |
|---|---|---|
| `flutter_sdk` | ^3.9.0 | Stable — Low risk |
| `firebase_core` | ^3.6.0 | Stable — standard |
| `cloud_firestore` | ^5.4.4 | Stable — standard |
| `firebase_auth` | ^5.3.1 | Stable — standard |
| `google_sign_in` | ^6.2.1 | Stable — standard |
| `sqflite` | ^2.4.2 | Stable but **Flutter 3.x migration completed**; verify plugin registration |
| `provider` | ^6.1.1 | Stable — Low risk |
| `connectivity_plus` | ^6.1.0 | Known to report "connected" when captive portal is active — no actual HTTP check |
| `shared_preferences` | ^2.5.3 | Unused — removable unless planned for future use |
| `cupertino_icons` | ^1.0.8 | Low risk |
| `flutter_launcher_icons` | ^0.13.1 | Dev-only; lowers risk |
| `flutter_lints` | ^5.0.0 | Dev-only; Low risk |

---

## 14. Gaps & Ambiguities

### 14.1 Functional Gaps

| Gap | Severity | Description |
|---|---|---|
| No conflict resolution | High | Concurrent edits on two devices overwrite silently; no merge UI |
| No ID collision handling | High | Cloud doc IDs from millisecond timestamps fail ID-match on sync → duplicate records |
| connectivity_plus ≠ real internet | Medium | "Connected" notification triggers sync that fails without retry |
| No currency/locale handling | Medium | Amounts stored and displayed as raw doubles; no currency formatting |
| No category management | Low | Categories are hardcoded; user cannot add/edit/delete categories |
| No account deletion / data export | Low | No GDPR or user-data management flow |
| No search in expense list | Low | Only date-filtering available |
| No recurring expense support | Low | Each entry must be re-entered manually |
| no `shared_preferences` usage | Low | Dependency declared but unused |
| No slope/budget alerts | Low | "Today" total shown but no budget threshold or warning |
| No multi-account support | Low | Single Google account per device session |
| No FCM / push notifications | Low | Background sync only works while app is foregrounded |

### 14.2 Architectural Gaps

| Gap | Severity | Description |
|---|---|---|
| No DI framework | Medium | CloudSyncService re-instantiated per use case; no connection pooling |
| No error boundary | Medium | Unhandled async errors in widget tree could crash app |
| Controllers not disposed | Low | `ExpenseController` and `BorrowLendController` created in `initState` without `dispose()` — potential minor memory leak |
| `lastUpdated` field unused | Low | Stored in Firestore but never read, queried, or surfaced in UI |

### 14.3 Security Gaps

| Gap | Severity | Description |
|---|---|---|
| Firestore rules in test mode | High | All data readable/writable by anyone until rules deployed |
| No input sanitization for Firestore fields | Low | Strings written directly; no XSS concerns in Flutter but consistency risk |
| Debug signing in release builds | High | Build configured with debug keystore — critical for production |

### 14.4 Deploy Risks

| Risk | Severity | Description |
|---|---|---|
| Release with debug signing | Critical | Signed with debug key; cannot be updated via Play Store; all users must reinstall |
| Deferred component on non-Play stores | Medium | Will fail to download borrowLendComponent on sideloaded builds |
| No rollback migration path | Low | Single-direction schema version with no downgrade |

---

## 15. Traceability Matrix

| Screen | Models | Local Tables | Cloud Docs | Use Cases | Controller |
|---|---|---|---|---|---|
| SplashScreen | — | — | — | — | — |
| HomeScreen | Expense | `expenses` | `users/{uid}/expenses/` | AddExpense, UpdateExpense, DeleteExpense, GetExpensesByDate, GetTotalExpensesByDate, GetTotalExpensesByDateRange | ExpenseController |
| AddExpenseScreen | Expense | `expenses` | `users/{uid}/expenses/` | AddExpense, UpdateExpense | ExpenseController (indirect) |
| SyncSetupScreen | — | — | — | SignInWithGoogle, SignOut | — |
| BorrowLendScreen | BorrowLend | `borrow_lend` | `users/{uid}/borrow_lend/` | GetBorrowLendByType, DeleteBorrowLend, MarkAsCompleted, MarkAsPending | BorrowLendController |
| AddBorrowLendScreen | BorrowLend | `borrow_lend` | `users/{uid}/borrow_lend/` | AddBorrowLend, UpdateBorrowLend | BorrowLendController (indirect) |
| DeferredBorrowLend | — | — | — | — | — |

---

## 16. Acceptance Criteria Summary

To consider this product "complete and deployable," the following must be addressed:

1. [ ] Replace debug signing with release keystore in `android/app/build.gradle.kts`
2. [ ] Deploy Firestore security rules (move from test mode to production)
3. [ ] Resolve cross-device ID collision in cloud sync (e.g., use UUID instead of millisecond timestamp for new cloud IDs)
4. [ ] Add conflict resolution or at least "last writer wins with timestamp" strategy
5. [ ] Replace `connectivity_plus`-only check with actual HTTP reachability test
6. [ ] Add unit tests for all use cases and repositories
7. [ ] Add global error boundary (`FlutterError.onError`)
8. [ ] Dispose controllers in screens (`dispose()` method)
9. [ ] Remove unused `shared_preferences` dependency, or implement a settings feature
10. [ ] Add currency formatting and locale-awareness for amounts

---

*Generated: 2026-06-05*  
*App Version: 1.0.0+1*  
*SDK: Dart 3.9*
