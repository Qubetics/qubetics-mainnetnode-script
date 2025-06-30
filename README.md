# Setup Mainnet Qubetics Node

This repository contains a script for setting up a node on the Qubetics blockchain.

## Installation

### Prerequisites

System Requirements:
- 4 or more physical CPU cores
- At least 1TB disk storage
- At least 16GB of memory (RAM)
- At least 100 Mbps network bandwidth

### Clone this repository:

```bash
git clone https://github.com/Qubetics/qubetics-mainnetnode-script.git
```

### Install Go (if not already installed)

Run the `install-go.sh` script. This script works for both macOS and Ubuntu.

For macOS users, if Homebrew is not installed, please install it first `install-brew.sh`.

## Setup a Node

Open a terminal window and run the appropriate script for your OS:

- For Ubuntu:

```bash
./qubetics_ubuntu_node.sh  '<nodename>'  (eg. ./qubetics_ubuntu_node.sh galaxynode)
```

- For macOS:

```bash
./qubetics_mac_node.sh '<nodename>'   (eg. ./qubetics_ubuntu_node.sh galaxynode)
```

**Note:** The blockchain syncing runs as a background service. You can check the logs with the following commands:

- Ubuntu:

```bash
journalctl -u qubeticschain -f
```
s
- macOS:

```bash
tail -f $HOME/logfile.log
```

### Important

Copy your key mnemonics and save them in a safe place or you can generate a new with any evm wallet. The mnemonics are displayed at the top of the JSON output in the terminal.

## Managing the Service

To stop the service, use the following commands:

- Ubuntu:

```bash
sudo systemctl stop qubeticschain.service
```

- macOS:

```bash
launchctl stop com.qubetics.myservice
launchctl remove com.qubetics.myservice
