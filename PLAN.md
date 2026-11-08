# Komerca – Project Plan

> Version 1.0 · 2026-11-09
> Status: **Awaiting approval before any application code is written.**

---

## 1. Monorepo Folder Structure

```
komerca/
├── apps/
│   ├── api/                        # Node.js + Express + TypeScript
│   │   ├── prisma/
│   │   │   ├── schema.prisma
│   │   │   ├── migrations/
│   │   │   └── seed.ts
│   │   ├── src/
│   │   │   ├── config/             # env validation (Zod), app constants
│   │   │   ├── core/
│   │   │   │   ├── errors.ts       # AppError hierarchy
│   │   │   │   ├── middleware/     # auth, rate-limit, error handler, logger
│   │   │   │   └── openapi.ts      # Zod → OpenAPI spec generator
│   │   │   ├── modules/
│   │   │   │   ├── auth/           # OTP, JWT, refresh
│   │   │   │   ├── users/          # profile, seller stats
│   │   │   │   ├── categories/     # category config + attributes
│   │   │   │   ├── listings/       # CRUD, photos, search, filters
│   │   │   │   ├── images/         # Cloudinary sign + local adapter
│   │   │   │   ├── deals/          # reservations, offers, inquiries, sold
│   │   │   │   ├── reviews/        # post-deal reviews
│   │   │   │   ├── listing-check/  # dHash, text flags, score engine
│   │   │   │   ├── reports/        # user reports
│   │   │   │   └── admin/          # admin review screen endpoints
│   │   │   ├── lib/
│   │   │   │   ├── ai/             # LLM provider interface + adapters
│   │   │   │   └── hashing/        # dHash with sharp
│   │   │   └── index.ts            # Express app entry
│   │   ├── test/
│   │   │   ├── helpers/            # DB setup, auth helpers
│   │   │   ├── integration/        # Supertest suites per module
│   │   │   └── unit/               # listing-check, state machines
│   │   ├── .env.example
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── vitest.config.ts
│   │
│   └── mobile/                     # Flutter + Dart
│       ├── lib/
│       │   ├── core/
│       │   │   ├── theme/
│       │   │   │   ├── app_colors.dart
│       │   │   │   └── app_theme.dart
│       │   │   ├── router/         # go_router route definitions
│       │   │   ├── network/        # Dio client, interceptors, error models
│       │   │   ├── storage/        # flutter_secure_storage wrapper
│       │   │   └── utils/          # formatters, validators
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── listings/
│       │   │   ├── deals/
│       │   │   ├── reviews/
│       │   │   ├── listing_check/
│       │   │   └── admin/
│       │   ├── shared/
│       │   │   └── widgets/        # buttons, chips, badges, cards, etc.
│       │   └── main.dart
│       ├── test/
│       │   ├── contrast_test.dart  # WCAG AA contrast ratios
│       │   └── widget/             # widget tests per component
│       ├── pubspec.yaml
│       └── analysis_options.yaml
│
├── docs/
│   ├── architecture.md             # Mermaid diagram
│   ├── openapi.yaml                # generated from Zod schemas
│   └── EVALUATION.md
│
├── .github/
│   └── workflows/
│       ├── api.yml                 # lint, typecheck, test (Postgres service)
│       └── mobile.yml              # flutter analyze, flutter test
│
├── PLAN.md                         # this file
├── README.md
└── .gitignore
```

---

## 2. Prisma Schema

```prisma
// apps/api/prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ── Users ──────────────────────────────────────────────────────────────────

enum UserRole {
  BUYER
  SELLER
  ADMIN
}

model User {
  id            String    @id @default(cuid())
  phone         String    @unique
  name          String
  avatarUrl     String?
  city          String?
  role          UserRole  @default(BUYER)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  otpTokens     OtpToken[]
  refreshTokens RefreshToken[]
  listings      Listing[]
  reservations  Reservation[]
  offersMade    Offer[]    @relation("OfferBuyer")
  reviews       Review[]   @relation("ReviewAuthor")
  receivedReviews Review[] @relation("ReviewSeller")
  sentMessages  Message[]
  reports       Report[]   @relation("ReportReporter")
  reportedItems Report[]   @relation("ReportTarget")

  // Computed at query time via aggregates; stored fields for fast reads
  completedDealCount Int   @default(0)
  responseRate       Float @default(0)
}

model OtpToken {
  id        String   @id @default(cuid())
  userId    String
  code      String
  expiresAt DateTime
  used      Boolean  @default(false)
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model RefreshToken {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// ── Categories ─────────────────────────────────────────────────────────────

model Category {
  id          String    @id @default(cuid())
  slug        String    @unique  // "phones-gadgets" | "fashion" | "home-furniture" | "books-school"
  name        String
  iconName    String    // Material icon name
  sortOrder   Int       @default(0)

  listings    Listing[]
}

// ── Listings ───────────────────────────────────────────────────────────────

enum ListingCondition {
  NEW
  LIKE_NEW
  GOOD
  FAIR
  FOR_PARTS
}

enum ListingStatus {
  DRAFT
  ACTIVE
  RESERVED
  SOLD
  REMOVED
}

model Listing {
  id            String           @id @default(cuid())
  sellerId      String
  categoryId    String
  title         String
  description   String
  price         Decimal          @db.Decimal(10, 2)
  condition     ListingCondition
  city          String
  lat           Float?
  lng           Float?
  attributes    Json             // category-specific, validated per-category
  status        ListingStatus    @default(DRAFT)
  viewCount     Int              @default(0)
  searchVector  Unsupported("tsvector")?  // maintained by trigger
  createdAt     DateTime         @default(now())
  updatedAt     DateTime         @updatedAt

  // Listing-check result (computed on save/update, cached)
  checkScore    Float?
  checkLevel    String?          // "LOW" | "MEDIUM" | "HIGH"
  checkReasons  Json?            // string[]

  seller        User             @relation(fields: [sellerId], references: [id])
  category      Category         @relation(fields: [categoryId], references: [id])
  photos        ListingPhoto[]
  reservation   Reservation?
  offers        Offer[]
  inquiries     Inquiry[]
  reviews       Review[]
  reports       Report[]         @relation("ListingReports")

  @@index([sellerId])
  @@index([categoryId])
  @@index([status])
  @@index([city])
  @@index([price])
  @@index([createdAt])
}

model ListingPhoto {
  id         String  @id @default(cuid())
  listingId  String
  url        String
  publicId   String  // Cloudinary public_id or local filename
  dhash      String? // 64-bit hex, for duplicate detection
  sortOrder  Int     @default(0)

  listing    Listing @relation(fields: [listingId], references: [id], onDelete: Cascade)

  @@index([listingId])
  @@index([dhash])
}

// ── Deals: Reservations ────────────────────────────────────────────────────

enum ReservationStatus {
  ACTIVE
  EXPIRED
  CANCELLED
  COMPLETED
}

model Reservation {
  id          String            @id @default(cuid())
  listingId   String            @unique
  buyerId     String
  expiresAt   DateTime
  status      ReservationStatus @default(ACTIVE)
  createdAt   DateTime          @default(now())
  updatedAt   DateTime          @updatedAt

  listing     Listing           @relation(fields: [listingId], references: [id])
  buyer       User              @relation(fields: [buyerId], references: [id])
}

// ── Deals: Offers ──────────────────────────────────────────────────────────

enum OfferStatus {
  PENDING
  ACCEPTED
  DECLINED
  EXPIRED
  CANCELLED
}

model Offer {
  id          String      @id @default(cuid())
  listingId   String
  buyerId     String
  amount      Decimal     @db.Decimal(10, 2)
  message     String?
  status      OfferStatus @default(PENDING)
  expiresAt   DateTime
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt

  listing     Listing     @relation(fields: [listingId], references: [id])
  buyer       User        @relation("OfferBuyer", fields: [buyerId], references: [id])

  @@index([listingId])
  @@index([buyerId])
}

// ── Deals: Inquiry Threads ─────────────────────────────────────────────────

model Inquiry {
  id        String    @id @default(cuid())
  listingId String
  buyerId   String    // thread is per (listing, buyer) pair
  createdAt DateTime  @default(now())

  listing   Listing   @relation(fields: [listingId], references: [id])
  messages  Message[]

  @@unique([listingId, buyerId])
}

model Message {
  id        String   @id @default(cuid())
  inquiryId String
  senderId  String
  body      String
  createdAt DateTime @default(now())

  inquiry   Inquiry  @relation(fields: [inquiryId], references: [id])
  sender    User     @relation(fields: [senderId], references: [id])

  @@index([inquiryId])
}

// ── Reviews ────────────────────────────────────────────────────────────────

model Review {
  id         String   @id @default(cuid())
  listingId  String
  authorId   String
  sellerId   String
  rating     Int      // 1–5
  comment    String?
  createdAt  DateTime @default(now())

  listing    Listing  @relation(fields: [listingId], references: [id])
  author     User     @relation("ReviewAuthor", fields: [authorId], references: [id])
  seller     User     @relation("ReviewSeller", fields: [sellerId], references: [id])

  @@unique([listingId, authorId])
}

// ── Reports ────────────────────────────────────────────────────────────────

enum ReportReason {
  SPAM
  FAKE
  OFFENSIVE
  SCAM
  OTHER
}

enum ReportStatus {
  PENDING
  REVIEWED
  DISMISSED
  REMOVED
}

model Report {
  id          String       @id @default(cuid())
  reporterId  String
  listingId   String
  targetId    String       // the seller's userId
  reason      ReportReason
  details     String?
  status      ReportStatus @default(PENDING)
  adminNote   String?
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  reporter    User         @relation("ReportReporter", fields: [reporterId], references: [id])
  listing     Listing      @relation("ListingReports", fields: [listingId], references: [id])
  target      User         @relation("ReportTarget", fields: [targetId], references: [id])
}

// ── Saved Searches ─────────────────────────────────────────────────────────

model SavedSearch {
  id          String   @id @default(cuid())
  userId      String
  query       String
  filters     Json     // serialized filter params
  lastAlertAt DateTime?
  createdAt   DateTime @default(now())

  @@index([userId])
}

// ── Reference Prices (SAMPLE DATA) ────────────────────────────────────────

model ReferencePrice {
  id        String  @id @default(cuid())
  model     String  @unique  // e.g. "iPhone 13"
  minPrice  Decimal @db.Decimal(10, 2)
  maxPrice  Decimal @db.Decimal(10, 2)
  currency  String  @default("PHP")
  // SAMPLE DATA – not real market prices, for demo/testing only
}
```

---

## 3. API Endpoint List

All routes prefixed with `/api/v1`. Auth-required routes marked **[A]**. Admin-only marked **[Admin]**.

### Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/otp/request | Request OTP (rate-limited) |
| POST | /auth/otp/verify | Verify OTP → access + refresh tokens |
| POST | /auth/token/refresh | Refresh access token |
| POST | /auth/logout | [A] Revoke refresh token |

### Users / Profile
| Method | Path | Description |
|--------|------|-------------|
| GET | /users/me | [A] Get own profile |
| PATCH | /users/me | [A] Update profile (name, city, avatar) |
| GET | /users/:id | Public seller profile |
| GET | /users/:id/listings | Public listings by seller |
| GET | /users/:id/reviews | Reviews received by seller |

### Categories
| Method | Path | Description |
|--------|------|-------------|
| GET | /categories | List all categories |
| GET | /categories/:slug | Category detail + attribute schema |

### Listings
| Method | Path | Description |
|--------|------|-------------|
| GET | /listings | Browse / search (q, categoryId, city, minPrice, maxPrice, condition, sortBy, lat, lng, page, limit) |
| POST | /listings | [A] Create listing (draft) |
| GET | /listings/:id | Get listing detail |
| PATCH | /listings/:id | [A] Update listing (owner only) |
| DELETE | /listings/:id | [A] Remove listing (owner or admin) |
| POST | /listings/:id/publish | [A] Publish draft (owner) |
| POST | /listings/:id/sold | [A] Mark as sold (owner) |

### Photos
| Method | Path | Description |
|--------|------|-------------|
| POST | /listings/:id/photos/sign | [A] Get signed Cloudinary upload params |
| POST | /listings/:id/photos | [A] Register photo after upload (url, publicId) |
| DELETE | /listings/:id/photos/:photoId | [A] Delete photo (owner) |

### Deals – Reservations
| Method | Path | Description |
|--------|------|-------------|
| POST | /listings/:id/reservation | [A] Create reservation (buyer) |
| GET | /listings/:id/reservation | [A] Get reservation for listing |
| DELETE | /listings/:id/reservation | [A] Cancel reservation (buyer or seller) |

### Deals – Offers
| Method | Path | Description |
|--------|------|-------------|
| POST | /listings/:id/offers | [A] Make offer (buyer) |
| GET | /listings/:id/offers | [A] List offers on listing (seller sees all, buyer sees own) |
| PATCH | /listings/:id/offers/:offerId | [A] Accept / decline / cancel offer |

### Deals – Inquiry Threads
| Method | Path | Description |
|--------|------|-------------|
| POST | /listings/:id/inquiries | [A] Start or get inquiry thread |
| GET | /listings/:id/inquiries/:inquiryId/messages | [A] Poll messages (buyer or seller) |
| POST | /listings/:id/inquiries/:inquiryId/messages | [A] Send message |

### Reviews
| Method | Path | Description |
|--------|------|-------------|
| POST | /listings/:id/reviews | [A] Leave review (buyer with completed deal only) |
| GET | /listings/:id/reviews | Get reviews for listing |

### AI Assistant
| Method | Path | Description |
|--------|------|-------------|
| POST | /ai/listing-draft | [A] Upload photos → get draft (rate-limited per user) |

### Reports
| Method | Path | Description |
|--------|------|-------------|
| POST | /listings/:id/reports | [A] Report a listing |

### Admin
| Method | Path | Description |
|--------|------|-------------|
| GET | /admin/reports | [Admin] List reports (filterable by status) |
| PATCH | /admin/reports/:id | [Admin] Review/dismiss/remove |
| GET | /admin/listings | [Admin] Search listings by status |
| PATCH | /admin/listings/:id/status | [Admin] Force status change |

### Saved Searches
| Method | Path | Description |
|--------|------|-------------|
| GET | /saved-searches | [A] List own saved searches |
| POST | /saved-searches | [A] Save a search |
| DELETE | /saved-searches/:id | [A] Delete saved search |
| GET | /saved-searches/alerts | [A] Poll for new matches (returns new listing IDs since lastAlertAt) |

---

## 4. Flutter Screen List

### Navigation structure
```
Root
 ├── /splash                     SplashScreen
 ├── /onboarding                 OnboardingScreen
 ├── /auth/phone                 PhoneInputScreen
 ├── /auth/otp                   OtpVerificationScreen
 └── /app  (BottomNavShell)
      ├── /browse                BrowseScreen (feed + search)
      │    ├── /browse/search    SearchResultsScreen
      │    └── /listings/:id     ListingDetailScreen
      │         ├── /listings/:id/reserve   ReserveSheet (bottom sheet)
      │         ├── /listings/:id/offer     MakeOfferSheet
      │         └── /listings/:id/inquire   InquiryThreadScreen
      ├── /sell
      │    ├── /sell/new         CreateListingScreen (step 1: photos)
      │    ├── /sell/draft/:id   DraftListingScreen  (step 2: details)
      │    └── /sell/ai-assist   AiAssistScreen
      ├── /inbox                 InboxScreen (all inquiry threads)
      │    └── /inbox/:inquiryId InquiryThreadScreen
      ├── /profile
      │    ├── /profile/me       OwnProfileScreen
      │    ├── /profile/:id      SellerProfileScreen
      │    └── /profile/settings SettingsScreen
      └── /gallery               ComponentGalleryScreen  ← dev only
```

### Screen inventory (38 screens + 1 dev screen)

| # | Screen | Feature |
|---|--------|---------|
| 1 | SplashScreen | Scaffold |
| 2 | OnboardingScreen | Scaffold |
| 3 | PhoneInputScreen | Auth |
| 4 | OtpVerificationScreen | Auth |
| 5 | ComponentGalleryScreen | Scaffold/Theme |
| 6 | BrowseScreen | Listings |
| 7 | SearchResultsScreen | Listings |
| 8 | FilterSheet | Listings |
| 9 | ListingDetailScreen | Listings |
| 10 | PhotoViewerScreen | Listings |
| 11 | CreateListingScreen | Listings |
| 12 | DraftListingScreen | Listings |
| 13 | CategoryPickerScreen | Listings |
| 14 | AttributesFormScreen | Listings |
| 15 | PhotoPickerScreen | Listings |
| 16 | ManageListingsScreen | Listings |
| 17 | AiAssistScreen | AI Assistant |
| 18 | ReserveSheet (bottom sheet) | Deals |
| 19 | ReservationStatusSheet | Deals |
| 20 | MakeOfferSheet | Deals |
| 21 | OffersListScreen | Deals |
| 22 | OfferDetailSheet | Deals |
| 23 | InboxScreen | Deals |
| 24 | InquiryThreadScreen | Deals |
| 25 | MarkSoldScreen | Deals |
| 26 | LeaveReviewScreen | Reviews |
| 27 | ReviewsListScreen | Reviews |
| 28 | OwnProfileScreen | Users |
| 29 | SellerProfileScreen | Users |
| 30 | EditProfileScreen | Users |
| 31 | SettingsScreen | Users |
| 32 | ReportSheet | Reports |
| 33 | ListingCheckBadgeSheet | Listing Check |
| 34 | SavedSearchesScreen | Saved Searches |
| 35 | AdminReportsScreen | Admin |
| 36 | AdminListingsScreen | Admin |
| 37 | AdminReportDetailScreen | Admin |
| 38 | NotFoundScreen | Navigation |

---

## 5. State Machines

### 5.1 Reservation State Machine

```
States: ACTIVE → EXPIRED | CANCELLED | COMPLETED
        (only one reservation per listing at a time)

Transitions:
  [buyer] POST /listings/:id/reservation
    guard: listing.status == ACTIVE, no existing ACTIVE reservation
    effect: reservation.status = ACTIVE
            listing.status = RESERVED
            reservation.expiresAt = now + 24 h

  [cron / on-read] expiry check
    guard: reservation.expiresAt < now, reservation.status == ACTIVE
    effect: reservation.status = EXPIRED
            listing.status = ACTIVE

  [buyer] DELETE /listings/:id/reservation
    guard: reservation.status == ACTIVE, caller == buyer
    effect: reservation.status = CANCELLED
            listing.status = ACTIVE

  [seller] DELETE /listings/:id/reservation
    guard: reservation.status == ACTIVE, caller == seller
    effect: reservation.status = CANCELLED
            listing.status = ACTIVE

  [seller] POST /listings/:id/sold
    guard: reservation exists (ACTIVE or EXPIRED), caller == seller
    effect: reservation.status = COMPLETED
            listing.status = SOLD
            user.completedDealCount++

Invalid transitions (all must return 409):
  - Creating reservation on RESERVED or SOLD listing
  - Cancelling an EXPIRED or COMPLETED reservation
  - Double-reservation by same or different buyer
```

### 5.2 Offer State Machine

```
States: PENDING → ACCEPTED | DECLINED | EXPIRED | CANCELLED

Transitions:
  [buyer] POST /listings/:id/offers
    guard: listing.status in (ACTIVE, RESERVED)
           buyer has no PENDING offer on this listing
           offer.amount > 0
    effect: offer.status = PENDING
            offer.expiresAt = now + 48 h

  [seller] PATCH …/offers/:id { action: "accept" }
    guard: offer.status == PENDING, caller == seller
    effect: offer.status = ACCEPTED
            listing.status = SOLD
            all OTHER PENDING offers on listing → DECLINED
            reservation (if any) → CANCELLED
            user.completedDealCount++

  [seller] PATCH …/offers/:id { action: "decline" }
    guard: offer.status == PENDING, caller == seller
    effect: offer.status = DECLINED

  [buyer] PATCH …/offers/:id { action: "cancel" }
    guard: offer.status == PENDING, caller == buyer
    effect: offer.status = CANCELLED

  [cron / on-read] expiry check
    guard: offer.expiresAt < now, offer.status == PENDING
    effect: offer.status = EXPIRED

Invalid transitions (all must return 409):
  - Accepting/declining a non-PENDING offer
  - Buyer making a second PENDING offer on the same listing
  - Making an offer on a SOLD listing
```

---

## 6. Feature-by-Feature Build Plan

---

### Feature 1 — Scaffold, CI, Theme + Component Gallery

**What it includes**

*API:*
- Monorepo root init (package.json workspaces, .gitignore, .env.example)
- `apps/api`: Express skeleton, tsconfig, Vitest config, Prisma init, database connection test
- GitHub Actions workflow: lint (eslint), typecheck, `vitest run` against Postgres service container

*Flutter:*
- `apps/mobile`: Flutter project, pubspec.yaml with all approved dependencies
- `app_colors.dart` — all brand color tokens, every neutral derived and commented
- `app_theme.dart` — MaterialApp ThemeData built from explicit ColorScheme
- `shared/widgets/`: KomButton (primary/secondary), KomChip, KomBadge (risk levels), KomCard, KomAvatar
- `ComponentGalleryScreen` — displays all components with labels; reachable at `/gallery` in dev
- `contrast_test.dart` — checks WCAG AA (≥4.5:1) for all defined color pairs; fails CI if any pair fails
- GitHub Actions workflow: `flutter analyze`, `flutter test` (runs contrast test)

**Data models touched**
- None (no DB tables yet)

**Dependencies**
- None (this is the base)

**Tests**
- API: health-check integration test (`GET /api/v1/health` → 200)
- Flutter: `contrast_test.dart` for every main color pair

**Done checklist**
- [ ] Monorepo structure matches the folder layout in §1
- [ ] `apps/api` starts, connects to Postgres, returns `{ status: "ok" }` on health endpoint
- [ ] All brand colors defined only in `app_colors.dart`; no raw hex elsewhere
- [ ] `ComponentGalleryScreen` renders all 5 component types with correct colors
- [ ] Contrast test passes for all pairs (≥4.5:1)
- [ ] Both CI workflows pass on a clean push
- [ ] One conventional commit: `feat: scaffold monorepo, CI, theme, and component gallery`

---

### Feature 2 — Auth, Categories, Listings, Browse, Search, Filters

**What it includes**

*API:*
- `prisma/schema.prisma`: User, OtpToken, RefreshToken, Category, Listing, ListingPhoto models
- Auth module: `POST /auth/otp/request` (mock OTP: logs code, does not send SMS), `POST /auth/otp/verify`, `POST /auth/token/refresh`, `POST /auth/logout`
- JWT middleware (access token 15 min, refresh token 30 days); `express-rate-limit` on auth routes
- Users module: `GET /users/me`, `PATCH /users/me`, `GET /users/:id`, `GET /users/:id/listings`
- Categories module: `GET /categories`, `GET /categories/:slug` — config-driven, 4 initial categories with Zod attribute schemas
- Listings module: full CRUD + publish + sold; photo sign + register + delete endpoints
- Search: Postgres full-text (`tsvector` maintained by DB trigger) + `pg_trgm` for fuzzy; `GET /listings` with query params
- Zod schemas for all inputs; OpenAPI spec generated and written to `docs/openapi.yaml`
- Cloudinary image adapter (signed upload) + local-disk adapter for dev; interface selectable by env var

*Flutter:*
- Auth screens: PhoneInputScreen, OtpVerificationScreen
- Riverpod providers: authProvider (access token, user), stored in flutter_secure_storage
- Listings screens: BrowseScreen (feed, search bar), SearchResultsScreen, FilterSheet, ListingDetailScreen, PhotoViewerScreen
- Sell flow: CreateListingScreen (photo picker, flutter_image_compress), DraftListingScreen (title, price, condition, city, attributes), CategoryPickerScreen, AttributesFormScreen
- ManageListingsScreen (seller's own listings, status chips)
- Dio client with auth interceptor (auto-refresh on 401); hand-written typed models from OpenAPI spec (or generated — decided after reviewing spec quality)

**Data models touched**
- User, OtpToken, RefreshToken, Category, Listing, ListingPhoto

**Dependencies**
- Feature 1 (scaffold, CI, theme)

**Tests**
- API integration: auth flow (request OTP → verify → get /me → refresh → logout)
- API integration: listings CRUD, photo registration, search with at least 5 query scenarios
- API integration: category attribute Zod validation rejects invalid payloads
- Flutter widget: BrowseScreen renders listing cards; FilterSheet applies filters

**Done checklist**
- [ ] OTP mock logs the code and does not call any external service
- [ ] JWT access + refresh tokens issued; refresh endpoint rotates token
- [ ] All 4 categories seeded; each has a valid Zod attribute schema
- [ ] Listing create/update validates attributes against category schema
- [ ] Photo upload via Cloudinary (dev: local disk) signs correctly and stores `publicId`
- [ ] `GET /listings?q=` returns ranked results using full-text + trgm
- [ ] `GET /listings?sortBy=price|newest|nearest` all work; nearest uses Haversine SQL
- [ ] `docs/openapi.yaml` generated and committed
- [ ] All auth + listing integration tests pass
- [ ] Flutter: auth flow works end-to-end against local API
- [ ] Flutter: browse, search, filter, listing detail all render correctly
- [ ] Flutter: sell flow creates a draft and publishes it

---

### Feature 3 — Deals Basics (Reservation, Inquiry Threads, Mark as Sold)

**What it includes**

*API:*
- Reservation module: create, get, cancel endpoints; expiry enforced on read and by a lightweight check on listing fetch (no cron daemon — expired reservations are lazily expired when their listing is read or the endpoint is called)
- Inquiry module: start/get thread, poll messages, send message
- `POST /listings/:id/sold` — mark sold; validates seller ownership
- Authorization checks: buyer can only cancel own reservation; seller can cancel any on own listing; messages visible only to the two parties

*Flutter:*
- ReserveSheet, ReservationStatusSheet
- InboxScreen, InquiryThreadScreen (polling every 5 s while screen is active)
- MarkSoldScreen
- Riverpod providers for deals state

**Data models touched**
- Reservation, Inquiry, Message

**Dependencies**
- Feature 2 (auth + listings)

**Tests**
- API unit: reservation state machine — double-reserve (409), expired-then-new, seller cancel, buyer cancel
- API unit: reservation expiry on read path
- API integration: full reservation lifecycle
- API integration: inquiry thread — both parties can send/receive; third party gets 403
- API integration: mark sold requires owner + existing deal

**Done checklist**
- [ ] Only one ACTIVE reservation per listing enforced at DB + application level
- [ ] Expired reservations are detected on read and transition listing back to ACTIVE
- [ ] Double-reserve returns 409 with a clear error message
- [ ] Inquiry thread is scoped to (listing, buyer) pair; seller sees threads from buyer side
- [ ] Messages endpoint returns only new messages since a `since` cursor
- [ ] Mark-sold endpoint requires the listing to have a reservation or offer
- [ ] State machine unit tests cover all invalid transitions
- [ ] Flutter: reserve/cancel flow updates listing status chip in real time

---

### Feature 4 — AI Listing Assistant

**What it includes**

*API:*
- `lib/ai/` provider interface: `analyzeListingPhotos(images: Buffer[]) → ListingDraft`
- Concrete adapter: Claude claude-haiku-4-5-20251001 vision (or whichever vision model is live; key in env, never in code)
- `POST /ai/listing-draft`: accepts 1–6 photos (multipart), calls vision API, returns `{ title, categorySlug, attributes, description, suggestedPriceMin, suggestedPriceMax }`
- Timeout: 30 s hard timeout; on failure returns `{ error: "ai_unavailable" }` so the client can fall back to manual
- Rate limit: 5 requests per user per hour (separate limiter)
- The endpoint sends only the photos; no user PII is forwarded to the third-party API

*Flutter:*
- AiAssistScreen: photo upload → loading state → draft pre-fill → user edits → continues to DraftListingScreen
- Manual fallback: "Skip AI" button always visible; if AI returns error, shows toast and auto-falls back
- Displays suggested price range as a hint in the price field

**Data models touched**
- Listing (pre-fill only; not persisted until user confirms)

**Dependencies**
- Feature 2 (listings, photos)

**Tests**
- API unit: provider interface contract (mock adapter returning canned response)
- API unit: timeout → `ai_unavailable` response (not 500)
- API integration: rate-limit enforcement (6th request in an hour → 429)
- Flutter widget: AiAssistScreen shows pre-filled fields from mock response

**Done checklist**
- [ ] AI provider key is in `.env`, never committed
- [ ] Provider interface is a TypeScript interface; swapping the adapter requires no route changes
- [ ] Manual fallback works even when the AI adapter is not configured
- [ ] Response includes all 6 draft fields
- [ ] Rate limit: 5/hour per user; headers include `X-RateLimit-Remaining`
- [ ] Timeout returns structured error, not 500
- [ ] Privacy: only photos are sent; documented in README

---

### Feature 5 — Offers, Reviews, Seller Reputation

**What it includes**

*API:*
- Offers module: make, list, accept, decline, cancel; expiry on read
- On offer accepted: all other PENDING offers on the listing → DECLINED automatically; listing → SOLD; reservation (if any) → CANCELLED
- Reviews module: `POST /listings/:id/reviews` — only allowed if the buyer has a COMPLETED reservation or an ACCEPTED offer; enforced server-side
- Seller stats: `completedDealCount` and `responseRate` updated after each deal; `GET /users/:id` returns these
- `GET /users/:id/reviews` — paginated

*Flutter:*
- MakeOfferSheet, OffersListScreen (seller view), OfferDetailSheet
- LeaveReviewScreen (shown after deal completes)
- ReviewsListScreen
- SellerProfileScreen (shows stats + reviews)

**Data models touched**
- Offer, Review, User (completedDealCount, responseRate)

**Dependencies**
- Feature 3 (deals, reservation)

**Tests**
- API unit: offer state machine — double-offer (409), expired offer, accept cascades declines, accept on SOLD listing (409)
- API unit: review gate — buyer without completed deal gets 403
- API integration: full offer lifecycle (make → accept → review)
- API integration: concurrent offer scenario (two buyers, seller accepts one)

**Done checklist**
- [ ] Buyer cannot make a second PENDING offer on the same listing
- [ ] Accepting an offer auto-declines all other pending offers (atomic transaction)
- [ ] Review is only possible after a confirmed deal (COMPLETED reservation or ACCEPTED offer)
- [ ] `completedDealCount` increments exactly once per deal
- [ ] `responseRate` = (messages replied within 24 h) / (total inquiry threads) — updated on message send
- [ ] All offer state machine transitions covered by unit tests

---

### Feature 6 — Listing Check Badge, Reports, Admin Review Screen

**What it includes**

*API:*
- `lib/listing-check/` — pure functions, no DB calls:
  - `computeDhash(buffer: Buffer): string` — 8×8 dHash via sharp
  - `detectDuplicate(dhash: string, existingHashes: string[]): boolean` — Hamming distance ≤ 10
  - `flagSuspiciousText(text: string): string[]` — patterns in `listing-check.config.ts` (deposit-first, GCash/bank-only, off-platform contact, Taglish scam phrases)
  - `checkNewSeller(user: User): boolean`
  - `checkPrice(price: number, category: string, refPrices: ReferencePrice[]): string | null`
  - `computeScore(signals: CheckSignals): CheckResult` — weights in config file
- `CheckResult` = `{ score: number, level: "LOW"|"MEDIUM"|"HIGH", reasons: string[] }`
- Listing check runs automatically on `POST /listings/:id/publish` and `PATCH /listings/:id`; result stored in `Listing.checkScore/Level/Reasons`
- Reports module: `POST /listings/:id/reports`
- Admin module: list/filter reports, update report status, force listing status change

*Flutter:*
- `KomBadge` (already built in Feature 1) surfaces level + icon + label
- ListingDetailScreen gets badge + "Why?" tap → ListingCheckBadgeSheet (shows reasons)
- ReportSheet (bottom sheet on listing detail)
- AdminReportsScreen, AdminListingsScreen, AdminReportDetailScreen (guarded by admin role)

**Data models touched**
- Listing (checkScore, checkLevel, checkReasons), ListingPhoto (dhash), Report, ReferencePrice

**Dependencies**
- Feature 2 (listings, photos)

**Tests**
- Unit: dHash computation is deterministic
- Unit: `detectDuplicate` — identical image, one-bit diff, threshold boundary
- Unit: `flagSuspiciousText` — each pattern category hits and misses
- Unit: `computeScore` — LOW/MEDIUM/HIGH boundary weights
- Unit: price-check with reference data
- Integration: publish endpoint runs check and stores result
- Flutter: badge renders correct icon + color + label for all three levels (no color-only)

**Done checklist**
- [ ] All listing-check functions are pure (no side effects, no DB inside)
- [ ] Weights and patterns are in one config file, not scattered in logic
- [ ] dHash stored on photo save; duplicate checked against all active listing photos
- [ ] Badge never uses color alone: icon + text label always present
- [ ] Semantic badge colors distinct from brand green (teal for LOW, amber for MEDIUM, red for HIGH)
- [ ] Admin endpoints require `role == ADMIN`; non-admins get 403
- [ ] Admin role seeded on one demo account
- [ ] Unit test coverage ≥ 90% on listing-check module

---

### Feature 7 — Saved Searches with In-App Alerts, Sort by Nearest

**What it includes**

*API:*
- Saved searches CRUD endpoints
- `GET /saved-searches/alerts` — polling endpoint; returns new listing IDs since `lastAlertAt`; updates `lastAlertAt`
- Sort by nearest already implemented in Feature 2 (`sortBy=nearest`); this feature adds the saved-search filtering to it

*Flutter:*
- SavedSearchesScreen
- Alert indicator on BrowseScreen tab badge (shown when alerts exist)
- Riverpod provider polling `/saved-searches/alerts` every 60 s while app is in foreground

**Data models touched**
- SavedSearch

**Dependencies**
- Feature 2 (listings, search)

**Tests**
- API integration: save search → create listing matching filters → poll alerts → alert returned
- API integration: `lastAlertAt` updates so second poll returns empty
- Flutter: alert badge appears/disappears correctly

**Done checklist**
- [ ] Saved searches are user-scoped (cannot read another user's)
- [ ] Alert poll is idempotent (calling twice within the same second returns same or empty)
- [ ] Sort by nearest (`lat`, `lng` required in query; falls back to newest if coords absent) works with and without saved searches
- [ ] Flutter: polling pauses when app is backgrounded (AppLifecycleListener)

---

### Feature 8 — Deploy, README, Evaluation

**What it includes**

*Deploy:*
- `README.md` with: project overview, local setup, env vars, seed instructions, privacy notes (AI sends photos only)
- Render/Railway deployment config for the API; Cloudinary production keys documented in `.env.example`
- Production Postgres connection + migration run in deploy step

*Evaluation (`docs/EVALUATION.md`):*
- (a) Listing time: ≥10 manual runs with AI assistant, ≥10 without; median and range reported
- (b) Search relevance: 20 test queries against seeded data; relevant/not-relevant judgment recorded
- (c) Listing-check coverage: test suite results + a 20-entry synthetic test set (10 clean, 10 flagged)
- All results marked "seeded/demo data only, not real-world performance"

**Data models touched**
- None

**Dependencies**
- All previous features

**Done checklist**
- [ ] `README.md` covers setup, env vars, seed, and privacy notes
- [ ] `.env.example` has every env var with a comment
- [ ] No secrets or sensitive data in repo
- [ ] `docs/EVALUATION.md` has all three evaluation sections with stated sample sizes
- [ ] API deployed and health endpoint returns 200 from public URL
- [ ] Seed script runs cleanly on production DB

---

## 7. Cut Order (if behind)

Never cut: tests, CI, README, contrast test.

Cut from bottom up:
1. Saved-search alerts (keep the saved-search CRUD, drop the polling alert)
2. Sort by nearest (keep newest/price sort; remove Haversine)
3. Counter-offers (keep make/accept/decline; remove counter flow)
4. Response-rate stat (keep completedDealCount; drop responseRate)
5. Admin screen polish (keep bare-minimum: list + status update)

---

## 8. Open Questions / Notes

1. **OpenAPI client generation for Flutter** — `openapi-generator` with the `dart-dio` template is an option, but the generated code is often noisy. Plan is to generate once, review the output, and decide at Feature 2 start whether to use it or hand-write typed models. Will flag before deciding.

2. **dHash library** — `blockhash-core` and `imghash` npm packages are either unmaintained or have thin test coverage. Plan is to implement dHash directly with `sharp` (8×8 grayscale resize + horizontal gradient bits), which is ~30 lines and has no external dependency risk. Will confirm before Feature 6.

3. **Expiry without a cron** — Reservations and offers are expired lazily on read. This means a listing may show as RESERVED in the feed for up to a few seconds after its reservation expires, but it will auto-correct on next fetch. This is acceptable for an MVP; a background job can be added later.

4. **Semaphore SMS** — The OTP module will use a `SmsProvider` interface from day one. The dev adapter logs the OTP to stdout. The Semaphore adapter is a stub that can be activated by setting `SMS_PROVIDER=semaphore` in env.

5. **LLM vision model** — The AI adapter will default to Claude claude-haiku-4-5-20251001 (fast, low cost). The provider interface makes swapping trivial. The model ID will be in env, not hardcoded.
