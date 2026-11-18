# SPEC.md — Household Pantry App (working name: "Pantry")

Read this file fully before writing any code. If a request conflicts with this spec, say so instead of silently deviating.

## 1. Purpose and users
A mobile + web app that helps a household know **what food it already has and what to use first**. Primary user: the household grocery manager (non-student adult, not tech-savvy). Others: family members who share the same pantry.

Core insight from research: inventory lives in one person's memory; people forget items, buy duplicates and let food expire; no one uses tools because effort is too high. **Every design decision must minimise user effort.**

## 2. Rules for the AI writing the code
1. Keep it simple. No microservices, no unnecessary abstractions, no extra features outside Phase 1.
2. Comment non-obvious code. The student must be able to explain every part.
3. App language is **English only**. No localization framework.
4. Never hardcode secrets. Use `.env` (backend) and never commit it. Provide `.env.example`.
5. All data belongs to a **household**, not a user. The server takes `household_id` from the authenticated token, **never from the request body**.
6. Never hard-delete items. Change `status` instead.
7. New features must be addable as new modules without rewriting existing ones.
8. After each task, list what was created and how to run and test it.

## 3. Scope
**Phase 1 (build now)**
- Signup/login (name + phone or email + PIN/password); a personal household is auto-created
- Add item (name + expiry required; quantity, category, location optional)
- Pantry list with status labels (Fresh / Soon / Expired), search, category filter
- Home screen with **Use First** list (soonest expiry first) and counts
- Mark item as used / thrown away
- Shopping list; ticking "bought" opens a sheet asking only expiry, then adds item to pantry
- Household: invite code, join with code, member list
- Expiry reminders (daily summary)
- Event logging (for before/after measurement)

**Phase 2 (later):** purchase history, barcode scan, low-stock alerts, quantity decrement.
**Future:** meal suggestions, analytics. Do not build these now, but do not block them.

## 4. Stack and distribution
- App: Flutter (Dart), Material 3. Targets: **Android (APK, direct install)** and **Web build** (used by iOS users via Safari "Add to Home Screen").
- Backend: Python + FastAPI + Uvicorn. Database: MongoDB Atlas (Motor driver).
- Auth: JWT, passwords/PINs hashed with bcrypt.
- Notifications: `flutter_local_notifications` on Android only. Guard with `kIsWeb`; on web show an in-app banner on Home ("N items expiring soon") instead.
- FastAPI must enable CORS for the web build's origin.

```
Flutter (Android APK / Web) --HTTPS+JWT--> FastAPI --> MongoDB Atlas
        |
        +-- local notifications (Android)
```

## 5. Data model (MongoDB collections)
All documents: `_id`, `created_at`, `updated_at`.

| Collection | Fields |
|---|---|
| users | name, identifier (phone or email, unique), secret_hash, household_id |
| households | name (default "My Kitchen"), invite_code (6 chars, unique), member_ids[] |
| items | household_id, name, expiry_date, status (`active`/`used`/`thrown`), used_at, added_by; optional: quantity, unit, category, location, barcode |
| shopping_items | household_id, name, quantity (optional), bought (bool), bought_at, added_by |
| events | user_id, household_id, type, meta (object), timestamp |

Do not store expiry status; compute it from `expiry_date` on every read.

## 6. Business rules
- Expiry status: `expired` if days_left < 0; `soon` if 0 ≤ days_left ≤ 3; else `fresh`.
- Use First = active items sorted by expiry_date ascending (expired first), limit 5 on Home.
- Signup creates a user and a household, links them, returns a JWT (long expiry, about 30 days, to avoid re-login friction).
- Invite code: 6 uppercase alphanumeric characters, avoid confusing characters (0/O, 1/I). Joining moves the user into that household.
- Marking an item bought: sets `bought=true`, `bought_at`, and (after the expiry sheet) creates an active item in the pantry.
- Concurrent edits: last write wins.
- Every query is filtered by the token's `household_id`.

## 7. API (prefix `/v1`)
- `POST /auth/signup`, `POST /auth/login`, `GET /me`
- `GET /items` (query: `status`, `category`, `q`), `POST /items`, `PATCH /items/{id}`, `POST /items/{id}/use`, `POST /items/{id}/throw`, `GET /items/use-first`
- `GET /shopping`, `POST /shopping`, `PATCH /shopping/{id}`, `POST /shopping/{id}/bought` (body: expiry_date)
- `GET /household`, `POST /household/join` (body: code), `POST /household/regenerate-code`
- `POST /events`
- `GET /health`

## 8. Screens (see wireframes)
Bottom tabs: **Home, Pantry, Shopping, Household**. A "+" floating button on Home and Pantry opens Add Item. Login/Signup screen shown when logged out.
- Add item: name field, expiry quick chips (1 week, 2 weeks, 1 month, 3 months, Pick date), collapsed "More details (optional)".
- Status is shown with icon + text + colour (never colour alone). Min tap target 48dp, body text 16sp+.
- Empty states with a clear first action. Short confirmation message after every action.
- Tone: friendly, positive microcopy. Home shows a progress line such as "6 items used before expiring this week".
- Screens must work with the last cached data when offline (read-only is enough).

## 9. Folder structure
Backend:
```
app/
  main.py, config.py, db.py, deps.py        # app setup, env, Mongo, auth dependency
  modules/auth/ households/ items/ shopping/ events/
    router.py, schemas.py, service.py       # one folder per feature
```
Flutter:
```
lib/
  main.dart, app_theme.dart, router.dart
  core/            # api client, storage, constants
  features/auth/ pantry/ shopping/ household/ home/
    data/ (models, repository)  ui/ (screens, widgets)  state/
```
One state-management package only (Provider or Riverpod, pick one and stay consistent).

## 10. Events to log
`app_open`, `signup`, `login`, `item_added`, `item_used`, `item_thrown`, `shopping_added`, `shopping_bought`, `reminder_opened`, `household_joined`, `invite_shared`.

## 11. Notifications
- Android: one daily summary (default 9:00 local) listing items expiring within 3 days; reschedule after every sync/login. Request notification permission at a sensible moment (after first item added), not on first launch.
- Do not send one notification per item.

## 12. Security checklist
- Passwords/PINs hashed (bcrypt), min length 4 for PIN, 6 for password.
- Token stored in `flutter_secure_storage` (Android); acceptable fallback on web.
- A user must never read or modify another household's data (test this).
- Validate all input with Pydantic. Rate-limit login if time permits.

## 13. Build order
1. Backend skeleton + Atlas + deploy. 2. Auth + household. 3. Items. 4. Shopping + bought flow. 5. Invite/join. 6. Events.
7. Flutter skeleton, theme, navigation. 8. Auth screens. 9. Home, Pantry, Add item. 10. Shopping. 11. Household. 12. Notifications. 13. Offline cache and polish. 14. Build APK and web.

## 14. Out of scope for now
Hindi/other languages, barcode, meal suggestions, analytics dashboards, payments, App Store / Play Store publishing.
