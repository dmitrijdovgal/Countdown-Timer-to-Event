⏱️ Countdown Timer to Event – Multi‑Language Edition

A powerful **countdown timer** that shows the exact time remaining until a specified event (birthday, deadline, holiday, etc.).  
Supports multiple date formats, live updating, saving events, and customisable output styles.  
Built in **7 programming languages** – perfect for anticipation, reminders, or learning date/time handling.

## ✨ Features
- **Set target date/time** – define the event date and optional time.
- **Live countdown** – updates in real time (every second).
- **Multiple output styles** – `full` (years, months, days, etc.), `compact` (DD:HH:MM:SS), `short` (just seconds).
- **Multiple date formats** – `YYYY-MM-DD`, `DD/MM/YYYY`, `MM/DD/YYYY`, `DD.MM.YYYY`.
- **Save/Load events** – store events with names to a JSON file.
- **List saved events** – view all your upcoming events.
- **Delete events** – remove an event by its name.
- **Command‑line mode** – set event and get countdown directly.
- **Interactive mode** – step‑by‑step prompts with validation.

## 🗂 Languages & Files
| Language          | File             |
|-------------------|------------------|
| Python            | `countdown.py`   |
| Go                | `countdown.go`   |
| JavaScript (Node) | `countdown.js`   |
| C#                | `Countdown.cs`   |
| Java              | `Countdown.java` |
| Ruby              | `countdown.rb`   |
| Swift             | `countdown.swift`|

## 🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.

| Language | Command (interactive) | Command (CLI) |
|----------|----------------------|---------------|
| Python   | `python countdown.py` | `python countdown.py --event "New Year" --date 2025-01-01` |
| Go       | `go run countdown.go` | `go run countdown.go -event "New Year" -date 2025-01-01` |
| JavaScript | `node countdown.js` | `node countdown.js --event "New Year" --date 2025-01-01` |
| C#       | `dotnet run` | `dotnet run -- --event "New Year" --date 2025-01-01` |
| Java     | `java Countdown` | `java Countdown --event "New Year" --date 2025-01-01` |
| Ruby     | `ruby countdown.rb` | `ruby countdown.rb --event "New Year" --date 2025-01-01` |
| Swift    | `swift countdown.swift` | `swift countdown.swift --event "New Year" --date 2025-01-01` |

## 📊 Example Session (Interactive)
=== Countdown Timer ===

Set new event

Show countdown

Live countdown

List events

Delete event

Save events

Load events

Exit
Choose: 1
Event name: Birthday
Event date (YYYY-MM-DD): 2025-07-15
Event time (HH:MM, optional):
Event saved!

Choose: 2
Event: Birthday
Time remaining: 1 year, 2 months, 3 days, 4 hours, 5 minutes, 6 seconds

text

## 🔧 Command‑Line Options (Common)
| Option | Description |
|--------|-------------|
| `--event NAME` | Name of the event |
| `--date DATE` | Target date (YYYY-MM-DD) |
| `--time TIME` | Target time (HH:MM) optional |
| `--format [full\|compact\|short]` | Output format (default: full) |
| `--live` | Show live countdown (updates every second) |
| `--list` | List all saved events |
| `--delete NAME` | Delete an event by name |

## 📁 Event File Format
Stored as JSON array:
```json
[{"name":"Birthday","date":"2025-07-15","time":"00:00"}]
🤝 Contributing
Add support for recurring events, alarms, or a GUI – PRs welcome!

📜 License
MIT – use freely.
