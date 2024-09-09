#!/bin/bash

# Define the Bitcoin Core version
BITCOIN_CORE_VERSION="0.21.1"

# Define the download link
DOWNLOAD_LINK="https://bitcoin.org/bin/bitcoin-core-${BITCOIN_CORE_VERSION}/bitcoin-${BITCOIN_CORE_VERSION}-x86_64-linux-gnu.tar.gz"

# Download Bitcoin Core
wget ${DOWNLOAD_LINK}

# Extract the tarball
tar -xvf bitcoin-${BITCOIN_CORE_VERSION}-x86_64-linux-gnu.tar.gz

# Remove the downloaded tarball
rm -rf bitcoin-${BITCOIN_CORE_VERSION}-x86_64-linux-gnu.tar.gz

echo "Bitcoin Core ${BITCOIN_CORE_VERSION} was successfully installed in the current directory!"

# Start bitcoind
./bitcoin-${BITCOIN_CORE_VERSION}/bin/bitcoind -daemon

echo "Bitcoind is running in the background!"

# Set up bitcoind to start at boot using systemd
echo "Configuring bitcoind to start on boot..."

sudo tee /etc/systemd/system/bitcoind.service > /dev/null <<EOL
[Unit]
Description=Bitcoin Core Daemon
After=network.target

[Service]
ExecStart=$(pwd)/bitcoin-${BITCOIN_CORE_VERSION}/bin/bitcoind -daemon -conf=/etc/bitcoin/bitcoin.conf
ExecStop=$(pwd)/bitcoin-${BITCOIN_CORE_VERSION}/bin/bitcoin-cli stop
Restart=on-failure
User=$USER

[Install]
WantedBy=multi-user.target
EOL

# Enable the service to start on boot
sudo systemctl enable bitcoind.service
sudo systemctl start bitcoind.service

echo "Bitcoind has been configured to start automatically on system boot."
