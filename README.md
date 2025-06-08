# convenience

# 🐚 Kali Docker Pentesting Environment Setup

This repository provides a modular and extensible setup for building, running, and managing **Custom Kali Docker containers**, configuring **ZSH environments**, and orchestrating **project-based workflows** for penetration testing.

---

## 📁 Repository Structure

```
.
├── docker_setup/
│   ├── kali/
│   │   ├── docker_builder.sh
│   │   └── GuiKali.Dockerfile
│   ├── kali_custom/
│   │   ├── docker_builder.sh
│   │   └── GuiKaliCustom.Dockerfile
├── zsh_setup/
│   └── aliases/
│       ├── host_aliases.zsh
│       ├── docker_aliases.zsh
│       └── project_aliases.zsh
├── host_setup/
│   ├── host_setup.sh
│   └── project_management/
│       ├── project_management_setup.sh
│       └── project.sh
└── README.md
```

---

## 🚀 Components

### 🐳 `docker_setup/`

Contains separate folders for two Kali image types:

- **`kali/`**: A GUI-capable Kali image with default tools.
- **`kalicustom/`**: A more advanced image with additional custom tools depending on local files.

Each folder includes:
- `docker_builder.sh` – Image build script.
- `GuiKali.Dockerfile` – Dockerfile defining the image.

---

### 💻 `zsh_setup/aliases/`

ZSH alias files for different contexts:

- `host_aliases.zsh` – Aliases for the host system.
- `docker_aliases.zsh` – Aliases copied into the container.
- `project_aliases.zsh` – Project-specific aliases used in engagement containers.

---

### 🖥️ `host_setup/`

Automates setup on the host machine.

- **`host_setup.sh`**
  - Installs ZSH and Oh My Zsh.
  - Downloads and installs [Tabby](https://tabby.sh), a terminal manager.
  - Copies `host_aliases.zsh` into the Oh My Zsh custom aliases folder.

#### 🗂 `project_management/`

Tools for managing pentest projects as Docker containers.

- **`project_management_setup.sh`**
  - Installs the `project_aliases.zsh` file for project-specific command aliases.
  - Links `project.sh` to `~/.local/bin/project` for easy CLI access.

- **`project.sh`**  
  A robust shell script to manage pentest engagements using Docker.

---

## 📦 Project Workflow

Engagements are stored in:
  - `~/Documents/Engagements/Running`
  - `~/Documents/Engagements/Archive`

And mounted into:
  - `/root/shared`
    
Manage pentest engagements via the `project` CLI:

```bash
project create <name>     # Create and start a new engagement
project enter [name]      # Enter engagement container shell (default: current)
project switch <name>     # Switch from current to another project
project archive <name>    # Archive shared data
project remove <name>     # Remove a project
project exit              # Stop current project
```

### ⚙️ Container Details

- Names are auto-suffixed with date.
- GUI-enabled via X11 socket sharing.
- Docker container security is hardened by dropping capabilities and only enabling what's required.

---

## 🛠️ Setup Instructions

1. Clone the repo:
   ```bash
   git clone https://github.com/MrMatch246/convenience.git
   cd convenience
   ```

2. Run the host setup:
   ```bash
   ./host_setup/host_setup.sh
   ```

3. Build Docker images:
   ```bash
   ./docker_setup/kali/docker_builder.sh
   ```
   or
   ```bash
   ./docker_setup/kalicustom/docker_builder.sh
   ```

4. Run project manager setup:
   ```bash
   ./host_setup/project_management/project_management_setup.sh
   ```

---

## 🧠 Notes

- Ensure `~/.local/bin` is in your `PATH` to use `project` from anywhere.
- `project.sh` handles engagement container lifecycle management cleanly, allowing you to work as if each project were a fully-isolated VM.
- Containers run with host networking and restricted permissions to balance functionality and security.

---

## 📜 License

MIT – Feel free to modify and adapt for your own use.
