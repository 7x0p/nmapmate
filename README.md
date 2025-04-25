# nmapmate

**nmapmate** is an interactive command-line assistant that helps users build and run powerful Nmap scans easily, flexibly, and efficiently — all through a simple terminal interface.

---

## 🔍 Features

- 🎯 Set and validate scan targets (IP, CIDR, or domain)
- 🔧 Manage custom Nmap options dynamically
- 📜 Search and select Nmap scripts interactively
- 🚪 Add and remove specific ports for scanning
- ✅ Results are displayed cleanly and organized at the end
- ❌ Prevents duplicate scripts/options
- 🧠 Smart prompt that reflects current context

---

## 🚀 Getting Started

### 🛠 Requirements
- `rlwrap` installed 
- `nmap` installed  
  ```
  sudo apt install nmap
  sudo apt install rlwrap
  ```

---

### 🔧 Running the script

```bash
chmod +x nmapmate.sh
./nmapmate.sh
```

---

## 💻 Commands

| Command             | Description                                     |
|---------------------|-------------------------------------------------|
| `set target <IP>`   | Set scan target (e.g. `192.168.1.1`, `example.com`) |
| `set port <ports>`  | Add one or more ports (e.g. `22 80 443`)       |
| `set option <opts>` | Add Nmap options (e.g. `-sV -T4`)               |
| `set script <name>` | Add Nmap script (e.g. `http-title.nse`)        |
| `unset <param>`     | Remove a target, port, option, or script       |
| `search <term>`     | Search for Nmap scripts containing a keyword   |
| `run`               | Run the scan with selected settings            |
| `show option`       | Show current configuration                     |
| `clear`             | Clear screen                                    |
| `help`              | Show help                                       |
| `exit`              | Exit the tool                                   |

---

## 📦 Example usage

```bash
nmapmate > set target nmap.org
nmapmate [target: nmap.org] > set port 80 443
nmapmate [target: nmap.org] ports(80,443) > set script http-title.nse
nmapmate [target: nmap.org] ports(80,443) scripts(http-title.nse) > run
```

## 📜 License

This project is released under the **MIT License**.  
You are free to use, modify, and share it for personal or commercial use.
