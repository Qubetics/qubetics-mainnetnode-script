# Qubetics Mainnet Node Setup

Scripts for setting up and managing a Qubetics blockchain node on Ubuntu and macOS.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Setup](#setup)
- [Verification](#verification)
- [Managing the Service](#managing-the-service)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Prerequisites

### System Requirements

- **CPU:** 4 or more physical cores
- **Storage:** At least 1TB disk space
- **Memory:** At least 16GB RAM
- **Network:** At least 100 Mbps bandwidth

### Supported Operating Systems

- Ubuntu 22.04 / 24.04
- macOS 14 / 15

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Qubetics/qubetics-mainnetnode-script.git
cd qubetics-mainnetnode-script
```

### 2. Install Go

Run the installation script (works for both macOS and Ubuntu):

```bash
./install-go.sh
```

**macOS users:** If Homebrew is not installed, run `./install-brew.sh` first.

## Setup

### Ubuntu

```bash
./qubetics_ubuntu_node.sh '<nodename>'
```

Example:
```bash
./qubetics_ubuntu_node.sh galaxynode
```

### macOS

```bash
./qubetics_mac_node.sh '<nodename>'
```

Example:
```bash
./qubetics_mac_node.sh galaxynode
```

> **Important:** The setup script will display your key mnemonics at the top of the JSON output. **Save these mnemonics in a secure location immediately.** You can also generate a new key with any EVM-compatible wallet.

## Verification

### Verify Binary Installation

Check that the `qubeticsd` binary is installed correctly and verify the version:

```bash
qubeticsd version
```

Expected output: `2.0.0`

### Monitor Blockchain Sync

The blockchain syncing runs as a background service. Monitor the logs:

**Ubuntu:**
```bash
journalctl -u qubeticschain -f
```

**macOS:**
```bash
tail -f $HOME/logfile.log
```

## Managing the Service

### Stop the Service

**Ubuntu:**
```bash
sudo systemctl stop qubeticschain.service
```

**macOS:**
```bash
launchctl stop com.qubetics.myservice
```

### Start the Service

**Ubuntu:**
```bash
sudo systemctl start qubeticschain.service
```

**macOS:**
```bash
launchctl start com.qubetics.myservice
```

### Restart the Service

**Ubuntu:**
```bash
sudo systemctl restart qubeticschain.service
```

**macOS:**
```bash
launchctl kickstart -k com.qubetics.myservice
```

### Check Service Status

**Ubuntu:**
```bash
sudo systemctl status qubeticschain.service
```

**macOS:**
```bash
launchctl list | grep qubetics
```

## Troubleshooting

### Fast Sync

If you need to speed up the initial blockchain sync, use the fast sync script:

```bash
./qubetics_fast_sync.sh
```

### Common Issues

- **Permission denied:** Make sure scripts are executable: `chmod +x *.sh`
- **Go not found:** Ensure Go is properly installed and added to your PATH
- **Service won't start:** Check logs for specific error messages

## License

See [LICENSE](LICENSE) file for details.

---

**Support:** For issues and questions, please open an issue on [GitHub](https://github.com/Qubetics/qubetics-mainnetnode-script/issues)
