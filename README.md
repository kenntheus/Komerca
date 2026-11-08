# Komerca: Your Everyday Marketplace

A second-hand marketplace for the Philippines, built as a portfolio project. Komerca is designed to be faster and smoother than Facebook Marketplace and Carousell through AI-assisted listing, better search, and cleaner deal flows.

---

## Features

- **AI listing assistant:** upload photos and get a pre-filled title, category, description, and suggested price range
- **Full-text search:** Postgres full-text + trigram search with category filters and sort by newest, price, or nearest
- **Deals:** time-limited reservations, make/accept/decline offers, inquiry threads, mark as sold
- **Seller reputation:** post-deal reviews, completed deal count, response rate
- **Listing check badge:** lightweight duplicate photo detection, suspicious-text flags, and price sanity check shown as a LOW / MEDIUM / HIGH badge

---

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| API | Node.js, Express, TypeScript, PostgreSQL, Prisma, Zod, JWT |
| Mobile | Flutter, Dart, Riverpod, go_router, Dio |
| Images | Cloudinary (direct upload from app; local disk adapter for dev) |
| AI | LLM vision API behind a provider interface (key stays server-side) |
| CI | GitHub Actions |

---

## Project Structure

```
komerca/
├── apps/
│   ├── api/          # Node.js + Express API
│   └── mobile/       # Flutter app
├── docs/             # Architecture diagram, OpenAPI spec, evaluation
└── PLAN.md           # Full feature plan and data model
```

---

## Local Setup

### Prerequisites

- Node.js 22+
- Flutter 3.x
- PostgreSQL 16+

### API

```bash
cd apps/api
cp .env.example .env        # fill in DATABASE_URL and JWT secrets
npm install
npx prisma db push          # create tables from schema
npx prisma db seed          # optional: load demo data
npm run dev                 # starts on port 3000
```

**Run tests**

```bash
npm test
```

**Lint and typecheck**

```bash
npm run lint
npm run typecheck
```

### Mobile

```bash
cd apps/mobile
flutter pub get
flutter run                 # pick a device or emulator
```

**Run tests**

```bash
flutter test                # includes WCAG contrast test
```

---

## Environment Variables

Copy `apps/api/.env.example` to `apps/api/.env` and fill in the values.

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_ACCESS_SECRET` | Secret for access tokens (min 32 chars) |
| `JWT_REFRESH_SECRET` | Secret for refresh tokens (min 32 chars) |
| `IMAGE_STORAGE` | `local` (dev) or `cloudinary` (production) |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `SMS_PROVIDER` | `mock` (logs OTP to stdout) or `semaphore` |
| `SEMAPHORE_API_KEY` | Semaphore SMS API key |
| `AI_PROVIDER` | `mock` (canned response) or `claude` |
| `AI_API_KEY` | AI provider API key |
| `AI_MODEL` | Model ID (default: `claude-haiku-4-5-20251001`) |

---

## Privacy Notes

- **OTP login:** phone numbers are stored only to identify accounts. No government IDs or sensitive personal data are collected, in line with the Philippines Data Privacy Act.
- **AI listing assistant:** only the listing photos you upload are sent to the third-party AI API. No user profile data, phone numbers, or personal information are included in those requests. This is enforced at the API route level.
- **Images:** photos are uploaded directly from the app to Cloudinary using a signed URL. The API never stores the raw image bytes.

---

## Design System

Brand colors: **Forest Green `#1F3D2B`** and **Sand Beige `#E8DCC4`**.

All color tokens are defined once in `apps/mobile/lib/core/theme/app_colors.dart`. No hard-coded hex values anywhere else in the UI. All main color pairs pass WCAG AA (4.5:1 minimum contrast ratio), enforced by a CI test.

---

## Status

| Feature | Status |
|---------|--------|
| Scaffold, CI, theme, component gallery | Done |
| Auth, categories, listings, search | Next |
| Deals (reserve, inquiries, sold) | Pending |
| AI listing assistant | Pending |
| Offers, reviews, reputation | Pending |
| Listing check badge, reports, admin | Pending |
| Saved searches, sort by nearest | Pending |
| Deploy, evaluation | Pending |

---

## License

Personal portfolio project, not licensed for redistribution.
