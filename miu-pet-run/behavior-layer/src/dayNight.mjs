const MINUTES_PER_DAY = 24 * 60;

export const DEFAULT_DAY_NIGHT_CONFIG = Object.freeze({
  timezone: 'Asia/Shanghai',
  wakeStart: '07:30',
  workStart: '09:00',
  leisureStart: '18:30',
  sleepyStart: '22:30',
  sleepStart: '23:30',
});

export function parseClock(value) {
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) {
    throw new Error(`Invalid HH:mm clock value: ${value}`);
  }
  const [hours, minutes] = value.split(':').map(Number);
  return hours * 60 + minutes;
}

export function minutesInTimezone(date = new Date(), timezone = 'Asia/Shanghai') {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone: timezone,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const parts = Object.fromEntries(formatter.formatToParts(date).map((part) => [part.type, part.value]));
  return Number(parts.hour) * 60 + Number(parts.minute);
}

function isBetweenWrapped(value, start, end) {
  if (start === end) return true;
  if (start < end) return value >= start && value < end;
  return value >= start || value < end;
}

export function getDayNightPhase(date = new Date(), config = DEFAULT_DAY_NIGHT_CONFIG) {
  const merged = { ...DEFAULT_DAY_NIGHT_CONFIG, ...config };
  const now = minutesInTimezone(date, merged.timezone);
  const wakeStart = parseClock(merged.wakeStart);
  const workStart = parseClock(merged.workStart);
  const leisureStart = parseClock(merged.leisureStart);
  const sleepyStart = parseClock(merged.sleepyStart);
  const sleepStart = parseClock(merged.sleepStart);

  if (isBetweenWrapped(now, sleepStart, wakeStart)) return 'night';
  if (now >= wakeStart && now < workStart) return 'morning';
  if (now >= workStart && now < leisureStart) return 'work';
  if (now >= leisureStart && now < sleepyStart) return 'leisure';
  if (now >= sleepyStart && now < sleepStart) return 'sleepy';
  return 'night';
}

export function minutesUntilPhaseChange(date = new Date(), config = DEFAULT_DAY_NIGHT_CONFIG) {
  const merged = { ...DEFAULT_DAY_NIGHT_CONFIG, ...config };
  const now = minutesInTimezone(date, merged.timezone);
  const boundaries = [
    parseClock(merged.wakeStart),
    parseClock(merged.workStart),
    parseClock(merged.leisureStart),
    parseClock(merged.sleepyStart),
    parseClock(merged.sleepStart),
  ].sort((a, b) => a - b);
  for (const boundary of boundaries) {
    if (boundary > now) return boundary - now;
  }
  return MINUTES_PER_DAY - now + boundaries[0];
}
