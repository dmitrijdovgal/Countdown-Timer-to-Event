
---

# 💻 Code Implementations

## 1. Python (`countdown.py`)

```python
# countdown.py
import json
import sys
import time
import argparse
import os
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

EVENTS_FILE = "events.json"
events = []

def load_events():
    global events
    try:
        with open(EVENTS_FILE, 'r') as f:
            events = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        events = []

def save_events():
    with open(EVENTS_FILE, 'w') as f:
        json.dump(events, f, indent=2)

def parse_date(date_str):
    """Parse date in multiple formats."""
    formats = ['%Y-%m-%d', '%d/%m/%Y', '%m/%d/%Y', '%d.%m.%Y']
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt).date()
        except ValueError:
            continue
    return None

def find_event(name):
    for e in events:
        if e["name"].lower() == name.lower():
            return e
    return None

def add_event(name, date_str, time_str=None):
    date = parse_date(date_str)
    if not date:
        return False, "Invalid date format."
    time = datetime.strptime(time_str, "%H:%M").time() if time_str else datetime.min.time()
    target = datetime.combine(date, time)
    events.append({"name": name, "date": date_str, "time": time_str or "00:00"})
    save_events()
    return True, "Event saved."

def delete_event(name):
    global events
    for i, e in enumerate(events):
        if e["name"].lower() == name.lower():
            del events[i]
            save_events()
            return True
    return False

def format_countdown(delta):
    """Format timedelta into years, months, days, hours, minutes, seconds."""
    # For accurate months/years, we need relativedelta
    # Since we don't have dateutil in all versions, we'll use a simpler approach
    total_seconds = delta.total_seconds()
    if total_seconds < 0:
        return "Event has passed!"
    years = total_seconds // (365.25 * 24 * 3600)
    remaining = total_seconds - years * (365.25 * 24 * 3600)
    months = remaining // (30.44 * 24 * 3600)
    remaining -= months * (30.44 * 24 * 3600)
    days = remaining // (24 * 3600)
    remaining -= days * (24 * 3600)
    hours = remaining // 3600
    remaining -= hours * 3600
    minutes = remaining // 60
    seconds = remaining % 60
    parts = []
    if years > 0: parts.append(f"{int(years)} year{'s' if years > 1 else ''}")
    if months > 0: parts.append(f"{int(months)} month{'s' if months > 1 else ''}")
    if days > 0: parts.append(f"{int(days)} day{'s' if days > 1 else ''}")
    if hours > 0: parts.append(f"{int(hours)} hour{'s' if hours > 1 else ''}")
    if minutes > 0: parts.append(f"{int(minutes)} minute{'s' if minutes > 1 else ''}")
    if seconds > 0: parts.append(f"{int(seconds)} second{'s' if seconds > 1 else ''}")
    return ", ".join(parts) if parts else "0 seconds"

def countdown(event, format_style="full", live=False):
    target = datetime.strptime(event["date"] + " " + event["time"], "%Y-%m-%d %H:%M")
    now = datetime.now()
    delta = target - now
    if delta.total_seconds() <= 0:
        print(f"⏰ {event['name']} is in the past!")
        return
    if live:
        try:
            while delta.total_seconds() > 0:
                print(f"\r⏳ {event['name']}: {format_countdown(delta)}    ", end="", flush=True)
                time.sleep(1)
                now = datetime.now()
                delta = target - now
            print(f"\r🎉 {event['name']} has arrived!    ")
        except KeyboardInterrupt:
            print("\nStopped.")
    else:
        if format_style == "compact":
            total_sec = int(delta.total_seconds())
            days = total_sec // 86400
            hours = (total_sec % 86400) // 3600
            minutes = (total_sec % 3600) // 60
            seconds = total_sec % 60
            print(f"⏳ {event['name']}: {days:02d}:{hours:02d}:{minutes:02d}:{seconds:02d}")
        elif format_style == "short":
            print(f"⏳ {event['name']}: {int(delta.total_seconds())} seconds")
        else:
            print(f"⏳ {event['name']}: {format_countdown(delta)}")

def list_events():
    if not events:
        print("No events saved.")
        return
    for e in events:
        target = datetime.strptime(e["date"] + " " + e["time"], "%Y-%m-%d %H:%M")
        if target > datetime.now():
            status = "⏳ pending"
        else:
            status = "✅ passed"
        print(f"  {e['name']}: {e['date']} {e['time']} - {status}")

def interactive():
    load_events()
    print("=== Countdown Timer ===")
    while True:
        print("\n1. Set new event")
        print("2. Show countdown")
        print("3. Live countdown")
        print("4. List events")
        print("5. Delete event")
        print("6. Save events")
        print("7. Load events")
        print("8. Exit")
        choice = input("Choose: ").strip()
        if choice == "1":
            name = input("Event name: ").strip()
            if not name:
                print("Name required.")
                continue
            if find_event(name):
                print("Event already exists.")
                continue
            date_str = input("Event date (YYYY-MM-DD): ").strip()
            if not parse_date(date_str):
                print("Invalid date.")
                continue
            time_str = input("Event time (HH:MM, optional): ").strip()
            if not time_str:
                time_str = "00:00"
            ok, msg = add_event(name, date_str, time_str)
            print(msg)
        elif choice == "2":
            name = input("Event name: ").strip()
            event = find_event(name)
            if not event:
                print("Event not found.")
                continue
            countdown(event, "full")
        elif choice == "3":
            name = input("Event name: ").strip()
            event = find_event(name)
            if not event:
                print("Event not found.")
                continue
            countdown(event, "full", live=True)
        elif choice == "4":
            list_events()
        elif choice == "5":
            name = input("Event name to delete: ").strip()
            if delete_event(name):
                print("Event deleted.")
            else:
                print("Event not found.")
        elif choice == "6":
            save_events()
            print("Events saved.")
        elif choice == "7":
            load_events()
            print("Events loaded.")
        elif choice == "8":
            print("Goodbye!")
            break
        else:
            print("Invalid choice.")

def cli():
    parser = argparse.ArgumentParser(description='Countdown Timer')
    parser.add_argument('--event', help='Event name')
    parser.add_argument('--date', help='Event date (YYYY-MM-DD)')
    parser.add_argument('--time', default='00:00', help='Event time (HH:MM)')
    parser.add_argument('--format', default='full', choices=['full', 'compact', 'short'], help='Output format')
    parser.add_argument('--live', action='store_true', help='Live countdown')
    parser.add_argument('--list', action='store_true', help='List events')
    parser.add_argument('--delete', help='Delete event by name')
    args = parser.parse_args()

    load_events()
    if args.list:
        list_events()
        return
    if args.delete:
        if delete_event(args.delete):
            print("Event deleted.")
        else:
            print("Event not found.")
        return
    if args.event and args.date:
        event = find_event(args.event)
        if event:
            countdown(event, args.format, args.live)
        else:
            print("Event not found. Use --list to see events.")
    elif args.event:
        event = find_event(args.event)
        if event:
            countdown(event, args.format, args.live)
        else:
            print("Event not found.")
    else:
        parser.print_help()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cli()
    else:
        interactive()
