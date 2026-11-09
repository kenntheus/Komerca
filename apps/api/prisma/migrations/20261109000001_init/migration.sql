-- Enable fuzzy-search extension
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── Enums ──────────────────────────────────────────────────────────────────

CREATE TYPE "UserRole" AS ENUM ('BUYER', 'SELLER', 'ADMIN');
CREATE TYPE "ListingCondition" AS ENUM ('NEW', 'LIKE_NEW', 'GOOD', 'FAIR', 'FOR_PARTS');
CREATE TYPE "ListingStatus" AS ENUM ('DRAFT', 'ACTIVE', 'RESERVED', 'SOLD', 'REMOVED');
CREATE TYPE "ReservationStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELLED', 'COMPLETED');
CREATE TYPE "OfferStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'CANCELLED');
CREATE TYPE "ReportReason" AS ENUM ('SPAM', 'FAKE', 'OFFENSIVE', 'SCAM', 'OTHER');
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'REVIEWED', 'DISMISSED', 'REMOVED');

-- ── Tables ─────────────────────────────────────────────────────────────────

CREATE TABLE "User" (
    "id"                 TEXT NOT NULL,
    "phone"              TEXT NOT NULL,
    "name"               TEXT NOT NULL,
    "avatarUrl"          TEXT,
    "city"               TEXT,
    "role"               "UserRole" NOT NULL DEFAULT 'BUYER',
    "completedDealCount" INTEGER NOT NULL DEFAULT 0,
    "responseRate"       DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt"          TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"          TIMESTAMP(3) NOT NULL,
    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

CREATE TABLE "OtpToken" (
    "id"        TEXT NOT NULL,
    "userId"    TEXT NOT NULL,
    "code"      TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "used"      BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "OtpToken_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "OtpToken_userId_idx" ON "OtpToken"("userId");

CREATE TABLE "RefreshToken" (
    "id"        TEXT NOT NULL,
    "userId"    TEXT NOT NULL,
    "token"     TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "RefreshToken_token_key" ON "RefreshToken"("token");
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

CREATE TABLE "Category" (
    "id"        TEXT NOT NULL,
    "slug"      TEXT NOT NULL,
    "name"      TEXT NOT NULL,
    "iconName"  TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Category_slug_key" ON "Category"("slug");

CREATE TABLE "Listing" (
    "id"           TEXT NOT NULL,
    "sellerId"     TEXT NOT NULL,
    "categoryId"   TEXT NOT NULL,
    "title"        TEXT NOT NULL,
    "description"  TEXT NOT NULL,
    "price"        DECIMAL(10,2) NOT NULL,
    "condition"    "ListingCondition" NOT NULL,
    "city"         TEXT NOT NULL,
    "lat"          DOUBLE PRECISION,
    "lng"          DOUBLE PRECISION,
    "attributes"   JSONB NOT NULL,
    "status"       "ListingStatus" NOT NULL DEFAULT 'DRAFT',
    "viewCount"    INTEGER NOT NULL DEFAULT 0,
    "searchVector" tsvector,
    "checkScore"   DOUBLE PRECISION,
    "checkLevel"   TEXT,
    "checkReasons" JSONB,
    "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"    TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Listing_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Listing_sellerId_idx"   ON "Listing"("sellerId");
CREATE INDEX "Listing_categoryId_idx" ON "Listing"("categoryId");
CREATE INDEX "Listing_status_idx"     ON "Listing"("status");
CREATE INDEX "Listing_city_idx"       ON "Listing"("city");
CREATE INDEX "Listing_price_idx"      ON "Listing"("price");
CREATE INDEX "Listing_createdAt_idx"  ON "Listing"("createdAt");
CREATE INDEX "Listing_searchVector_idx" ON "Listing" USING GIN("searchVector");
CREATE INDEX "Listing_title_trgm_idx"   ON "Listing" USING GIN("title" gin_trgm_ops);

CREATE TABLE "ListingPhoto" (
    "id"        TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "url"       TEXT NOT NULL,
    "publicId"  TEXT NOT NULL,
    "dhash"     TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "ListingPhoto_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ListingPhoto_listingId_idx" ON "ListingPhoto"("listingId");
CREATE INDEX "ListingPhoto_dhash_idx"     ON "ListingPhoto"("dhash");

CREATE TABLE "Reservation" (
    "id"        TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "buyerId"   TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "status"    "ReservationStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Reservation_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Reservation_listingId_key" ON "Reservation"("listingId");
CREATE INDEX "Reservation_buyerId_idx" ON "Reservation"("buyerId");

CREATE TABLE "Offer" (
    "id"        TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "buyerId"   TEXT NOT NULL,
    "amount"    DECIMAL(10,2) NOT NULL,
    "message"   TEXT,
    "status"    "OfferStatus" NOT NULL DEFAULT 'PENDING',
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Offer_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Offer_listingId_idx" ON "Offer"("listingId");
CREATE INDEX "Offer_buyerId_idx"   ON "Offer"("buyerId");

CREATE TABLE "Inquiry" (
    "id"        TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "buyerId"   TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Inquiry_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Inquiry_listingId_buyerId_key" ON "Inquiry"("listingId", "buyerId");
CREATE INDEX "Inquiry_buyerId_idx" ON "Inquiry"("buyerId");

CREATE TABLE "Message" (
    "id"        TEXT NOT NULL,
    "inquiryId" TEXT NOT NULL,
    "senderId"  TEXT NOT NULL,
    "body"      TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Message_inquiryId_idx" ON "Message"("inquiryId");

CREATE TABLE "Review" (
    "id"        TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "authorId"  TEXT NOT NULL,
    "sellerId"  TEXT NOT NULL,
    "rating"    INTEGER NOT NULL,
    "comment"   TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Review_listingId_authorId_key" ON "Review"("listingId", "authorId");
CREATE INDEX "Review_sellerId_idx" ON "Review"("sellerId");

CREATE TABLE "Report" (
    "id"         TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "listingId"  TEXT NOT NULL,
    "targetId"   TEXT NOT NULL,
    "reason"     "ReportReason" NOT NULL,
    "details"    TEXT,
    "status"     "ReportStatus" NOT NULL DEFAULT 'PENDING',
    "adminNote"  TEXT,
    "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"  TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Report_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Report_status_idx" ON "Report"("status");

CREATE TABLE "SavedSearch" (
    "id"          TEXT NOT NULL,
    "userId"      TEXT NOT NULL,
    "query"       TEXT NOT NULL,
    "filters"     JSONB NOT NULL,
    "lastAlertAt" TIMESTAMP(3),
    "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SavedSearch_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "SavedSearch_userId_idx" ON "SavedSearch"("userId");

CREATE TABLE "ReferencePrice" (
    "id"       TEXT NOT NULL,
    "model"    TEXT NOT NULL,
    "minPrice" DECIMAL(10,2) NOT NULL,
    "maxPrice" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'PHP',
    CONSTRAINT "ReferencePrice_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "ReferencePrice_model_key" ON "ReferencePrice"("model");

-- ── Foreign Keys ───────────────────────────────────────────────────────────

ALTER TABLE "OtpToken"
    ADD CONSTRAINT "OtpToken_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "RefreshToken"
    ADD CONSTRAINT "RefreshToken_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Listing"
    ADD CONSTRAINT "Listing_sellerId_fkey"
    FOREIGN KEY ("sellerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Listing"
    ADD CONSTRAINT "Listing_categoryId_fkey"
    FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ListingPhoto"
    ADD CONSTRAINT "ListingPhoto_listingId_fkey"
    FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Reservation"
    ADD CONSTRAINT "Reservation_listingId_fkey"
    FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Reservation"
    ADD CONSTRAINT "Reservation_buyerId_fkey"
    FOREIGN KEY ("buyerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Offer"
    ADD CONSTRAINT "Offer_listingId_fkey"
    FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Offer"
    ADD CONSTRAINT "Offer_buyerId_fkey"
    FOREIGN KEY ("buyerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Inquiry"
    ADD CONSTRAINT "Inquiry_listingId_fkey"
    FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Inquiry"
    ADD CONSTRAINT "Inquiry_buyerId_fkey"
    FOREIGN KEY ("buyerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Message"
    ADD CONSTRAINT "Message_inquiryId_fkey"
    FOREIGN KEY ("inquiryId") REFERENCES "Inquiry"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Message"
    ADD CONSTRAINT "Message_senderId_fkey"
    FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Review"
    ADD CONSTRAINT "Review_listingId_fkey"
    FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Review"
    ADD CONSTRAINT "Review_authorId_fkey"
    FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Review"
    ADD CONSTRAINT "Review_sellerId_fkey"
    FOREIGN KEY ("sellerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Report"
    ADD CONSTRAINT "Report_reporterId_fkey"
    FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Report"
    ADD CONSTRAINT "Report_listingId_fkey"
    FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Report"
    ADD CONSTRAINT "Report_targetId_fkey"
    FOREIGN KEY ("targetId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- ── Full-text search trigger ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION listings_search_vector_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW."searchVector" :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(NEW.city, '')), 'C');
  RETURN NEW;
END;
$$;

CREATE TRIGGER "listings_search_vector_trigger"
BEFORE INSERT OR UPDATE ON "Listing"
FOR EACH ROW EXECUTE FUNCTION listings_search_vector_update();
