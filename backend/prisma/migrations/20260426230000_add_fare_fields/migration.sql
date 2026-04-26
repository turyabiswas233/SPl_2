/*
  Warnings:

  - You are about to add the column `currency` to the `rides` table. The values you're trying to add may be too long for the column's type. You may need to change the type of the column or adjust the max length of the values.
  - You are about to add the column `totalFare` to the `rides` table. The values you're trying to add may be too long for the column's type. You may need to change the type of the column or adjust the max length of the values.
  - You made changes to the `ride_participants` table that may require data conversion. If conversion fails, the migration will stop at this point, leaving the database in an inconsistent state until fixed.

*/
-- CreateEnum
CREATE TYPE "PaymentType" AS ENUM ('ride_fare', 'deposit', 'subscription');

-- AlterTable
ALTER TABLE "ride_participants" ADD COLUMN "dropoffLat" DOUBLE PRECISION,
ADD COLUMN "dropoffLng" DOUBLE PRECISION,
ADD COLUMN "fare" DOUBLE PRECISION,
ADD COLUMN "pickupLat" DOUBLE PRECISION,
ADD COLUMN "pickupLng" DOUBLE PRECISION;

-- AlterTable
ALTER TABLE "rides" ADD COLUMN "currency" TEXT NOT NULL DEFAULT 'BDT',
ADD COLUMN "totalFare" DOUBLE PRECISION;
