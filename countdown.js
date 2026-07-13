// countdown.js
const fs = require('fs');
const readline = require('readline');

const EVENTS_FILE = 'events.json';
let events = [];

function loadEvents() {
    try {
        const data = fs.readFileSync(EVENTS_FILE, 'utf8');
        events = JSON.parse(data);
    } catch (e) {
        events = [];
    }
}

function saveEvents() {
    fs.writeFileSync(EVENTS_FILE, JSON.stringify(events, null, 2));
}

function parseDate(dateStr) {
    const formats = [
        /^(\d{4})-(\d{2})-(\d{2})$/,
        /^(\d{2})\/(\d{2})\/(\d{4})$/,
        /^(\d{2})\/(\d{2})\/(\d{4})$/,
        /^(\d{2})\.(\d{2})\.(\d{4})$/
    ];
    for (const fmt of formats) {
        const match = dateStr.match(fmt);
        if (match) {
            let y, m, d;
            if (fmt === formats[0]) { y = match[1]; m = match[2]; d = match[3]; }
            else if (fmt === formats[1]) { d = match[1]; m = match[2]; y = match[3]; }
            else if (fmt === formats[2]) { m = match[1]; d = match[2]; y = match[3]; }
            else { d = match[1]; m = match[2]; y = match[3]; }
            const date = new Date(parseInt(y), parseInt(m)-1, parseInt(d));
            if (!isNaN(date)) return date;
        }
    }
    return null;
}

function findEvent(name) {
    return events.find(e => e.name.toLowerCase() === name.toLowerCase());
}

function addEvent(name, dateStr, timeStr) {
    const date = parseDate(dateStr);
    if (!date) return false;
    if (!timeStr) timeStr = '00:00';
    const [h, m] = timeStr.split(':').map(Number);
    date.setHours(h || 0, m || 0, 0, 0);
    events.push({ name, date: dateStr, time: timeStr });
    saveEvents();
    return true;
}

function deleteEvent(name) {
    const idx = events.findIndex(e => e.name.toLowerCase() === name.toLowerCase());
    if (idx !== -1) {
        events.splice(idx, 1);
        saveEvents();
        return true;
    }
    return false;
}

function formatCountdown(ms) {
    if (ms < 0) return 'Event has passed!';
    const totalSec = Math.floor(ms / 1000);
    const years = Math.floor(totalSec / (365.25 * 24 * 3600));
    let rem = totalSec - years * (365.25 * 24 * 3600);
    const months = Math.floor(rem / (30.44 * 24 * 3600));
    rem -= months * (30.44 * 24 * 3600);
    const days = Math.floor(rem / (24 * 3600));
    rem -= days * (24 * 3600);
    const hours = Math.floor(rem / 3600);
    rem -= hours * 3600;
    const minutes = Math.floor(rem / 60);
    const seconds = rem % 60;
    const parts = [];
    if (years > 0) parts.push(`${years} year${years > 1 ? 's' : ''}`);
    if (months > 0) parts.push(`${months} month${months > 1 ? 's' : ''}`);
    if (days > 0) parts.push(`${days} day${days > 1 ? 's' : ''}`);
    if (hours > 0) parts.push(`${hours} hour${hours > 1 ? 's' : ''}`);
    if (minutes > 0) parts.push(`${minutes} minute${minutes > 1 ? 's' : ''}`);
    if (seconds > 0) parts.push(`${seconds} second${seconds > 1 ? 's' : ''}`);
    return parts.length ? parts.join(', ') : '0 seconds';
}

function countdown(event, formatStyle, live) {
    const [h, m] = (event.time || '00:00').split(':').map(Number);
    const target = new Date(event.date + 'T' + String(h||0).padStart(2,'0') + ':' + String(m||0).padStart(2,'0'));
    const now = new Date();
    let diff = target - now;
    if (diff <= 0) {
        console.log(`⏰ ${event.name} is in the past!`);
        return;
    }
    if (live) {
        const interval = setInterval(() => {
            const now2 = new Date();
            const diff2 = target - now2;
            if (diff2 <= 0) {
                clearInterval(interval);
                console.log(`\r🎉 ${event.name} has arrived!    `);
                return;
            }
            process.stdout.write(`\r⏳ ${event.name}: ${formatCountdown(diff2)}    `);
        }, 1000);
        setTimeout(() => {}, 10);
    } else {
        if (formatStyle === 'compact') {
            const totalSec = Math.floor(diff / 1000);
            const days = Math.floor(totalSec / 86400);
            const hours = Math.floor((totalSec % 86400) / 3600);
            const minutes = Math.floor((totalSec % 3600) / 60);
            const seconds = totalSec % 60;
            console.log(`⏳ ${event.name}: ${String(days).padStart(2,'0')}:${String(hours).padStart(2,'0')}:${String(minutes).padStart(2,'0')}:${String(seconds).padStart(2,'0')}`);
        } else if (formatStyle === 'short') {
            console.log(`⏳ ${event.name}: ${Math.floor(diff / 1000)} seconds`);
        } else {
            console.log(`⏳ ${event.name}: ${formatCountdown(diff)}`);
        }
    }
}

function listEvents() {
    if (events.length === 0) {
        console.log('No events saved.');
        return;
    }
    for (const e of events) {
        const [h, m] = (e.time || '00:00').split(':').map(Number);
        const target = new Date(e.date + 'T' + String(h||0).padStart(2,'0') + ':' + String(m||0).padStart(2,'0'));
        const status = target > new Date() ? '⏳ pending' : '✅ passed';
        console.log(`  ${e.name}: ${e.date} ${e.time} - ${status}`);
    }
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

async function interactive() {
    loadEvents();
    console.log('=== Countdown Timer ===');
    while (true) {
        console.log('\n1. Set new event');
        console.log('2. Show countdown');
        console.log('3. Live countdown');
        console.log('4. List events');
        console.log('5. Delete event');
        console.log('6. Save events');
        console.log('7. Load events');
        console.log('8. Exit');
        const choice = await ask('Choose: ');
        switch (choice.trim()) {
            case '1': {
                const name = await ask('Event name: ');
                if (!name.trim()) { console.log('Name required.'); break; }
                if (findEvent(name.trim())) { console.log('Event already exists.'); break; }
                const dateStr = await ask('Event date (YYYY-MM-DD): ');
                if (!parseDate(dateStr.trim())) { console.log('Invalid date.'); break; }
                let timeStr = await ask('Event time (HH:MM, optional): ');
                if (!timeStr.trim()) timeStr = '00:00';
                if (addEvent(name.trim(), dateStr.trim(), timeStr.trim())) {
                    console.log('Event saved.');
                }
                break;
            }
            case '2': {
                const name = await ask('Event name: ');
                const event = findEvent(name.trim());
                if (!event) { console.log('Event not found.'); break; }
                countdown(event, 'full', false);
                break;
            }
            case '3': {
                const name = await ask('Event name: ');
                const event = findEvent(name.trim());
                if (!event) { console.log('Event not found.'); break; }
                countdown(event, 'full', true);
                break;
            }
            case '4': listEvents(); break;
            case '5': {
                const name = await ask('Event name to delete: ');
                if (deleteEvent(name.trim())) console.log('Event deleted.');
                else console.log('Event not found.');
                break;
            }
            case '6': saveEvents(); console.log('Events saved.'); break;
            case '7': loadEvents(); console.log('Events loaded.'); break;
            case '8': console.log('Goodbye!'); rl.close(); return;
            default: console.log('Invalid choice.');
        }
    }
}

function cli() {
    const args = require('minimist')(process.argv.slice(2));
    loadEvents();
    if (args.list) { listEvents(); return; }
    if (args.delete) {
        if (deleteEvent(args.delete)) console.log('Event deleted.');
        else console.log('Event not found.');
        return;
    }
    if (args.event && args.date) {
        const event = findEvent(args.event);
        if (event) {
            const formatStyle = args.format || 'full';
            const live = args.live || false;
            countdown(event, formatStyle, live);
        } else {
            console.log('Event not found.');
        }
    } else if (args.event) {
        const event = findEvent(args.event);
        if (event) countdown(event, args.format || 'full', args.live || false);
        else console.log('Event not found.');
    } else {
        console.log('Usage: node countdown.js --event NAME --date DATE [--time TIME] [--format full|compact|short] [--live]');
    }
}

if (process.argv.length > 2) {
    cli();
} else {
    interactive();
}
