#!/bin/bash

# Check if the script is run as root
#if [ "$(id -u)" != "0" ]; then
#  echo "This script must be run as root or with sudo." 1>&2
#  exit 1
#fi
current_path=$(pwd)


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

source $HOME/.bashrc
ulimit -n 16384

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

# Get OS and version
OS=$(awk -F '=' '/^NAME/{print $2}' /etc/os-release | awk '{print $1}' | tr -d '"')
VERSION=$(awk -F '=' '/^VERSION_ID/{print $2}' /etc/os-release | awk '{print $1}' | tr -d '"')

# Define the binary and installation paths
BINARY="qubeticsd"
INSTALL_PATH="/usr/local/bin/"
# INSTALL_PATH="/root/go/bin/"


# Check if the OS is Ubuntu and the version is either 20.04 or 22.04
if [ "$OS" = "Ubuntu" ] && { [ "$VERSION" = "20.04" ] || [ "$VERSION" = "22.04" ] || [ "$VERSION" = "24.04" ]; }; then
    print_status "Downloading qubeticsd binary for Ubuntu $VERSION..."
    
    # Download the binary
    DOWNLOAD_URL="https://github.com/Qubetics/qubetics-mainnet-upgrade/releases/download/ubuntu${VERSION}/qubeticsd"
    print_status "Download URL: $DOWNLOAD_URL"
    
    # Remove existing binary if present
    if [ -f "$BINARY" ]; then
        rm -f "$BINARY"
    fi
    
    # Download with error checking
    if command -v wget >/dev/null 2>&1; then
        wget "$DOWNLOAD_URL" -O "$BINARY"
    elif command -v curl >/dev/null 2>&1; then
        curl -L "$DOWNLOAD_URL" -o "$BINARY"
    else
        print_error "Neither wget nor curl is installed. Please install one of them."
        exit 1
    fi
    
    # Verify download
    if [ ! -f "$BINARY" ]; then
        print_error "Failed to download binary"
        exit 1
    fi
    
    # Make the binary executable
    chmod +x "$BINARY"
    
    # Verify binary works
    if ./"$BINARY" version >/dev/null 2>&1; then
        print_status "Binary downloaded and verified successfully"
    else
        print_warning "Binary downloaded but version check failed"
    fi
    # Update package lists and install necessary packages
  sudo  apt-get update
  sudo apt-get install -y build-essential jq wget unzip
  
  # Check if the installation path exists
  if [ -d "$INSTALL_PATH" ]; then
  sudo  cp "$BINARY" "$INSTALL_PATH" && sudo chmod +x "${INSTALL_PATH}${BINARY}"
    echo "$BINARY installed or updated successfully!"
  else
    echo "Installation path $INSTALL_PATH does not exist. Please create it."
    exit 1
  fi
     
      
else
    print_error "Unsupported OS or version: $OS $VERSION"
    print_error "Only Ubuntu 20.04 and 22.04 are supported at this time."
    exit 1
fi


#==========================================================================================================================================
echo "============================================================================================================"
echo "Enter the Name for the node:"
echo "============================================================================================================"
read -r MONIKER
KEYS="bob"
CHAINID="qubetics_9030-1"
KEYRING="os"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"

# Set dedicated home directory for the qubeticsd instance
 HOMEDIR="/data/.tmp-qubeticsd"

# Path variables
CONFIG=$HOMEDIR/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
CLIENT=$HOMEDIR/config/client.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

# validate dependencies are installed
command -v jq >/dev/null 2>&1 || {
	echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"
	exit 1
}

# used to exit on first error
set -e

# User prompt if an existing local node configuration is found.
if [ -d "$HOMEDIR" ]; then
	printf "\nAn existing folder at '%s' was found. You can choose to delete this folder and start a new local node with new keys from genesis. When declined, the existing local node is started. \n" "$HOMEDIR"
	echo "Overwrite the existing configuration and start a new local node? [y/n]"
	read -r overwrite
else
	overwrite="Y"
fi

# Setup local node if overwrite is set to Yes, otherwise skip setup
if [[ $overwrite == "y" || $overwrite == "Y" ]]; then
	# Remove the previous folder
	file_path="/etc/systemd/system/qubeticschain.service"

# Check if the file exists
if [ -e "$file_path" ]; then
sudo systemctl stop qubeticschain.service
    echo "The file $file_path exists."
fi
	sudo rm -rf "$HOMEDIR"

# Set client config
	qubeticsd config keyring-backend $KEYRING --home "$HOMEDIR"
	qubeticsd config chain-id $CHAINID --home "$HOMEDIR"

    echo "===========================Copy these keys with mnemonics and save it in safe place ==================================="
	qubeticsd keys add $KEYS --keyring-backend $KEYRING --algo $KEYALGO --home "$HOMEDIR"
	echo "========================================================================================================================"
	echo "========================================================================================================================"
	qubeticsd init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"

		
	#changes status in app,config files
    sed -i 's/timeout_commit = "3s"/timeout_commit = "6s"/g' "$CONFIG"
    sed -i 's/seeds = ""/seeds = ""/g' "$CONFIG"
    sed -i 's/prometheus = false/prometheus = true/' "$CONFIG"
    sed -i 's/experimental_websocket_write_buffer_size = 200/experimental_websocket_write_buffer_size = 600/' "$CONFIG"
    sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML"
    sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
    sed -i 's/minimum-gas-prices = "0tics"/minimum-gas-prices = "0.25tics"/g' "$APP_TOML"
    sed -i 's/enable = false/enable = true/g' "$APP_TOML"
    sed -i 's/swagger = false/swagger = true/g' "$APP_TOML"
    sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' "$APP_TOML"
    sed -i 's/enable-unsafe-cors = false/enable-unsafe-cors = true/g' "$APP_TOML"
        sed -i '/\[rosetta\]/,/^\[.*\]/ s/enable = true/enable = false/' "$APP_TOML"
	sed -i 's/localhost/0.0.0.0/g' "$APP_TOML"
    sed -i 's/localhost/0.0.0.0/g' "$CONFIG"
    sed -i 's/:26660/0.0.0.0:26660/g' "$CONFIG"
    sed -i 's/localhost/0.0.0.0/g' "$CLIENT"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$APP_TOML"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CONFIG"
    sed -i 's/127.0.0.1/0.0.0.0/g' "$CLIENT"
    sed -i 's/\[\]/["*"]/g' "$CONFIG"
	sed -i 's/\["\*",\]/["*"]/g' "$CONFIG"

sed -i 's/flush_throttle_timeout = "100ms"/flush_throttle_timeout = "10ms"/g' "$CONFIG"
sed -i 's/peer_gossip_sleep_duration = "100ms"/peer_gossip_sleep_duration = "10ms"/g' "$CONFIG"

	# these are some of the node ids help to sync the node with p2p connections
	 sed -i 's/persistent_peers \s*=\s* ""/persistent_peers = "ad8e2053470a347d87f5125d54fe04d86155f7c4@159.138.134.250:26656,1cb538b9950c4f3ce89848101e6698bbf68ad40c@150.40.237.123:26656,41f8e8b5479374a21e69be09911a0c0dc6f41b23@49.0.247.123:26656"/g' "$CONFIG"

     # Don't enable Rosetta API by default
        grep -q -F '[rosetta]' "$APP_TOML" && sed -i '/\[rosetta\]/,/^\[/ s/enable = true/enable = false/' "$APP_TOML"
        # Don't enable memiavl by default
        grep -q -F '[memiavl]' "$APP_TOML" && sed -i '/\[memiavl\]/,/^\[/ s/enable = true/enable = false/' "$APP_TOML"
	# remove the genesis file from binary
	rm -rf $HOMEDIR/config/genesis.json

	# paste the genesis file
	 cp $current_path/genesis.json $HOMEDIR/config

	# Run this to ensure everything worked and that the genesis file is setup correctly
	# qubeticsd validate-genesis --home "$HOMEDIR"

	echo "export DAEMON_NAME=qubeticsd" >> ~/.profile
    echo "export DAEMON_HOME="$HOMEDIR"" >> ~/.profile
    source ~/.profile
    echo $DAEMON_HOME
    echo $DAEMON_NAME

	cosmovisor init "${INSTALL_PATH}${BINARY}"

	
	TENDERMINTPUBKEY=$(qubeticsd tendermint show-validator --home $HOMEDIR | grep "key" | cut -c12-)
	NodeId=$(qubeticsd tendermint show-node-id --home $HOMEDIR --keyring-backend $KEYRING)
	BECH32ADDRESS=$(qubeticsd keys show ${KEYS} --home $HOMEDIR --keyring-backend $KEYRING| grep "address" | cut -c12-)

	echo "========================================================================================================================"
	echo "tendermint Key==== "$TENDERMINTPUBKEY
	echo "BECH32Address==== "$BECH32ADDRESS
	echo "NodeId ===" $NodeId
	echo "========================================================================================================================"

fi

#========================================================================================================================================================
sudo su -c  "echo '[Unit]
Description=qubetics Node
Wants=network-online.target
After=network-online.target
[Service]
User=$(whoami)
Group=$(whoami)
Type=simple
ExecStart=/$(whoami)/go/bin/cosmovisor run start --home $DAEMON_HOME --json-rpc.api eth,txpool,personal,net,debug,web3
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=qubeticsd"
Environment="DAEMON_HOME="$HOMEDIR""
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="UNSAFE_SKIP_BACKUP=false"
[Install]
WantedBy=multi-user.target'> /etc/systemd/system/qubeticschain.service"

sudo systemctl daemon-reload
sudo systemctl enable qubeticschain.service
sudo systemctl start qubeticschain.service

#========================================================================================================================================================
# SNAPSHOT DOWNLOAD AND RESTORATION
#========================================================================================================================================================

print_status "Starting snapshot download and restoration process..."

# Stop the service if it's running
sudo systemctl stop qubeticschain.service || true


# Define snapshot URL and filename
SNAPSHOT_URL="https://snapshots.ticsscan.com/mainnet-qubetics.zip"
SNAPSHOT_FILE="mainnet-qubetics.zip"


print_status "Downloading snapshot from $SNAPSHOT_URL..."

# Download snapshot with error checking
if command -v curl >/dev/null 2>&1; then
    curl -L "$SNAPSHOT_URL" -o "$SNAPSHOT_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget "$SNAPSHOT_URL" -O "$SNAPSHOT_FILE"
else
    print_error "Neither curl nor wget is available for downloading snapshot"
    exit 1
fi

# Verify download
if [ ! -f "$SNAPSHOT_FILE" ]; then
    print_error "Failed to download snapshot"
    exit 1
fi

print_status "Snapshot downloaded successfully"

# Check if priv_validator_state.json exists before backing it up
if [ -f "$HOMEDIR/data/priv_validator_state.json" ]; then
    print_status "Backing up priv_validator_state.json..."
    mv "$HOMEDIR/data/priv_validator_state.json" "$HOMEDIR/priv_validator_state.json"
else
    print_warning "priv_validator_state.json not found, skipping backup"
fi

print_status "Resetting blockchain data..."
qubeticsd tendermint unsafe-reset-all --home "$HOMEDIR"

print_status "Extracting snapshot..."
unzip  "$SNAPSHOT_FILE" -d "$HOMEDIR/data/"

# Check if the backup exists before restoring
if [ -f "$HOMEDIR/priv_validator_state.json" ]; then
    print_status "Restoring priv_validator_state.json..."
    mv "$HOMEDIR/priv_validator_state.json" "$HOMEDIR/data/priv_validator_state.json"
else
    print_warning "Backup priv_validator_state.json not found, skipping restoration"
fi


print_status "Snapshot restoration completed successfully"

# Start the service
print_status "Starting qubeticschain service..."
sudo systemctl start qubeticschain.service

print_status "Node setup with snapshot completed successfully!"
print_status "You can check the service status with: sudo systemctl status qubeticschain.service"
print_status "You can check the logs with: sudo journalctl -u qubeticschain.service -f"