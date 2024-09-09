
# Bitcoin Core Installer Script

This script automates the installation and configuration of **Bitcoin Core (bitcoind)** on an Ubuntu-based system. The script simplifies the process by downloading the Bitcoin Core binaries, installing them, and configuring the node to start automatically on boot.

## Features

- **Automated Installation**: The script fetches and installs the specified version of Bitcoin Core from the official source.
- **Automatic Background Operation**: After installation, `bitcoind` is started in the background as a daemon.
- **Systemd Service Integration**: Configures a systemd service to ensure `bitcoind` starts automatically after system reboots.
- **Version Control**: The script allows for easy version changes by modifying the `BITCOIN_CORE_VERSION` variable.

## How to Use

1. Clone the repository and navigate to the directory containing the script.
2. Give execution permission to the script:
   ```bash
   chmod +x install_bitcoin_core.sh
   ```
3. Run the script:
   ```bash
   ./install_bitcoin_core.sh
   ```

The script will handle the following steps automatically:

- Download Bitcoin Core.
- Extract and install the necessary files.
- Start `bitcoind` as a background service.
- Set up a systemd service to ensure Bitcoin Core starts automatically on boot.

## Why Version 0.21.1?

We chose **Bitcoin Core v0.21.1** for its advanced functionality and stability. Specifically, version 0.21.1 offers:

- **Private Key Export from Transactions**: This feature simplifies the process of creating **Bitcoin bills (paper wallets)**, where the private key needs to be exported from a specific transaction.
- **Replace-by-Fee (RBF)**: This feature allows users to resend transactions with higher fees to ensure they are confirmed faster. This is particularly useful for managing multiple wallets or high-traffic Bitcoin nodes, where efficiency is key.

These capabilities make **Bitcoin Core v0.21.1** an ideal choice for scenarios such as generating Bitcoin notes or managing multiple wallets, providing greater flexibility and control over transaction handling.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
