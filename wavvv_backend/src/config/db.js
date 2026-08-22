const mongoose = require('mongoose');
const config = require('./env');

const connectDB = async () => {
  try {
    if (config.env === 'development') {
      mongoose.set('debug', true);
    }
    
    await mongoose.connect(config.mongoose.url);
    console.log('MongoDB Connected Successfully.');
  } catch (error) {
    console.error('MongoDB Connection Error:', error.message);
    process.exit(1);
  }
};

module.exports = connectDB;
