// Countdown.java
import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.time.format.*;
import java.util.*;
import com.google.gson.*;

public class Countdown {
    private static List<Event> events = new ArrayList<>();
    private static final String EVENTS_FILE = "events.json";
    private static final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    static class Event {
        String name;
        String date;
        String time;
    }

    static void loadEvents() {
        try {
            String json = new String(Files.readAllBytes(Paths.get(EVENTS_FILE)));
            Event[] arr = gson.fromJson(json, Event[].class);
            if (arr != null) events = new ArrayList<>(Arrays.asList(arr));
        } catch (Exception e) {
            events = new ArrayList<>();
        }
    }

    static void saveEvents() {
        String json = gson.toJson(events);
        try {
            Files.write(Paths.get(EVENTS_FILE), json.getBytes());
        } catch (Exception e) {}
    }

    static LocalDate parseDate(String dateStr) {
        DateTimeFormatter[] formatters = {
            DateTimeFormatter.ofPattern("yyyy-MM-dd"),
            DateTimeFormatter.ofPattern("dd/MM/yyyy"),
            DateTimeFormatter.ofPattern("MM/dd/yyyy"),
            DateTimeFormatter.ofPattern("dd.MM.yyyy")
        };
        for (DateTimeFormatter fmt : formatters) {
            try {
                return LocalDate.parse(dateStr, fmt);
            } catch (DateTimeParseException e) {}
        }
        return null;
    }

    static Event findEvent(String name) {
        for (Event e : events) {
            if (e.name.equalsIgnoreCase(name)) return e;
        }
        return null;
    }

    static boolean addEvent(String name, String dateStr, String timeStr) {
        if (parseDate(dateStr) == null) return false;
        if (timeStr == null || timeStr.isEmpty()) timeStr = "00:00";
        Event e = new Event();
        e.name = name;
        e.date = dateStr;
        e.time = timeStr;
        events.add(e);
        saveEvents();
        return true;
    }

    static boolean deleteEvent(String name) {
        for (int i = 0; i < events.size(); i++) {
            if (events.get(i).name.equalsIgnoreCase(name)) {
                events.remove(i);
                saveEvents();
                return true;
            }
        }
        return false;
    }

    static String formatCountdown(long seconds) {
        if (seconds < 0) return "Event has passed!";
        long years = (long)(seconds / (365.25 * 24 * 3600));
        seconds -= (long)(years * 365.25 * 24 * 3600);
        long months = (long)(seconds / (30.44 * 24 * 3600));
        seconds -= (long)(months * 30.44 * 24 * 3600);
        long days = seconds / (24 * 3600);
        seconds -= days * (24 * 3600);
        long hours = seconds / 3600;
        seconds -= hours * 3600;
        long minutes = seconds / 60;
        seconds %= 60;
        List<String> parts = new ArrayList<>();
        if (years > 0) parts.add(years + " year" + (years > 1 ? "s" : ""));
        if (months > 0) parts.add(months + " month" + (months > 1 ? "s" : ""));
        if (days > 0) parts.add(days + " day" + (days > 1 ? "s" : ""));
        if (hours > 0) parts.add(hours + " hour" + (hours > 1 ? "s" : ""));
        if (minutes > 0) parts.add(minutes + " minute" + (minutes > 1 ? "s" : ""));
        if (seconds > 0) parts.add(seconds + " second" + (seconds > 1 ? "s" : ""));
        return parts.isEmpty() ? "0 seconds" : String.join(", ", parts);
    }

    static void countdown(Event ev, String formatStyle, boolean live) {
        String[] timeParts = ev.time.split(":");
        int h = Integer.parseInt(timeParts[0]);
        int m = Integer.parseInt(timeParts[1]);
        LocalDate date = parseDate(ev.date);
        if (date == null) return;
        LocalDateTime target = LocalDateTime.of(date, LocalTime.of(h, m));
        LocalDateTime now = LocalDateTime.now();
        long seconds = Duration.between(now, target).getSeconds();
        if (seconds <= 0) {
            System.out.println("⏰ " + ev.name + " is in the past!");
            return;
        }
        if (live) {
            while (seconds > 0) {
                System.out.print("\r⏳ " + ev.name + ": " + formatCountdown(seconds) + "    ");
                try { Thread.sleep(1000); } catch (InterruptedException e) {}
                now = LocalDateTime.now();
                seconds = Duration.between(now, target).getSeconds();
            }
            System.out.println("\r🎉 " + ev.name + " has arrived!    ");
        } else {
            if ("compact".equals(formatStyle)) {
                long totalSec = seconds;
                long days = totalSec / 86400;
                long hours = (totalSec % 86400) / 3600;
                long minutes = (totalSec % 3600) / 60;
                long secs = totalSec % 60;
                System.out.printf("⏳ %s: %02d:%02d:%02d:%02d%n", ev.name, days, hours, minutes, secs);
            } else if ("short".equals(formatStyle)) {
                System.out.println("⏳ " + ev.name + ": " + seconds + " seconds");
            } else {
                System.out.println("⏳ " + ev.name + ": " + formatCountdown(seconds));
            }
        }
    }

    static void listEvents() {
        if (events.isEmpty()) {
            System.out.println("No events saved.");
            return;
        }
        for (Event e : events) {
            String[] timeParts = e.time.split(":");
            int h = Integer.parseInt(timeParts[0]);
            int m = Integer.parseInt(timeParts[1]);
            LocalDate date = parseDate(e.date);
            LocalDateTime target = LocalDateTime.of(date, LocalTime.of(h, m));
            String status = target.isAfter(LocalDateTime.now()) ? "⏳ pending" : "✅ passed";
            System.out.printf("  %s: %s %s - %s%n", e.name, e.date, e.time, status);
        }
    }

    static void interactive() throws Exception {
        Scanner scanner = new Scanner(System.in);
        loadEvents();
        System.out.println("=== Countdown Timer ===");
        while (true) {
            System.out.println("\n1. Set new event");
            System.out.println("2. Show countdown");
            System.out.println("3. Live countdown");
            System.out.println("4. List events");
            System.out.println("5. Delete event");
            System.out.println("6. Save events");
            System.out.println("7. Load events");
            System.out.println("8. Exit");
            System.out.print("Choose: ");
            String choice = scanner.nextLine().trim();
            switch (choice) {
                case "1":
                    System.out.print("Event name: ");
                    String name = scanner.nextLine().trim();
                    if (name.isEmpty()) { System.out.println("Name required."); break; }
                    if (findEvent(name) != null) { System.out.println("Event already exists."); break; }
                    System.out.print("Event date (YYYY-MM-DD): ");
                    String dateStr = scanner.nextLine().trim();
                    if (parseDate(dateStr) == null) { System.out.println("Invalid date."); break; }
                    System.out.print("Event time (HH:MM, optional): ");
                    String timeStr = scanner.nextLine().trim();
                    if (timeStr.isEmpty()) timeStr = "00:00";
                    if (addEvent(name, dateStr, timeStr)) System.out.println("Event saved.");
                    break;
                case "2":
                    System.out.print("Event name: ");
                    name = scanner.nextLine().trim();
                    Event ev = findEvent(name);
                    if (ev == null) { System.out.println("Event not found."); break; }
                    countdown(ev, "full", false);
                    break;
                case "3":
                    System.out.print("Event name: ");
                    name = scanner.nextLine().trim();
                    ev = findEvent(name);
                    if (ev == null) { System.out.println("Event not found."); break; }
                    countdown(ev, "full", true);
                    break;
                case "4": listEvents(); break;
                case "5":
                    System.out.print("Event name to delete: ");
                    name = scanner.nextLine().trim();
                    if (deleteEvent(name)) System.out.println("Event deleted.");
                    else System.out.println("Event not found.");
                    break;
                case "6": saveEvents(); System.out.println("Events saved."); break;
                case "7": loadEvents(); System.out.println("Events loaded."); break;
                case "8": System.out.println("Goodbye!"); scanner.close(); return;
                default: System.out.println("Invalid choice.");
            }
        }
    }

    static void cli(String[] args) {
        Map<String, String> params = new HashMap<>();
        for (int i = 0; i < args.length; i++) {
            if (args[i].startsWith("--")) {
                String key = args[i].substring(2);
                if (i + 1 < args.length && !args[i+1].startsWith("--"))
                    params.put(key, args[++i]);
                else
                    params.put(key, "true");
            }
        }
        loadEvents();
        if (params.containsKey("list")) { listEvents(); return; }
        if (params.containsKey("delete")) {
            if (deleteEvent(params.get("delete"))) System.out.println("Event deleted.");
            else System.out.println("Event not found.");
            return;
        }
        if (params.containsKey("event") && params.containsKey("date")) {
            Event ev = findEvent(params.get("event"));
            if (ev != null) {
                String format = params.getOrDefault("format", "full");
                boolean live = params.containsKey("live");
                countdown(ev, format, live);
            } else System.out.println("Event not found.");
        } else {
            System.out.println("Usage: java Countdown --event NAME --date DATE [--time TIME] [--format full|compact|short] [--live]");
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length > 0) cli(args);
        else interactive();
    }
}
