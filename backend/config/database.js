/**
 * Database Configuration with Prisma ORM
 * Exports Prisma client for all database operations
 */

const prisma = require('../db/prismaClient');

/**
 * Initialize database connection
 * @returns {Promise<void>}
 */
const initDB = async () => {
  try {
    // Test the connection
    await prisma.$queryRaw`SELECT 1`;
    console.log('✅ Prisma: Database connected successfully');
  } catch (error) {
    console.error('❌ Prisma: Database connection error:', error.message);
    throw error;
  }
};

/**
 * Disconnect from database (useful for graceful shutdown)
 * @returns {Promise<void>}
 */
const disconnectDB = async () => {
  try {
    await prisma.$disconnect();
    console.log('✅ Prisma: Database disconnected');
  } catch (error) {
    console.error('❌ Prisma: Disconnection error:', error.message);
  }
};

module.exports = {
  prisma,
  initDB,
  disconnectDB
};
