const pool = require('./db');
const fs = require('fs');
const path = require('path');

async function initDB() { 
    try {
        
        const sqlPath = path.join(__dirname, 'migrations', 'init_schema.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8'); 

        await pool.query(sql);
        console.log('PostgreSQL tables initialized successfully... 👑');

    } catch (error) {
        // Log error but don't crash - tables might already exist
        console.warn('PostgreSQL init warning (this is OK if tables already exist):', error);
        // Don't exit on failure - let the server continue
    }
}

module.exports = initDB;