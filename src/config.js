const path = require('path');
const crypto = require('crypto');

// Load .env file if it exists
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Generate default token if none exists
const generateDefaultToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

const config = {
  // Server configuration
  port: parseInt(process.env.PORT || '8099', 10),
  host: process.env.HOST || '0.0.0.0',

  // Printer configuration
  printerIp: process.env.PRINTER_IP || '10.1.55.150',
  printerPort: parseInt(process.env.PRINTER_PORT || '9100', 10),

  // Security
  authToken: process.env.AUTH_TOKEN || generateDefaultToken(),

  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',

  // Queue configuration
  maxRetries: parseInt(process.env.MAX_RETRIES || '3', 10),
  retryDelay: parseInt(process.env.RETRY_DELAY_MS || '2000', 10)
};

module.exports = config;
