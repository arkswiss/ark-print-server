# ARK Print Server

**Local print server for ARK Stock ZPL printers**

A standalone, lightweight print server that allows ARK Stock cloud instances to communicate with local ZPL printers (Zebra, etc.) securely via HTTPS.

---

## 🎯 Purpose

This print server solves the problem of connecting cloud-hosted ARK Stock instances to local network printers. It acts as a bridge between your cloud application and your local ZPL printer.

```
[ARK Stock Cloud Instance]
        ↓ HTTPS (secure)
   [Print Server] (your local network)
        ↓ TCP 9100
   [ZPL Printer] (10.1.55.150)
```

---

## ✨ Features

- ✅ **Simple setup** - Just download and run
- ✅ **Secure authentication** - Token-based API security
- ✅ **Web UI** - Easy configuration interface
- ✅ **Auto-retry** - Handles temporary network issues
- ✅ **Logging** - Full audit trail of print jobs
- ✅ **Cross-platform** - Windows, Mac, Linux, Raspberry Pi
- ✅ **Lightweight** - Minimal resource usage

---

## 🚀 Quick Start

### 1. Download

Download the appropriate version for your system:

- **Windows**: `ark-print-server-win.exe`
- **Mac**: `ark-print-server-mac`
- **Linux**: `ark-print-server-linux`

### 2. Configure

Create a `.env` file next to the executable:

```bash
# Printer Configuration
PRINTER_IP=10.1.55.150
PRINTER_PORT=9100

# Security Token (generate a random token)
AUTH_TOKEN=your-secure-token-here

# Server Port (default: 8099)
PORT=8099
```

To generate a secure token, run:

```bash
# On Linux/Mac
openssl rand -hex 32

# On Windows (PowerShell)
[System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

### 3. Run

**Windows:**
```bash
ark-print-server-win.exe
```

**Mac/Linux:**
```bash
chmod +x ark-print-server-mac  # or ark-print-server-linux
./ark-print-server-mac
```

### 4. Configure in ARK Stock

1. Open ARK Stock and go to **Profile > Print Settings**
2. In the ZPL section, enter:
   - **Print Server URL**: `http://localhost:8099` (or your server IP)
   - **Auth Token**: The token from your `.env` file
3. Click **Test Connection**
4. Save settings

---

## 🌐 Exposing the Server (for remote access)

If your ARK Stock instance is in the cloud, you need to expose the print server to the Internet securely.

### Option 1: Cloudflare Tunnel (Recommended ✅)

Cloudflare Tunnel provides free, secure HTTPS access without opening ports.

1. **Install cloudflared**:
   ```bash
   # Mac
   brew install cloudflare/cloudflare/cloudflared

   # Windows
   # Download from https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/

   # Linux
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. **Authenticate**:
   ```bash
   cloudflared tunnel login
   ```

3. **Create tunnel**:
   ```bash
   cloudflared tunnel create ark-print-server
   ```

4. **Configure tunnel** - Create `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <your-tunnel-id>
   credentials-file: /path/to/credentials.json

   ingress:
     - hostname: print.yourdomain.com
       service: http://localhost:8099
     - service: http_status:404
   ```

5. **Run tunnel**:
   ```bash
   cloudflared tunnel run ark-print-server
   ```

6. **Use in ARK Stock**:
   - Print Server URL: `https://print.yourdomain.com`

### Option 2: Reverse SSH Tunnel

If you have SSH access to your cloud server:

```bash
ssh -R 8099:localhost:8099 user@your-cloud-server.com
```

### Option 3: Port Forwarding + HTTPS

1. Forward port 8099 on your router
2. Use a service like Let's Encrypt for HTTPS
3. Configure a reverse proxy (nginx, Caddy)

---

## 📡 API Endpoints

### `GET /health`

Check server health (public, no auth required).

**Response:**
```json
{
  "success": true,
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 3600,
  "printer": {
    "ip": "10.1.55.150",
    "port": 9100
  }
}
```

### `POST /api/print`

Print a ZPL label (requires authentication).

**Headers:**
```
Authorization: Bearer your-auth-token
Content-Type: application/json
```

**Body:**
```json
{
  "zpl": "^XA^FO50,50^A0N,50,50^FDTEST^FS^XZ",
  "jobId": "optional-job-id",
  "metadata": {
    "productUid": "ABC-123",
    "user": "tech@ark.swiss"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Label printed successfully",
  "jobId": "550e8400-e29b-41d4-a716-446655440000"
}
```

### `POST /api/test`

Send a test print (requires authentication).

**Headers:**
```
Authorization: Bearer your-auth-token
```

**Response:**
```json
{
  "success": true,
  "message": "Test print sent successfully to printer"
}
```

### `GET /api/config`

Get current configuration (requires authentication).

**Response:**
```json
{
  "success": true,
  "config": {
    "printerIp": "10.1.55.150",
    "printerPort": 9100,
    "maxRetries": 3,
    "retryDelay": 2000,
    "logLevel": "info"
  }
}
```

### `POST /api/config`

Update configuration (requires authentication).

**Body:**
```json
{
  "printerIp": "10.1.55.150",
  "printerPort": 9100
}
```

---

## 🔧 Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8099` | Server port |
| `HOST` | `0.0.0.0` | Server host (0.0.0.0 = all interfaces) |
| `PRINTER_IP` | `10.1.55.150` | ZPL printer IP address |
| `PRINTER_PORT` | `9100` | ZPL printer port |
| `AUTH_TOKEN` | Auto-generated | API authentication token |
| `LOG_LEVEL` | `info` | Log level (error, warn, info, debug) |
| `MAX_RETRIES` | `3` | Max print attempts |
| `RETRY_DELAY_MS` | `2000` | Delay between retries (ms) |

---

## 📊 Logs

Logs are stored in the `logs/` directory:

- `combined.log` - All logs
- `error.log` - Errors only

---

## 🔒 Security Best Practices

1. **Use strong tokens** - Generate random 32+ character tokens
2. **Use HTTPS** - Always use HTTPS when exposing to Internet
3. **Firewall rules** - Restrict access to known IPs if possible
4. **Update regularly** - Keep the print server updated
5. **Monitor logs** - Check logs regularly for suspicious activity

---

## 🐛 Troubleshooting

### Printer not responding

1. Check printer IP and port are correct
2. Verify printer is on and connected to network
3. Try pinging the printer: `ping 10.1.55.150`
4. Check printer is in ZPL mode (not EPL)
5. Review logs in `logs/error.log`

### Connection timeout

- Increase timeout in `.env`: `TIMEOUT_MS=15000`
- Check network connectivity
- Verify firewall settings

### "Unauthorized" error

- Verify AUTH_TOKEN matches in both print server and ARK Stock
- Check Authorization header format: `Bearer your-token`

### Can't access from Internet

- Verify Cloudflare Tunnel is running
- Check port forwarding configuration
- Test with `curl http://your-server:8099/health`

---

## 🚀 Running as a Service

### Windows (Task Scheduler)

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger: "When the computer starts"
4. Action: "Start a program"
5. Program: `C:\path\to\ark-print-server-win.exe`

### Mac (launchd)

Create `~/Library/LaunchAgents/com.ark.printserver.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ark.printserver</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/ark-print-server-mac</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Load: `launchctl load ~/Library/LaunchAgents/com.ark.printserver.plist`

### Linux (systemd)

Create `/etc/systemd/system/ark-print-server.service`:

```ini
[Unit]
Description=ARK Print Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/ark-print-server
ExecStart=/home/ubuntu/ark-print-server/ark-print-server-linux
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable ark-print-server
sudo systemctl start ark-print-server
sudo systemctl status ark-print-server
```

---

## 📦 Building from Source

### Prerequisites

- Node.js 18+
- npm

### Steps

1. Clone repository
2. Install dependencies: `npm install`
3. Run in development: `npm run dev`
4. Build executables: `npm run build:all`

Executables will be in the `dist/` directory.

---

## 🤝 Support

For support, please contact **ARK Swiss** at [ark.swiss](https://ark.swiss)

---

## 📄 License

MIT License - © 2025 ARK Swiss
