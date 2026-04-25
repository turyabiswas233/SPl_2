-- CreateEnum
CREATE TYPE "AppRole" AS ENUM ('student', 'admin');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('unverified', 'verified', 'banned');

-- CreateEnum
CREATE TYPE "RideStatus" AS ENUM ('open', 'in_progress', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "GenderType" AS ENUM ('male', 'female', 'other');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('pending', 'resolved', 'dismissed');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('pending', 'accepted', 'rejected');

-- CreateEnum
CREATE TYPE "SOSAlertStatus" AS ENUM ('active', 'resolved');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded');

-- CreateEnum
CREATE TYPE "PaymentType" AS ENUM ('ride_fare', 'deposit', 'subscription');

-- CreateTable
CREATE TABLE "users" (
    "userId" UUID NOT NULL,
    "fullName" VARCHAR(100) NOT NULL,
    "email" VARCHAR(255),
    "password" VARCHAR(255),
    "phoneNumber" VARCHAR(15),
    "gender" VARCHAR(10),
    "role" "AppRole" NOT NULL DEFAULT 'student',
    "registrationNumber" VARCHAR(20),
    "deptName" VARCHAR(100),
    "hallName" VARCHAR(100),
    "verificationStatus" "UserStatus" NOT NULL DEFAULT 'unverified',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "rides" (
    "rideId" UUID NOT NULL,
    "initiatorId" UUID NOT NULL,
    "preferredGender" "GenderType" NOT NULL DEFAULT 'other',
    "startLocation" TEXT NOT NULL,
    "startLat" DOUBLE PRECISION NOT NULL,
    "startLng" DOUBLE PRECISION NOT NULL,
    "destinationName" TEXT NOT NULL,
    "destLat" DOUBLE PRECISION NOT NULL,
    "destLng" DOUBLE PRECISION NOT NULL,
    "tripQrCode" TEXT NOT NULL,
    "tripOtp" CHAR(6) NOT NULL,
    "maxSeats" INTEGER NOT NULL,
    "status" "RideStatus" NOT NULL DEFAULT 'open',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rides_pkey" PRIMARY KEY ("rideId")
);

-- CreateTable
CREATE TABLE "ride_participants" (
    "rideParticipantId" UUID NOT NULL,
    "rideId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "participantId" UUID NOT NULL,
    "meetingLat" DOUBLE PRECISION,
    "meetingLng" DOUBLE PRECISION,
    "hasMetBoolean" BOOLEAN NOT NULL DEFAULT false,
    "metAt" TIMESTAMPTZ,

    CONSTRAINT "ride_participants_pkey" PRIMARY KEY ("rideParticipantId")
);

-- CreateTable
CREATE TABLE "reports" (
    "reportId" UUID NOT NULL,
    "reporterId" UUID,
    "reportedId" UUID,
    "rideId" UUID,
    "issueType" TEXT NOT NULL,
    "status" "ReportStatus" NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reports_pkey" PRIMARY KEY ("reportId")
);

-- CreateTable
CREATE TABLE "notifications" (
    "notificationId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "rideId" UUID,
    "messageText" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("notificationId")
);

-- CreateTable
CREATE TABLE "ride_requests" (
    "requestId" UUID NOT NULL,
    "rideId" UUID NOT NULL,
    "requesterId" UUID NOT NULL,
    "status" "RequestStatus" NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ride_requests_pkey" PRIMARY KEY ("requestId")
);

-- CreateTable
CREATE TABLE "messages" (
    "messageId" UUID NOT NULL,
    "rideId" UUID NOT NULL,
    "senderId" UUID NOT NULL,
    "messageText" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("messageId")
);

-- CreateTable
CREATE TABLE "ratings" (
    "ratingId" UUID NOT NULL,
    "rideId" UUID NOT NULL,
    "raterId" UUID NOT NULL,
    "ratedUserId" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ratings_pkey" PRIMARY KEY ("ratingId")
);

-- CreateTable
CREATE TABLE "fares" (
    "fareId" UUID NOT NULL,
    "rideId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "paid" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fares_pkey" PRIMARY KEY ("fareId")
);

-- CreateTable
CREATE TABLE "sos_alerts" (
    "alertId" UUID NOT NULL,
    "rideId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "alertType" VARCHAR(50) NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "status" "SOSAlertStatus" NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sos_alerts_pkey" PRIMARY KEY ("alertId")
);

-- CreateTable
CREATE TABLE "payments" (
    "paymentId" VARCHAR(25) NOT NULL,
    "orderId" TEXT NOT NULL,
    "userId" UUID NOT NULL,
    "rideId" UUID,
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'BDT',
    "status" "PaymentStatus" NOT NULL DEFAULT 'pending',
    "transactionId" TEXT,
    "paymentMethod" TEXT,
    "customerName" TEXT,
    "customerEmail" TEXT,
    "customerPhone" TEXT,
    "aamarPayResponse" JSONB,
    "paymentStatus" TEXT,
    "paymentTime" TIMESTAMPTZ,
    "rideFare" DOUBLE PRECISION,
    "platformFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "paymentType" "PaymentType" NOT NULL DEFAULT 'ride_fare',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("paymentId")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_phoneNumber_key" ON "users"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "users_registrationNumber_key" ON "users"("registrationNumber");

-- CreateIndex
CREATE UNIQUE INDEX "rides_tripQrCode_key" ON "rides"("tripQrCode");

-- CreateIndex
CREATE UNIQUE INDEX "ride_participants_rideId_userId_participantId_key" ON "ride_participants"("rideId", "userId", "participantId");

-- CreateIndex
CREATE UNIQUE INDEX "ride_requests_rideId_requesterId_key" ON "ride_requests"("rideId", "requesterId");

-- CreateIndex
CREATE UNIQUE INDEX "ratings_rideId_raterId_ratedUserId_key" ON "ratings"("rideId", "raterId", "ratedUserId");

-- CreateIndex
CREATE UNIQUE INDEX "payments_orderId_key" ON "payments"("orderId");

-- AddForeignKey
ALTER TABLE "rides" ADD CONSTRAINT "rides_initiatorId_fkey" FOREIGN KEY ("initiatorId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_participants" ADD CONSTRAINT "ride_participants_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_participants" ADD CONSTRAINT "ride_participants_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_participants" ADD CONSTRAINT "ride_participants_participantId_fkey" FOREIGN KEY ("participantId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "users"("userId") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reportedId_fkey" FOREIGN KEY ("reportedId") REFERENCES "users"("userId") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ratings" ADD CONSTRAINT "ratings_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ratings" ADD CONSTRAINT "ratings_raterId_fkey" FOREIGN KEY ("raterId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ratings" ADD CONSTRAINT "ratings_ratedUserId_fkey" FOREIGN KEY ("ratedUserId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fares" ADD CONSTRAINT "fares_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fares" ADD CONSTRAINT "fares_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_alerts" ADD CONSTRAINT "sos_alerts_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_alerts" ADD CONSTRAINT "sos_alerts_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_rideId_fkey" FOREIGN KEY ("rideId") REFERENCES "rides"("rideId") ON DELETE SET NULL ON UPDATE CASCADE;
