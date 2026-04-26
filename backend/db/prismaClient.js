const { PrismaClient } = require("@prisma/client");

// Fallback to local sqlite for development without requiring DIRECT_DATABASE_URL
let prisma;
try {
  const { env } = require("prisma/config");
  const { PrismaPg } = require("@prisma/adapter-pg");
  prisma = new PrismaClient({
    adapter: new PrismaPg(env("DIRECT_DATABASE_URL")),
  });
} catch (e) {
  // Use default Prisma client without adapter if config fails
  prisma = new PrismaClient();
}

module.exports = prisma;
