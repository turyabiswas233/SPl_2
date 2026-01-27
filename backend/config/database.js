/**
 * Database Configuration
 * Exports PostgreSQL pool and MongoDB connection
 */

const pool = require('../db/db');
const mongoose = require('../db/mongoose');
const initDB = require('../db/initpsql');

module.exports = {
  pool,
  mongoose,
  initDB
};
