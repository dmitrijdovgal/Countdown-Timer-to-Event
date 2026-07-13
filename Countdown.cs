// Countdown.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

class Event
{
    public string Name { get; set; }
    public string Date { get; set; }
    public string Time { get; set; }
}

class Countdown
{
    private static List<Event> events = new List<Event>();
    private const string EventsFile = "events.json";

    static void LoadEvents()
    {
        try
        {
            string json = File.ReadAllText(EventsFile);
            events = JsonSerializer.Deserialize<List<Event>>(json) ?? new List<Event>();
        }
        catch { events = new List<Event>(); }
    }

    static void SaveEvents()
    {
        string json = JsonSerializer.Serialize(events, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(EventsFile, json);
    }

    static DateTime? ParseDate(string dateStr)
    {
        string[] formats = { "yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "dd.MM.yyyy" };
        foreach (var fmt in formats)
        {
            if (DateTime.TryParseExact(dateStr, fmt, null, System.Globalization.DateTimeStyles.None, out DateTime result))
                return result;
        }
        return null;
    }

    static Event FindEvent(string name)
    {
        return events.Find(e => e.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
    }

    static bool AddEvent(string name, string dateStr, string timeStr)
    {
        if (ParseDate(dateStr) == null) return false;
        if (string.IsNullOrEmpty(timeStr)) timeStr = "00:00";
        events.Add(new Event { Name = name, Date = dateStr, Time = timeStr });
        SaveEvents();
        return true;
    }

    static bool DeleteEvent(string name)
    {
        var ev = FindEvent(name);
        if (ev != null)
        {
            events.Remove(ev);
            SaveEvents();
            return true;
        }
        return false;
    }

    static string FormatCountdown(TimeSpan delta)
    {
        if (delta.TotalSeconds < 0) return "Event has passed!";
        int totalSec = (int)delta.TotalSeconds;
        int years = (int)(totalSec / (365.25 * 24 * 3600));
        totalSec -= (int)(years * 365.25 * 24 * 3600);
        int months = (int)(totalSec / (30.44 * 24 * 3600));
        totalSec -= (int)(months * 30.44 * 24 * 3600);
        int days = totalSec / (24 * 3600);
        totalSec -= days * (24 * 3600);
        int hours = totalSec / 3600;
        totalSec -= hours * 3600;
        int minutes = totalSec / 60;
        int seconds = totalSec % 60;
        var parts = new List<string>();
        if (years > 0) parts.Add($"{years} year{(years > 1 ? "s" : "")}");
        if (months > 0) parts.Add($"{months} month{(months > 1 ? "s" : "")}");
        if (days > 0) parts.Add($"{days} day{(days > 1 ? "s" : "")}");
        if (hours > 0) parts.Add($"{hours} hour{(hours > 1 ? "s" : "")}");
        if (minutes > 0) parts.Add($"{minutes} minute{(minutes > 1 ? "s" : "")}");
        if (seconds > 0) parts.Add($"{seconds} second{(seconds > 1 ? "s" : "")}");
        return parts.Count > 0 ? string.Join(", ", parts) : "0 seconds";
    }

    static void Countdown(Event ev, string formatStyle, bool live)
    {
        var timeParts = ev.Time.Split(':');
        int h = int.Parse(timeParts[0]);
        int m = int.Parse(timeParts[1]);
        var target = DateTime.Parse(ev.Date).AddHours(h).AddMinutes(m);
        var now = DateTime.Now;
        var delta = target - now;
        if (delta.TotalSeconds <= 0)
        {
            Console.WriteLine($"⏰ {ev.Name} is in the past!");
            return;
        }
        if (live)
        {
            while (delta.TotalSeconds > 0)
            {
                Console.Write($"\r⏳ {ev.Name}: {FormatCountdown(delta)}    ");
                System.Threading.Thread.Sleep(1000);
                now = DateTime.Now;
                delta = target - now;
            }
            Console.WriteLine($"\r🎉 {ev.Name} has arrived!    ");
        }
        else
        {
            if (formatStyle == "compact")
            {
                int totalSec = (int)delta.TotalSeconds;
                int days = totalSec / 86400;
                int hours = (totalSec % 86400) / 3600;
                int minutes = (totalSec % 3600) / 60;
                int seconds = totalSec % 60;
                Console.WriteLine($"⏳ {ev.Name}: {days:D2}:{hours:D2}:{minutes:D2}:{seconds:D2}");
            }
            else if (formatStyle == "short")
            {
                Console.WriteLine($"⏳ {ev.Name}: {(int)delta.TotalSeconds} seconds");
            }
            else
            {
                Console.WriteLine($"⏳ {ev.Name}: {FormatCountdown(delta)}");
            }
        }
    }

    static void ListEvents()
    {
        if (events.Count == 0)
        {
            Console.WriteLine("No events saved.");
            return;
        }
        foreach (var e in events)
        {
            var timeParts = e.Time.Split(':');
            int h = int.Parse(timeParts[0]);
            int m = int.Parse(timeParts[1]);
            var target = DateTime.Parse(e.Date).AddHours(h).AddMinutes(m);
            string status = target > DateTime.Now ? "⏳ pending" : "✅ passed";
            Console.WriteLine($"  {e.Name}: {e.Date} {e.Time} - {status}");
        }
    }

    static void Main(string[] args)
    {
        LoadEvents();
        if (args.Length > 0)
        {
            // CLI mode
            var dict = new Dictionary<string, string>();
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i].StartsWith("--"))
                {
                    string key = args[i].Substring(2);
                    if (i + 1 < args.Length && !args[i + 1].StartsWith("--"))
                        dict[key] = args[++i];
                    else
                        dict[key] = "true";
                }
            }
            if (dict.ContainsKey("list")) { ListEvents(); return; }
            if (dict.ContainsKey("delete"))
            {
                if (DeleteEvent(dict["delete"])) Console.WriteLine("Event deleted.");
                else Console.WriteLine("Event not found.");
                return;
            }
            if (dict.ContainsKey("event") && dict.ContainsKey("date"))
            {
                var ev = FindEvent(dict["event"]);
                if (ev != null)
                {
                    string format = dict.ContainsKey("format") ? dict["format"] : "full";
                    bool live = dict.ContainsKey("live");
                    Countdown(ev, format, live);
                }
                else Console.WriteLine("Event not found.");
            }
            else Console.WriteLine("Usage: Countdown --event NAME --date DATE [--time TIME] [--format full|compact|short] [--live]");
            return;
        }

        // Interactive mode
        Console.WriteLine("=== Countdown Timer ===");
        while (true)
        {
            Console.WriteLine("\n1. Set new event");
            Console.WriteLine("2. Show countdown");
            Console.WriteLine("3. Live countdown");
            Console.WriteLine("4. List events");
            Console.WriteLine("5. Delete event");
            Console.WriteLine("6. Save events");
            Console.WriteLine("7. Load events");
            Console.WriteLine("8. Exit");
            Console.Write("Choose: ");
            string choice = Console.ReadLine()?.Trim();
            switch (choice)
            {
                case "1":
                    Console.Write("Event name: ");
                    string name = Console.ReadLine()?.Trim();
                    if (string.IsNullOrEmpty(name)) { Console.WriteLine("Name required."); break; }
                    if (FindEvent(name) != null) { Console.WriteLine("Event already exists."); break; }
                    Console.Write("Event date (YYYY-MM-DD): ");
                    string dateStr = Console.ReadLine()?.Trim();
                    if (ParseDate(dateStr) == null) { Console.WriteLine("Invalid date."); break; }
                    Console.Write("Event time (HH:MM, optional): ");
                    string timeStr = Console.ReadLine()?.Trim();
                    if (string.IsNullOrEmpty(timeStr)) timeStr = "00:00";
                    if (AddEvent(name, dateStr, timeStr)) Console.WriteLine("Event saved.");
                    break;
                case "2":
                    Console.Write("Event name: ");
                    name = Console.ReadLine()?.Trim();
                    var ev = FindEvent(name);
                    if (ev == null) { Console.WriteLine("Event not found."); break; }
                    Countdown(ev, "full", false);
                    break;
                case "3":
                    Console.Write("Event name: ");
                    name = Console.ReadLine()?.Trim();
                    ev = FindEvent(name);
                    if (ev == null) { Console.WriteLine("Event not found."); break; }
                    Countdown(ev, "full", true);
                    break;
                case "4": ListEvents(); break;
                case "5":
                    Console.Write("Event name to delete: ");
                    name = Console.ReadLine()?.Trim();
                    if (DeleteEvent(name)) Console.WriteLine("Event deleted.");
                    else Console.WriteLine("Event not found.");
                    break;
                case "6": SaveEvents(); Console.WriteLine("Events saved."); break;
                case "7": LoadEvents(); Console.WriteLine("Events loaded."); break;
                case "8": Console.WriteLine("Goodbye!"); return;
                default: Console.WriteLine("Invalid choice."); break;
            }
        }
    }
}
