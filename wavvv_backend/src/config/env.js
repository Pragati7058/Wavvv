const dotenv = require('dotenv');
const joi = require('joi');
const path = require('path');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../../.env') });

const envVarsSchema = joi.object()
  .keys({
    NODE_ENV: joi.string().valid('development', 'production', 'test').default('development'),
    PORT: joi.number().default(3000),
    MONGODB_URI: joi.string().required().description('MongoDB connection URI'),
    JWT_SECRET: joi.string().required().min(8).description('JWT secret key'),
    FIREBASE_PROJECT_ID: joi.string().required().description('Firebase Project ID'),
    FIREBASE_PRIVATE_KEY: joi.string().required().description('Firebase Private Key'),
    FIREBASE_CLIENT_EMAIL: joi.string().required().email().description('Firebase Client Email'),
    YOUTUBE_API_KEY: joi.string().required().description('YouTube API Key'),
    CLIENT_URL: joi.string().required().description('Client URL for CORS'),
  })
  .unknown();

const { value: envVars, error } = envVarsSchema.validate(process.env);

if (error) {
  throw new Error(`Config validation error: ${error.message}`);
}

module.exports = {
  env: envVars.NODE_ENV,
  port: envVars.PORT,
  mongoose: {
    url: envVars.MONGODB_URI,
  },
  jwt: {
    secret: envVars.JWT_SECRET,
  },
  firebase: {
    projectId: envVars.FIREBASE_PROJECT_ID,
    privateKey: envVars.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    clientEmail: envVars.FIREBASE_CLIENT_EMAIL,
  },
  youtubeApiKey: envVars.YOUTUBE_API_KEY,
  clientUrl: envVars.CLIENT_URL,
};
