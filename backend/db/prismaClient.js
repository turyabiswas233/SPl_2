const { PrismaClient } = require("@prisma/client");
const { env } = require("prisma/config");
const { PrismaPg } = require("@prisma/adapter-pg");

const prisma = new PrismaClient({
  adapter: new PrismaPg(env("DIRECT_DATABASE_URL")),
});

module.exports = prisma;
