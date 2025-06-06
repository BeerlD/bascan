# 🌐 Bascan - Automation and Scanning Vulnerabilities

Bascan is a tool that aims to bring together several vulnerability analysis and scanning tools on a website. It aims to provide clear and objective information on how the vulnerability works and how to fix it. It is a tool developed for Bug Bounters, Red Team and Blue Team users.

> :warning: This tool should be used ethically and responsibly. I am not responsible for its use.

## 🛠️ Tools

### 🔍 Nmap (Network Mapper)

A powerful utility for network scanning. It helps identify live hosts, open ports, running services, and operating systems. Commonly used for security auditing and network discovery.

### 🌐 Dig (Domain Information Groper)

A command-line tool for DNS queries. Ideal for troubleshooting name resolution issues, retrieving domain records (A, MX, TXT, etc.), and analyzing DNS servers.

### 🧾 Whois

A tool for retrieving registration information of domains and IP addresses. Displays data such as domain owner, creation/expiration dates, name servers, and contact details.

## Installation

| OS                     | Support                 |
| :--------------------- | :---------------------: |
| Kali-Linux 2025.2      | :white_check_mark:      |
| Ubuntu 24.04.2 LTS     | :white_check_mark:      |

```sh
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/BeerlD/bascan/refs/heads/main/install.sh)"
```

### Build

#### Install Compiler

```sh
sudo apt-get update -y
sudo apt-get install -y make gcc

cd /usr/local/bin/
wget https://github.com/neurobin/shc/archive/refs/tags/4.0.3.tar.gz
tar -xvzf 4.0.3.tar.gz
cd shc-4.0.3
./configure

make
sudo make install
```

#### Build Command

```sh
git clone https://github.com/BeerlD/bascan.git
cd bascan
make build
```

### Updating

```sh
sudo bascan update
```

<p style="color: red;">OR</p>

```sh
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/BeerlD/bascan/refs/heads/main/install.sh)"
```

## Usage

```sh
# Examples
sudo bascan host.com        # Example 1
sudo bascan -h host.com     # Example 2
sudo bascan --host host.com # Example 3
```

## Author

**Powered by @BeerlD** <br>

> :warning: Only the automation part was developed by me, the tools used were not created by me.

## Contributors

Contributions are welcome!

<!--- <table>
  <tr>
    <td align="center">
      <img src="https://github.com/BeerlD.png" width="60" height="60" style="border-radius:50%; border: 2px solid #ccc;"><br>
      <sub><b>@BeerlD</b></sub>
    </td>
  </tr>
</table> -->

## License

This project is licensed under the [MIT License](LICENSE).
