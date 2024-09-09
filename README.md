
# Lightning Network Daemon (LND) Installer Script

This script automates the installation and configuration of the **Lightning Network Daemon (LND)** on an Ubuntu-based system. The script ensures smooth setup, including compiling the LND source code, configuring it to run as a service, and setting it to start automatically on system boot.

## Features

- **Automated Installation**: The script downloads, compiles, and installs LND from the source (master branch of the official GitHub repository).
- **Background Service**: LND is started in the background as a daemon, ensuring that it runs without manual intervention.
- **Systemd Service Integration**: Configures LND to run as a systemd service, making sure that it starts automatically on system boot.
- **Bitcoin Core Integration**: Installs and configures Bitcoin Core (bitcoind) as the blockchain backend for LND.

## How to Use

1. Clone the repository and navigate to the directory containing the script.
2. Give execution permission to the script:
   ```bash
   chmod +x install_lnd.sh
   ```
3. Run the script:
   ```bash
   ./install_lnd.sh
   ```

The script will handle the following steps automatically:

- Download and compile the LND source code.
- Install Bitcoin Core (bitcoind) as the backend.
- Start `bitcoind` and LND as background services.
- Set up systemd services to ensure LND and bitcoind start automatically on boot.

## Why Use This Installer?

We chose to install **LND** from the latest source on GitHub to ensure you get the most up-to-date features and bug fixes. The systemd service integration ensures that LND is always running, making it ideal for setting up a reliable Lightning Network node.

Additionally, **Bitcoin Core (v0.21.1)** is installed as the blockchain backend, providing advanced features such as:
- **Private Key Export from Transactions**: This feature simplifies managing multiple Bitcoin wallets and generating Bitcoin notes or physical Bitcoin bills.
- **Replace-by-Fee (RBF)**: Helps manage fee adjustments dynamically, especially for nodes handling many transactions or wallets, ensuring that transactions are confirmed in a timely manner.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
