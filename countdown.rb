# countdown.rb
require 'json'
require 'date'
require 'optparse'
require 'time'

EVENTS_FILE = 'events.json'
$events = []

def load_events
  $events = JSON.parse(File.read(EVENTS_FILE)) rescue []
end

def save_events
  File.write(EVENTS_FILE, JSON.pretty_generate($events))
end

def parse_date(date_str)
  formats = ['%Y-%m-%d', '%d/%m/%Y', '%m/%d/%Y', '%d.%m.%Y']
  formats.each do |fmt|
    begin
      return Date.strptime(date_str, fmt)
    rescue ArgumentError
    end
  end
  nil
end

def find_event(name)
  $events.find { |e| e['name'].downcase == name.downcase }
end

def add_event(name, date_str, time_str)
  return false unless parse_date(date_str)
  time_str = '00:00' if time_str.nil? || time_str.empty?
  $events << { 'name' => name, 'date' => date_str, 'time' => time_str }
  save_events
  true
end

def delete_event(name)
  idx = $events.index { |e| e['name'].downcase == name.downcase }
  if idx
    $events.delete_at(idx)
    save_events
    true
  else
    false
  end
end

def format_countdown(seconds)
  return 'Event has passed!' if seconds < 0
  years = (seconds / (365.25 * 24 * 3600)).to_i
  seconds -= (years * 365.25 * 24 * 3600).to_i
  months = (seconds / (30.44 * 24 * 3600)).to_i
  seconds -= (months * 30.44 * 24 * 3600).to_i
  days = (seconds / (24 * 3600)).to_i
  seconds -= days * 24 * 3600
  hours = (seconds / 3600).to_i
  seconds -= hours * 3600
  minutes = (seconds / 60).to_i
  seconds = seconds % 60
  parts = []
  parts << "#{years} year#{years > 1 ? 's' : ''}" if years > 0
  parts << "#{months} month#{months > 1 ? 's' : ''}" if months > 0
  parts << "#{days} day#{days > 1 ? 's' : ''}" if days > 0
  parts << "#{hours} hour#{hours > 1 ? 's' : ''}" if hours > 0
  parts << "#{minutes} minute#{minutes > 1 ? 's' : ''}" if minutes > 0
  parts << "#{seconds} second#{seconds > 1 ? 's' : ''}" if seconds > 0
  parts.empty? ? '0 seconds' : parts.join(', ')
end

def countdown(event, format_style, live)
  target = Time.parse("#{event['date']} #{event['time']}")
  now = Time.now
  diff = target - now
  if diff <= 0
    puts "⏰ #{event['name']} is in the past!"
    return
  end
  if live
    while diff > 0
      print "\r⏳ #{event['name']}: #{format_countdown(diff)}    "
      sleep 1
      now = Time.now
      diff = target - now
    end
    puts "\r🎉 #{event['name']} has arrived!    "
  else
    if format_style == 'compact'
      total_sec = diff.to_i
      days = total_sec / 86400
      hours = (total_sec % 86400) / 3600
      minutes = (total_sec % 3600) / 60
      seconds = total_sec % 60
      puts "⏳ #{event['name']}: #{'%02d' % days}:#{'%02d' % hours}:#{'%02d' % minutes}:#{'%02d' % seconds}"
    elsif format_style == 'short'
      puts "⏳ #{event['name']}: #{diff.to_i} seconds"
    else
      puts "⏳ #{event['name']}: #{format_countdown(diff)}"
    end
  end
end

def list_events
  if $events.empty?
    puts 'No events saved.'
    return
  end
  $events.each do |e|
    target = Time.parse("#{e['date']} #{e['time']}")
    status = target > Time.now ? '⏳ pending' : '✅ passed'
    puts "  #{e['name']}: #{e['date']} #{e['time']} - #{status}"
  end
end

def interactive
  load_events
  puts "=== Countdown Timer ==="
  loop do
    puts "\n1. Set new event"
    puts "2. Show countdown"
    puts "3. Live countdown"
    puts "4. List events"
    puts "5. Delete event"
    puts "6. Save events"
    puts "7. Load events"
    puts "8. Exit"
    print "Choose: "
    choice = gets.chomp.strip
    case choice
    when '1'
      print "Event name: "
      name = gets.chomp.strip
      if name.empty?
        puts "Name required."
        next
      end
      if find_event(name)
        puts "Event already exists."
        next
      end
      print "Event date (YYYY-MM-DD): "
      date_str = gets.chomp.strip
      unless parse_date(date_str)
        puts "Invalid date."
        next
      end
      print "Event time (HH:MM, optional): "
      time_str = gets.chomp.strip
      if add_event(name, date_str, time_str)
        puts "Event saved."
      end
    when '2'
      print "Event name: "
      name = gets.chomp.strip
      event = find_event(name)
      if event
        countdown(event, 'full', false)
      else
        puts "Event not found."
      end
    when '3'
      print "Event name: "
      name = gets.chomp.strip
      event = find_event(name)
      if event
        countdown(event, 'full', true)
      else
        puts "Event not found."
      end
    when '4'
      list_events
    when '5'
      print "Event name to delete: "
      name = gets.chomp.strip
      if delete_event(name)
        puts "Event deleted."
      else
        puts "Event not found."
      end
    when '6'
      save_events
      puts "Events saved."
    when '7'
      load_events
      puts "Events loaded."
    when '8'
      puts "Goodbye!"
      break
    else
      puts "Invalid choice."
    end
  end
end

def cli
  options = {}
  OptionParser.new do |opts|
    opts.on('--event NAME', 'Event name') { |v| options[:event] = v }
    opts.on('--date DATE', 'Event date') { |v| options[:date] = v }
    opts.on('--time TIME', 'Event time') { |v| options[:time] = v }
    opts.on('--format FORMAT', 'Output format') { |v| options[:format] = v }
    opts.on('--live', 'Live countdown') { options[:live] = true }
    opts.on('--list', 'List events') { options[:list] = true }
    opts.on('--delete NAME', 'Delete event') { |v| options[:delete] = v }
  end.parse!
  load_events
  if options[:list]
    list_events
    return
  end
  if options[:delete]
    if delete_event(options[:delete])
      puts "Event deleted."
    else
      puts "Event not found."
    end
    return
  end
  if options[:event] && options[:date]
    event = find_event(options[:event])
    if event
      countdown(event, options[:format] || 'full', options[:live] || false)
    else
      puts "Event not found."
    end
  else
    puts "Usage: ruby countdown.rb --event NAME --date DATE [--time TIME] [--format full|compact|short] [--live]"
  end
end

if ARGV.empty?
  interactive
else
  cli
end
