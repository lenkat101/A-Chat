# A-Chat 💬

> [!WARNING]
> **ALPHA STATUS: UNTESTED**
> This project is currently in **Early Alpha (v0.2)**. The code has been architected and structurally verified, but **has not yet been battle-tested in a live Roblox game**.
> 
> Bugs are expected. Use at your own risk. If you find issues, please open a Ticket/Issue on GitHub!

**The Open Source Legacy Chat System for Roblox**

A-Chat is a fully custom, modular chat system designed to restore the **Legacy Chat Behavior** to Roblox games. It bypasses the 2025 chat segregation updates by implementing a custom networking and filtering stack, allowing all players in a server to communicate freely (while strictly adhering to Roblox's filtering requirements).

## 🚀 Features

*   **Global Chat:** Talk to everyone in the server, regardless of "Text Chat Matchmaking Signal" groups.
*   **Team Chat:** Automatically creates private channels for teams. Press **TAB** to toggle between Global and Team chat.
*   **Modular Architecture:** Built with professional standards using `Wally`, `Rojo`, and modular Lua services.
*   **Modern UI:** A sleek, rounded-corner interface with animations and RichText support.
*   **Safe & Compliant:** Implements `TextService:FilterStringAsync` rigorously to ensure your game stays safe and compliant with TOS.
*   **Command System:** Built-in support for commands (e.g., `/help`, `/e dance`).
*   **Rich Text:** Supports bold, italics, and colored text in chat.

## 📦 Installation

### Option 1: Rojo (Recommended)
1.  Clone this repository.
2.  Install dependencies with [Wally](https://github.com/UpliftGames/wally):
    ```bash
    wally install
    ```
3.  Sync to Roblox Studio using [Rojo](https://rojo.space/):
    ```bash
    rojo serve
    ```

### Option 2: Drag & Drop (Coming Soon)
A pre-built `.rbxm` model will be available in the Releases tab soon.

## 🛠 Usage

The system initializes automatically.

*   **Server:** `ServerScriptService.AChat_Server` starts the `ChatService`.
*   **Client:** `StarterPlayerScripts.AChat_Client` handles the UI.

### Configuration
Configuration is currently handled in `src/server/ChatService.lua`. You can toggle:
*   `AutoJoin`: Whether players automatically join the Global channel.

## 🤝 Contributing
Contributions are welcome!
1.  Fork the repo.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes.
4.  Push to the branch.
5.  Open a Pull Request.

## 📜 License
MIT License. Free to use in any project.