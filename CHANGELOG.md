# Changelog

All notable changes to ARK Print Server will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-10

### Added
- Initial release of ARK Print Server
- Express REST API with authentication
- Web UI for printer configuration
- TCP/IP communication with ZPL printers
- Automatic retry mechanism on connection failures
- Complete logging system with Winston
- Health check endpoint
- Queue management for print jobs
- Support for Windows, macOS, and Linux
- Token-based authentication
- Configuration management via web UI and API
- Test print functionality
- Multi-language support preparation
- Comprehensive documentation

### Security
- Secure token authentication for all API endpoints
- Token stored as private field in configuration
- HTTPS support via Cloudflare Tunnel
- No direct network exposure required

### Documentation
- Complete README with installation guide
- API documentation
- Troubleshooting section
- Security best practices
- Examples for all major operating systems
