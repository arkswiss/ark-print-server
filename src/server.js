#!/usr/bin/env node

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const printer = require('./printer');
const logger = require('./logger');
const config = require('./config');

const app = express();

// Middleware
app.use(helmet({
  contentSecurityPolicy: false // Pour permettre l'interface web
}));
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Authentication middleware
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token || token !== config.authToken) {
    logger.warn('Unauthorized access attempt', { ip: req.ip });
    return res.status(401).json({
      success: false,
      error: 'Unauthorized - Invalid or missing token'
    });
  }

  next();
};

// ============================================
// API Routes
// ============================================

/**
 * Health check endpoint
 * Public - no authentication required
 */
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    version: require('../package.json').version,
    uptime: process.uptime(),
    printer: {
      ip: config.printerIp,
      port: config.printerPort
    }
  });
});

/**
 * Get server configuration
 * Requires authentication
 */
app.get('/api/config', authenticate, (req, res) => {
  res.json({
    success: true,
    config: {
      printerIp: config.printerIp,
      printerPort: config.printerPort,
      maxRetries: config.maxRetries,
      retryDelay: config.retryDelay,
      logLevel: config.logLevel
    }
  });
});

/**
 * Update server configuration
 * Requires authentication
 */
app.post('/api/config', authenticate, (req, res) => {
  const { printerIp, printerPort } = req.body;

  if (printerIp) {
    config.printerIp = printerIp;
  }

  if (printerPort) {
    config.printerPort = parseInt(printerPort, 10);
  }

  // Save to .env file
  const envPath = path.join(__dirname, '../.env');
  let envContent = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';

  if (printerIp) {
    envContent = envContent.replace(/PRINTER_IP=.*/g, `PRINTER_IP=${printerIp}`) ||
                 envContent + `\nPRINTER_IP=${printerIp}`;
  }

  if (printerPort) {
    envContent = envContent.replace(/PRINTER_PORT=.*/g, `PRINTER_PORT=${printerPort}`) ||
                 envContent + `\nPRINTER_PORT=${printerPort}`;
  }

  fs.writeFileSync(envPath, envContent);

  logger.info('Configuration updated', { printerIp, printerPort });

  res.json({
    success: true,
    message: 'Configuration updated successfully',
    config: {
      printerIp: config.printerIp,
      printerPort: config.printerPort
    }
  });
});

/**
 * Test printer connection
 * Requires authentication
 */
app.post('/api/test', authenticate, async (req, res) => {
  try {
    const testZpl = '^XA^FO50,50^A0N,50,50^FDTEST PRINT^FS^XZ';

    await printer.print(testZpl, {
      ip: config.printerIp,
      port: config.printerPort,
      timeout: 5000
    });

    logger.info('Test print successful');

    res.json({
      success: true,
      message: 'Test print sent successfully to printer'
    });
  } catch (error) {
    logger.error('Test print failed', { error: error.message });

    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Print ZPL label
 * Requires authentication
 *
 * Body:
 * {
 *   "zpl": "^XA^FO50,50^A0N,50,50^FDTEST^FS^XZ",
 *   "jobId": "optional-job-id",
 *   "metadata": { ... }
 * }
 */
app.post('/api/print', authenticate, async (req, res) => {
  const { zpl, jobId = uuidv4(), metadata = {} } = req.body;

  if (!zpl || typeof zpl !== 'string') {
    return res.status(400).json({
      success: false,
      error: 'Missing or invalid ZPL content'
    });
  }

  logger.info('Print job received', {
    jobId,
    zplLength: zpl.length,
    metadata
  });

  try {
    await printer.print(zpl, {
      ip: config.printerIp,
      port: config.printerPort,
      timeout: 10000,
      maxRetries: config.maxRetries,
      retryDelay: config.retryDelay
    });

    logger.info('Print job completed successfully', { jobId });

    res.json({
      success: true,
      message: 'Label printed successfully',
      jobId
    });
  } catch (error) {
    logger.error('Print job failed', {
      jobId,
      error: error.message,
      stack: error.stack
    });

    res.status(500).json({
      success: false,
      error: `Failed to print label: ${error.message}`,
      jobId
    });
  }
});

/**
 * Get print queue status
 * Requires authentication
 */
app.get('/api/queue', authenticate, (req, res) => {
  res.json({
    success: true,
    queue: printer.getQueueStatus()
  });
});

// ============================================
// Web UI - Serve static files
// ============================================

app.use(express.static(path.join(__dirname, 'web-ui')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'web-ui', 'index.html'));
});

// ============================================
// Error handling
// ============================================

app.use((err, req, res, next) => {
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    path: req.path
  });

  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// ============================================
// Start server
// ============================================

const PORT = config.port;
const HOST = config.host;

app.listen(PORT, HOST, () => {
  logger.info(`ARK Print Server started`, {
    port: PORT,
    host: HOST,
    printer: `${config.printerIp}:${config.printerPort}`,
    authToken: config.authToken ? '✓ Configured' : '✗ Missing'
  });

  console.log('');
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║                                                        ║');
  console.log('║           🖨️  ARK Print Server Running  🖨️             ║');
  console.log('║                                                        ║');
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log('');
  console.log(`  📍 Web UI:        http://localhost:${PORT}`);
  console.log(`  🔌 API Endpoint:  http://localhost:${PORT}/api/print`);
  console.log(`  🖨️  Printer:       ${config.printerIp}:${config.printerPort}`);
  console.log(`  🔐 Auth Token:    ${config.authToken ? '✓ Configured' : '✗ Not configured'}`);
  console.log('');
  console.log('  Press Ctrl+C to stop the server');
  console.log('');

  if (!config.authToken || config.authToken === 'your-secure-token-here') {
    console.log('⚠️  WARNING: No secure auth token configured!');
    console.log('   Please set AUTH_TOKEN in your .env file');
    console.log('');
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});
