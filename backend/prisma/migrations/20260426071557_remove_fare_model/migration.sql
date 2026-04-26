/*
  Warnings:

  - You are about to drop the `fares` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "fares" DROP CONSTRAINT "fares_rideId_fkey";

-- DropForeignKey
ALTER TABLE "fares" DROP CONSTRAINT "fares_userId_fkey";

-- DropTable
DROP TABLE "fares";
