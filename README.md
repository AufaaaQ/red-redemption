# 🏙️ East Side Roleplay (ES-RP)

![SA-MP Version](https://img.shields.io/badge/SA--MP-0.3.7--R2-blue)
![Language](https://img.shields.io/badge/Language-Pawn-yellow)
![Status](https://img.shields.io/badge/Status-In--Development-orange)

Welcome to the official repository of **East Side Roleplay**. This is a heavy-roleplay oriented gamemode built for the SA-MP (San Andreas Multiplayer) platform, focusing on immersive storytelling and a realistic economy.

---

## ✨ Key Features

* **Advanced Dynamic System:** Create houses, businesses, and factions in-game without restarting the server.
* **Realistic Economy:** Balanced job salaries and item pricing to ensure long-term gameplay.
* **Custom Mapping:** Exclusive interiors and map expansions around the East Side of Los Santos.
* **Illegal Activities:** Detailed drug manufacturing, robbery systems, and black market trading.

---

## 🛠️ Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-username/east-side-roleplay.git](https://github.com/your-username/east-side-roleplay.git)
    ```
2.  **Includes & Plugins:** Make sure you have the following updated:
    * `sscanf2`, `pawn.raknet`, `samp-node` (if applicable), and `mysql`.
3.  **Database Setup:**
    * Import the `database.sql` file to your MySQL server (PHPMyAdmin).
    * Configure your connection settings in `pawno/include/config.inc` or directly in the `.pwn` file.
4.  **Compile:** Use the Pawno compiler (F5) and ensure all dependencies are in the `pawno/include` folder.

---

## 🚀 Getting Started

To run the server locally, ensure you have the latest **SA-MP Server Client** and execute:
```bash
samp-server.exe