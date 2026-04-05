const mongoose = require('mongoose');
require('dotenv').config();

const connectMongoDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI);
        console.log(`✅ MongoDB Connected`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1); // Exit with failure
    }
};

module.exports = connectMongoDB;