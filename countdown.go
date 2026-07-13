// countdown.go
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
	"time"
)

type Event struct {
	Name string `json:"name"`
	Date string `json:"date"`
	Time string `json:"time"`
}

var events []Event
const eventsFile = "events.json"

func loadEvents() {
	data, err := os.ReadFile(eventsFile)
	if err != nil {
		events = []Event{}
		return
	}
	json.Unmarshal(data, &events)
}

func saveEvents() {
	data, _ := json.MarshalIndent(events, "", "  ")
	os.WriteFile(eventsFile, data, 0644)
}

func parseDate(dateStr string) (time.Time, bool) {
	formats := []string{"2006-01-02", "02/01/2006", "01/02/2006", "02.01.2006"}
	for _, fmt := range formats {
		t, err := time.Parse(fmt, dateStr)
		if err == nil {
			return t, true
		}
	}
	return time.Time{}, false
}

func findEvent(name string) *Event {
	for i, e := range events {
		if strings.EqualFold(e.Name, name) {
			return &events[i]
		}
	}
	return nil
}

func addEvent(name, dateStr, timeStr string) bool {
	_, ok := parseDate(dateStr)
	if !ok {
		return false
	}
	if timeStr == "" {
		timeStr = "00:00"
	}
	events = append(events, Event{Name: name, Date: dateStr, Time: timeStr})
	saveEvents()
	return true
}

func deleteEvent(name string) bool {
	for i, e := range events {
		if strings.EqualFold(e.Name, name) {
			events = append(events[:i], events[i+1:]...)
			saveEvents()
			return true
		}
	}
	return false
}

func formatCountdown(delta time.Duration) string {
	if delta < 0 {
		return "Event has passed!"
	}
	totalSec := int(delta.Seconds())
	years := totalSec / int(365.25*24*3600)
	remaining := totalSec - years*int(365.25*24*3600)
	months := remaining / int(30.44*24*3600)
	remaining -= months * int(30.44*24*3600)
	days := remaining / (24 * 3600)
	remaining -= days * (24 * 3600)
	hours := remaining / 3600
	remaining -= hours * 3600
	minutes := remaining / 60
	seconds := remaining % 60
	parts := []string{}
	if years > 0 {
		parts = append(parts, fmt.Sprintf("%d year%s", years, plural(years)))
	}
	if months > 0 {
		parts = append(parts, fmt.Sprintf("%d month%s", months, plural(months)))
	}
	if days > 0 {
		parts = append(parts, fmt.Sprintf("%d day%s", days, plural(days)))
	}
	if hours > 0 {
		parts = append(parts, fmt.Sprintf("%d hour%s", hours, plural(hours)))
	}
	if minutes > 0 {
		parts = append(parts, fmt.Sprintf("%d minute%s", minutes, plural(minutes)))
	}
	if seconds > 0 {
		parts = append(parts, fmt.Sprintf("%d second%s", seconds, plural(seconds)))
	}
	if len(parts) == 0 {
		return "0 seconds"
	}
	return strings.Join(parts, ", ")
}

func plural(n int) string {
	if n > 1 {
		return "s"
	}
	return ""
}

func countdown(event Event, formatStyle string, live bool) {
	target, _ := time.Parse("2006-01-02 15:04", event.Date+" "+event.Time)
	now := time.Now()
	delta := target.Sub(now)
	if delta <= 0 {
		fmt.Printf("⏰ %s is in the past!\n", event.Name)
		return
	}
	if live {
		for delta > 0 {
			fmt.Printf("\r⏳ %s: %s    ", event.Name, formatCountdown(delta))
			time.Sleep(1 * time.Second)
			now = time.Now()
			delta = target.Sub(now)
		}
		fmt.Printf("\r🎉 %s has arrived!    \n", event.Name)
	} else {
		if formatStyle == "compact" {
			totalSec := int(delta.Seconds())
			days := totalSec / 86400
			hours := (totalSec % 86400) / 3600
			minutes := (totalSec % 3600) / 60
			seconds := totalSec % 60
			fmt.Printf("⏳ %s: %02d:%02d:%02d:%02d\n", event.Name, days, hours, minutes, seconds)
		} else if formatStyle == "short" {
			fmt.Printf("⏳ %s: %d seconds\n", event.Name, int(delta.Seconds()))
		} else {
			fmt.Printf("⏳ %s: %s\n", event.Name, formatCountdown(delta))
		}
	}
}

func listEvents() {
	if len(events) == 0 {
		fmt.Println("No events saved.")
		return
	}
	for _, e := range events {
		target, _ := time.Parse("2006-01-02 15:04", e.Date+" "+e.Time)
		status := "⏳ pending"
		if target.Before(time.Now()) {
			status = "✅ passed"
		}
		fmt.Printf("  %s: %s %s - %s\n", e.Name, e.Date, e.Time, status)
	}
}

func interactive() {
	scanner := bufio.NewScanner(os.Stdin)
	loadEvents()
	fmt.Println("=== Countdown Timer ===")
	for {
		fmt.Println("\n1. Set new event")
		fmt.Println("2. Show countdown")
		fmt.Println("3. Live countdown")
		fmt.Println("4. List events")
		fmt.Println("5. Delete event")
		fmt.Println("6. Save events")
		fmt.Println("7. Load events")
		fmt.Println("8. Exit")
		fmt.Print("Choose: ")
		scanner.Scan()
		choice := strings.TrimSpace(scanner.Text())
		switch choice {
		case "1":
			fmt.Print("Event name: ")
			scanner.Scan()
			name := strings.TrimSpace(scanner.Text())
			if name == "" {
				fmt.Println("Name required.")
				continue
			}
			if findEvent(name) != nil {
				fmt.Println("Event already exists.")
				continue
			}
			fmt.Print("Event date (YYYY-MM-DD): ")
			scanner.Scan()
			dateStr := strings.TrimSpace(scanner.Text())
			if _, ok := parseDate(dateStr); !ok {
				fmt.Println("Invalid date.")
				continue
			}
			fmt.Print("Event time (HH:MM, optional): ")
			scanner.Scan()
			timeStr := strings.TrimSpace(scanner.Text())
			if addEvent(name, dateStr, timeStr) {
				fmt.Println("Event saved.")
			}
		case "2":
			fmt.Print("Event name: ")
			scanner.Scan()
			name := strings.TrimSpace(scanner.Text())
			event := findEvent(name)
			if event == nil {
				fmt.Println("Event not found.")
				continue
			}
			countdown(*event, "full", false)
		case "3":
			fmt.Print("Event name: ")
			scanner.Scan()
			name := strings.TrimSpace(scanner.Text())
			event := findEvent(name)
			if event == nil {
				fmt.Println("Event not found.")
				continue
			}
			countdown(*event, "full", true)
		case "4":
			listEvents()
		case "5":
			fmt.Print("Event name to delete: ")
			scanner.Scan()
			name := strings.TrimSpace(scanner.Text())
			if deleteEvent(name) {
				fmt.Println("Event deleted.")
			} else {
				fmt.Println("Event not found.")
			}
		case "6":
			saveEvents()
			fmt.Println("Events saved.")
		case "7":
			loadEvents()
			fmt.Println("Events loaded.")
		case "8":
			fmt.Println("Goodbye!")
			return
		default:
			fmt.Println("Invalid choice.")
		}
	}
}

func cli() {
	eventName := flag.String("event", "", "Event name")
	date := flag.String("date", "", "Event date (YYYY-MM-DD)")
	time := flag.String("time", "00:00", "Event time (HH:MM)")
	format := flag.String("format", "full", "Output format: full, compact, short")
	live := flag.Bool("live", false, "Live countdown")
	list := flag.Bool("list", false, "List events")
	deleteName := flag.String("delete", "", "Delete event by name")
	flag.Parse()

	loadEvents()
	if *list {
		listEvents()
		return
	}
	if *deleteName != "" {
		if deleteEvent(*deleteName) {
			fmt.Println("Event deleted.")
		} else {
			fmt.Println("Event not found.")
		}
		return
	}
	if *eventName != "" {
		event := findEvent(*eventName)
		if event != nil {
			countdown(*event, *format, *live)
		} else {
			fmt.Println("Event not found.")
		}
	} else {
		fmt.Println("Usage: countdown --event NAME --date DATE [--time TIME] [--format full|compact|short] [--live]")
	}
}

func main() {
	if len(os.Args) > 1 {
		cli()
	} else {
		interactive()
	}
}
