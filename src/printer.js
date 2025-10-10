const net = require('net');
const logger = require('./logger');

// Print queue for managing print jobs
const printQueue = {
  pending: [],
  processing: null,
  completed: [],
  failed: []
};

/**
 * Print ZPL content to printer
 *
 * @param {string} zpl - ZPL content to print
 * @param {object} options - Print options
 * @param {string} options.ip - Printer IP address
 * @param {number} options.port - Printer port
 * @param {number} options.timeout - Connection timeout in ms
 * @param {number} options.maxRetries - Maximum number of retries
 * @param {number} options.retryDelay - Delay between retries in ms
 * @returns {Promise<void>}
 */
async function print(zpl, options = {}) {
  const {
    ip,
    port = 9100,
    timeout = 10000,
    maxRetries = 3,
    retryDelay = 2000
  } = options;

  if (!ip) {
    throw new Error('Printer IP address is required');
  }

  if (!zpl || typeof zpl !== 'string') {
    throw new Error('Invalid ZPL content');
  }

  let lastError;
  let attempt = 0;

  while (attempt < maxRetries) {
    attempt++;

    try {
      logger.info(`Attempting to print (attempt ${attempt}/${maxRetries})`, {
        ip,
        port,
        zplLength: zpl.length
      });

      await sendToPrinter(zpl, ip, port, timeout);

      logger.info('Print successful', { ip, port, attempt });
      return; // Success!

    } catch (error) {
      lastError = error;
      logger.warn(`Print attempt ${attempt} failed`, {
        ip,
        port,
        error: error.message,
        willRetry: attempt < maxRetries
      });

      if (attempt < maxRetries) {
        // Wait before retrying
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      }
    }
  }

  // All attempts failed
  throw new Error(
    `Failed to print after ${maxRetries} attempts: ${lastError.message}`
  );
}

/**
 * Send ZPL data to printer via TCP
 *
 * @param {string} zpl - ZPL content
 * @param {string} ip - Printer IP
 * @param {number} port - Printer port
 * @param {number} timeout - Timeout in ms
 * @returns {Promise<void>}
 */
function sendToPrinter(zpl, ip, port, timeout) {
  return new Promise((resolve, reject) => {
    const client = new net.Socket();
    let isResolved = false;

    // Set timeout
    client.setTimeout(timeout);

    // Connection successful
    client.connect(port, ip, () => {
      logger.debug('Connected to printer', { ip, port });

      // Send ZPL data
      client.write(zpl, 'utf8', (err) => {
        if (err) {
          if (!isResolved) {
            isResolved = true;
            client.destroy();
            reject(new Error(`Failed to write to printer: ${err.message}`));
          }
        } else {
          logger.debug('ZPL data sent to printer', { ip, port });
          // Don't close immediately, wait for confirmation or timeout
        }
      });
    });

    // Data received from printer (optional, some printers send confirmation)
    client.on('data', (data) => {
      logger.debug('Received data from printer', {
        ip,
        port,
        data: data.toString()
      });
    });

    // Connection closed
    client.on('close', () => {
      logger.debug('Connection closed', { ip, port });
      if (!isResolved) {
        isResolved = true;
        resolve();
      }
    });

    // Connection ended
    client.on('end', () => {
      logger.debug('Connection ended', { ip, port });
      if (!isResolved) {
        isResolved = true;
        resolve();
      }
    });

    // Timeout
    client.on('timeout', () => {
      logger.warn('Connection timeout', { ip, port, timeout });
      if (!isResolved) {
        isResolved = true;
        client.destroy();
        reject(new Error(`Connection timeout after ${timeout}ms`));
      }
    });

    // Error
    client.on('error', (err) => {
      logger.error('Printer connection error', {
        ip,
        port,
        error: err.message
      });

      if (!isResolved) {
        isResolved = true;
        client.destroy();
        reject(new Error(`Printer connection error: ${err.message}`));
      }
    });

    // After sending, wait a bit then close
    setTimeout(() => {
      if (!isResolved) {
        client.end();
        // Give it another moment to close gracefully
        setTimeout(() => {
          if (!isResolved) {
            isResolved = true;
            client.destroy();
            resolve();
          }
        }, 500);
      }
    }, 1000);
  });
}

/**
 * Get queue status
 *
 * @returns {object} Queue status
 */
function getQueueStatus() {
  return {
    pending: printQueue.pending.length,
    processing: printQueue.processing ? 1 : 0,
    completed: printQueue.completed.length,
    failed: printQueue.failed.length,
    recentCompleted: printQueue.completed.slice(-10),
    recentFailed: printQueue.failed.slice(-10)
  };
}

module.exports = {
  print,
  getQueueStatus
};
