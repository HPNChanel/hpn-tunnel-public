# 🚀 HPN Tunnel

**High-Performance Network Tunnel** - A blazing-fast, secure tunneling solution built with QUIC protocol.

## ✨ Features

- **⚡ Lightning Fast**: Built on QUIC protocol for maximum performance
- **🔒 Secure**: TLS encryption for all connections
- **🌐 Cross-Platform**: Works on Windows, macOS, and Linux
- **🎯 Simple**: Easy to install and use
- **🔄 Reliable**: Smart reconnection and authentication

## 📦 Installation

### Linux & macOS

```bash
curl -fsSL https://raw.githubusercontent.com/HPNChanel/hpn-tunnel-public/main/install.sh | bash
```

### Windows

```powershell
iwr -useb https://raw.githubusercontent.com/HPNChanel/hpn-tunnel-public/main/install.ps1 | iex
```

### Manual Installation

Download the latest release for your platform from the [Releases](https://github.com/HPNChanel/hpn-tunnel-public/releases) page.

## 🎮 Quick Start

### Start HTTP Tunnel

```bash
hpn http 8080
```

This will:
- Create a secure tunnel to your local port 8080
- Generate a public URL for sharing
- Display a QR code for easy mobile access

### Available Commands

```bash
hpn help          # Show help information
hpn version       # Show version information
hpn http <port>   # Start HTTP tunnel on specified port
```

## 📚 Documentation

- [Installation Guide](INSTALL.md)
- [Build From Source](BUILD.md)
- [Contributing](CONTRIBUTING.md)

## 💡 Use Cases

- **Web Development**: Share your local development server
- **API Testing**: Expose local APIs for testing
- **Webhooks**: Receive webhooks on your local machine
- **Team Collaboration**: Quick demos and testing

## 🔐 Security

HPN Tunnel uses industry-standard security practices:
- TLS 1.3 encryption
- QUIC protocol for secure, fast connections
- Optional authentication tokens
- No data logging

## 📄 License

HPN Tunnel is distributed under closed-source license. The binaries are free to use for personal and commercial purposes.

## 🤝 Support

- 📧 Email: support@hpntunnel.com
- 💬 Issues: [GitHub Issues](https://github.com/HPNChanel/hpn-tunnel-public/issues)
- 📖 Docs: [Documentation](https://docs.hpntunnel.com)

## ⚡ Why HPN Tunnel?

Unlike other tunneling solutions, HPN Tunnel offers:
- **Superior Performance**: QUIC protocol ensures minimal latency
- **Easy Setup**: One command to get started
- **Reliable**: Built-in reconnection and error handling
- **Modern**: Leverages cutting-edge networking technology

---

**Made with ❤️ by HPN Team**
