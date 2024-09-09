#!/bin/bash

# Display start message
echo "Starting LND installation from source on Ubuntu..."

# Update the system and install dependencies
echo "Updating packages and installing dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git curl build-essential

# Install Go (required to compile LND)
GO_VERSION="1.21.0"

if ! [ -x "$(command -v go)" ]; then
    echo "Installing Go version $GO_VERSION..."
    wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz
fi

# Configure Go environment variables
echo "Configuring Go environment variables..."
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.profile
source ~/.profile

# Verify Go installation
if ! [ -x "$(command -v go)" ]; then
    echo "Go installation failed. Please check the process and try again."
    exit 1
fi

# Create directory for Go code
mkdir -p ~/go/src/github.com/lightningnetwork

# Clone LND repository from master branch
echo "Cloning LND repository from master branch..."
cd ~/go/src/github.com/lightningnetwork
git clone https://github.com/lightningnetwork/lnd.git
cd lnd

# Compile and install LND
echo "Compiling and installing LND..."
make && make install

# Verify LND installation
if [ $? -ne 0 ]; then
    echo "LND compilation failed."
    exit 1
fi

# Create LND configuration directory
echo "Creating LND configuration directory..."
mkdir -p ~/.lnd

# Generate default LND configuration file
echo "Generating default LND configuration file..."
cat <<EOL > ~/.lnd/lnd.conf
[Application Options]
alias=MyLNDNode
color=#3399FF
maxpendingchannels=5
rpclisten=0.0.0.0:10009
listen=0.0.0.0:9735
restlisten=0.0.0.0:8080
tlsextraip=0.0.0.0

[Bitcoin]
bitcoin.active=1
bitcoin.mainnet=1
bitcoin.node=bitcoind

[autopilot]
autopilot.active=1
autopilot.maxchannels=5
autopilot.allocation=0.6
EOL

# Install Bitcoin Core (required for LND)
echo "Installing Bitcoin Core..."
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install -y bitcoind

# Create Bitcoin Core configuration file
echo "Creating Bitcoin Core configuration file..."
mkdir -p ~/.bitcoin
cat <<EOL > ~/.bitcoin/bitcoin.conf
server=1
txindex=1
rpcuser=rpcuser
rpcpassword=rpcpassword
zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28333
EOL

# Start bitcoind
echo "Starting bitcoind..."
bitcoind -daemon

# Wait a few seconds for bitcoind to start
sleep 10

# Verify if bitcoind is running
if pgrep -x "bitcoind" > /dev/null
then
    echo "bitcoind is running."
else
    echo "bitcoind is not running. Please check the process and try again."
    exit 1
fi

# Start LND
echo "Starting LND..."
lnd --daemon

# Wait a few seconds for LND to start
sleep 10

# Verify if LND is running
if pgrep -x "lnd" > /dev/null
then
    echo "LND has been successfully installed and is running in the background."
    echo "Use 'lncli' to interact with LND."
else
    echo "LND is not running. Please check the process and try again."
    exit 1
fi

# Configure LND to start on system boot
echo "Configuring LND to start on boot..."
sudo tee /etc/systemd/system/lnd.service > /dev/null <<EOL
[Unit]
Description=LND - Lightning Network Daemon
After=bitcoind.service
Wants=bitcoind.service

[Service]
ExecStart=/usr/local/bin/lnd
ExecStop=/usr/local/bin/lncli stop
Restart=always
User=$USER
LimitNOFILE=128000

[Install]
WantedBy=multi-user.target
EOL

# Enable LND to start at boot
sudo systemctl enable lnd.service
sudo systemctl start lnd.service

echo "LND is now configured to start automatically on boot or system restart."
