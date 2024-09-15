#!/bin/bash

# Define the Bitcoin Core version
BITCOIN_CORE_VERSION="0.21.1"

# Define the download link
DOWNLOAD_LINK="https://bitcoin.org/bin/bitcoin-core-${BITCOIN_CORE_VERSION}/bitcoin-${BITCOIN_CORE_VERSION}-x86_64-linux-gnu.tar.gz"

# Define the project directory
PROJECT_DIR=$(pwd)

# Define paths
BITCOIN_TAR="bitcoin-${BITCOIN_CORE_VERSION}-x86_64-linux-gnu.tar.gz"
BITCOIN_DIR="bitcoin-${BITCOIN_CORE_VERSION}"
BITCOIND_BIN="${PROJECT_DIR}/${BITCOIN_DIR}/bin/bitcoind"
BITCOIN_CLI_BIN="${PROJECT_DIR}/${BITCOIN_DIR}/bin/bitcoin-cli"
SERVICE_DIR="${BITCOIN_DIR}/config"
SERVICE_FILE="${SERVICE_DIR}/bitcoind.service"
CONFIG_FILE="${SERVICE_DIR}/bitcoin.conf"
SYSTEMD_SERVICE="/etc/systemd/system/bitcoind.service"

# Check if the script is being run with root permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)." 
   exit 1
fi

# Check if GPG is installed
if ! command -v gpg &> /dev/null; then
    echo "GPG is not installed. Installing GPG..."
    apt-get update
    apt-get install -y gnupg
fi

# Check for user.txt.gpg and retrieve rpcuser and rpcpassword
USER_FILE_ENC="user.txt.gpg"
if [[ -f "${USER_FILE_ENC}" ]]; then
    echo "Encrypted credentials file ${USER_FILE_ENC} found."
    echo "Decrypting ${USER_FILE_ENC} to retrieve RPC credentials..."
    # Decrypt the file (will prompt for passphrase)
    gpg --decrypt "${USER_FILE_ENC}" > user.txt
    if [[ $? -ne 0 ]]; then
        echo "Failed to decrypt ${USER_FILE_ENC}. Exiting."
        exit 1
    fi
    # Read rpcuser and rpcpassword from user.txt
    source user.txt
    # Remove the unencrypted file
    shred -u user.txt
    echo "RPC credentials retrieved from ${USER_FILE_ENC}."
else
    echo "No encrypted credentials file found. Generating new RPC credentials..."
    # Generate secure RPC credentials
    RPCUSER="rpcuser_$(openssl rand -hex 8)"
    RPCPASSWORD="rpcpassword_$(openssl rand -hex 16)"
    # Save credentials to user.txt
    echo "rpcuser=${RPCUSER}" > user.txt
    echo "rpcpassword=${RPCPASSWORD}" >> user.txt
    # Encrypt user.txt to user.txt.gpg
    echo "Encrypting RPC credentials to ${USER_FILE_ENC}..."
    gpg -c --batch --yes user.txt
    if [[ $? -ne 0 ]]; then
        echo "Failed to encrypt RPC credentials. Exiting."
        exit 1
    fi
    # Remove the unencrypted file securely
    shred -u user.txt
    echo "Encrypted credentials saved to ${USER_FILE_ENC}."
    echo "Keep the passphrase safe to access your RPC credentials in the future."
fi

# Download Bitcoin Core
echo "Downloading Bitcoin Core version ${BITCOIN_CORE_VERSION}..."
wget ${DOWNLOAD_LINK} -O ${BITCOIN_TAR}

# Verify if the download was successful
if [[ $? -ne 0 ]]; then
    echo "Error downloading Bitcoin Core. Check your internet connection and the download link."
    exit 1
fi

# Extract the tarball
echo "Extracting Bitcoin Core..."
tar -xvf ${BITCOIN_TAR}

# Remove the downloaded tarball
echo "Removing the downloaded tarball..."
rm -rf ${BITCOIN_TAR}

echo "Bitcoin Core ${BITCOIN_CORE_VERSION} has been successfully installed in the current directory!"

# Create the configuration directory structure
echo "Creating configuration directory at ${SERVICE_DIR}..."
mkdir -p ${SERVICE_DIR}

# Detect number of CPU cores and calculate 'par'
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
if [ -z "$CPU_CORES" ] || [ "$CPU_CORES" -le 1 ]; then
    PAR=1
else
    PAR=$(($CPU_CORES / 2))
fi
echo "Detected number of CPU cores: ${CPU_CORES}"
echo "Setting 'par' to: ${PAR}"

# Detect total available RAM and calculate 'dbcache'
TOTAL_RAM=$(awk '/^MemTotal:/{print int($2/1024)}' /proc/meminfo)
if [ -z "$TOTAL_RAM" ] || [ "$TOTAL_RAM" -le 0 ]; then
    echo "Unable to determine total RAM."
    exit 1
fi
DBCACHE=$(($TOTAL_RAM / 2))
# Set a maximum value for dbcache to avoid excessive allocation
MAX_DBCACHE=8192
if [ "$DBCACHE" -gt "$MAX_DBCACHE" ]; then
    DBCACHE=$MAX_DBCACHE
fi
echo "Detected total RAM: ${TOTAL_RAM} MB"
echo "Setting 'dbcache' to: ${DBCACHE} MB"

# Create the bitcoin.conf file with basic and dynamic configurations
echo "Creating the configuration file bitcoin.conf at ${CONFIG_FILE}..."
tee ${CONFIG_FILE} > /dev/null <<EOL
# Enable RPC server
server=1

# RPC configurations
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}

# Set the RPC port (default 8332)
rpcport=8332

# Allow RPC connections from localhost
rpcallowip=127.0.0.1

# Increase database cache to speed up synchronization (${DBCACHE} MB)
dbcache=${DBCACHE}

# Adjustments to speed up synchronization
maxconnections=40         # Increase the number of network connections
par=${PAR}                # Number of script verification threads

# Data directory (optional, uncomment and adjust if you want to use a different directory)
# datadir=/path/to/your/data_directory

# Enable detailed logging (optional, uncomment if you need more detailed logs)
# debug=1
EOL

echo "Configuration file bitcoin.conf successfully created at ${CONFIG_FILE}."
echo "RPC Username: ${RPCUSER}"
echo "RPC Password: ${RPCPASSWORD}"
echo "Keep this information in a safe place."

# Adjust permissions of the configuration file
echo "Adjusting permissions of the configuration file..."
chown $SUDO_USER:$SUDO_USER ${CONFIG_FILE}
chmod 600 ${CONFIG_FILE}

# Create the service file in the configuration directory
echo "Creating the service file bitcoind.service at ${SERVICE_FILE}..."
tee ${SERVICE_FILE} > /dev/null <<EOL
[Unit]
Description=Bitcoin Core Daemon
After=network.target

[Service]
ExecStart=${BITCOIND_BIN} -conf=${CONFIG_FILE}
ExecStop=${BITCOIN_CLI_BIN} stop
Restart=on-failure
User=${SUDO_USER}
Group=${SUDO_USER}
WorkingDirectory=${PROJECT_DIR}
Environment=HOME=/home/${SUDO_USER}

[Install]
WantedBy=multi-user.target
EOL

echo "Service file bitcoind.service successfully created at ${SERVICE_FILE}."

# Create symlink to systemd
echo "Creating symlink to systemd at ${SYSTEMD_SERVICE}..."
ln -sf ${SERVICE_FILE} ${SYSTEMD_SERVICE}

echo "Symlink created: ${SYSTEMD_SERVICE} -> ${SERVICE_FILE}"

# Reload systemd to recognize the new service
echo "Reloading systemd..."
systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling the bitcoind service to start on boot..."
systemctl enable bitcoind.service

# Start the service
echo "Starting the bitcoind service..."
systemctl start bitcoind.service

# Check the status of the service
echo "Checking the status of bitcoind.service..."
systemctl status bitcoind.service

echo "Bitcoind has been configured to start automatically on boot."
echo "Blockchain synchronization started. You can monitor the progress with the command:"
echo "  ${BITCOIN_CLI_BIN} -conf=${CONFIG_FILE} getblockchaininfo"
