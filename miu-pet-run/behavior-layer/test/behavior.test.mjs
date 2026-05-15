import assert from 'node:assert/strict';

import {
  choosePetZone,
  getDayNightPhase,
  placePet,
  reducePetState,
  windowCoverageRatio,
} from '../src/index.mjs';

const config = {
  dayNight: {
    timezone: 'Asia/Shanghai',
    wakeStart: '07:30',
    workStart: '09:00',
    leisureStart: '18:30',
    sleepyStart: '22:30',
    sleepStart: '23:30',
  },
  behavior: {
    defaultZone: 'bottom-right',
    leisureWalkEnabled: true,
    nightSleepEnabled: true,
  },
  thresholds: {
    largeFrontWindowRatio: 0.6,
    fullscreenWindowRatio: 0.92,
    idleMs: 300000,
    mouseNearPetPx: 96,
  },
  availableActions: [
    'loaf',
    'sleep',
    'wake',
    'stretch',
    'peek',
    'edge-walk',
    'groom',
    'purr',
    'sit-watch',
    'celebrate',
    'comfort',
    'idle',
    'waiting',
    'jumping',
    'failed',
    'running-right',
  ],
};

assert.equal(getDayNightPhase(new Date('2026-05-11T23:45:00+08:00'), config.dayNight), 'night');
assert.equal(getDayNightPhase(new Date('2026-05-11T08:00:00+08:00'), config.dayNight), 'morning');
assert.equal(getDayNightPhase(new Date('2026-05-11T10:00:00+08:00'), config.dayNight), 'work');
assert.equal(getDayNightPhase(new Date('2026-05-11T20:00:00+08:00'), config.dayNight), 'leisure');
assert.equal(getDayNightPhase(new Date('2026-05-11T23:00:00+08:00'), config.dayNight), 'sleepy');

assert.deepEqual(
  reducePetState({ now: new Date('2026-05-11T10:00:00+08:00'), focused: true }, config),
  { mode: 'work', action: 'loaf', animationIntensity: 'low', shouldStealFocus: false },
);

assert.equal(reducePetState({ now: new Date('2026-05-11T23:45:00+08:00') }, config).action, 'sleep');
assert.equal(reducePetState({ event: 'success' }, config).action, 'celebrate');
assert.equal(reducePetState({ event: 'failed' }, config).action, 'comfort');
assert.equal(reducePetState({ taskRunning: true }, config).action, 'sit-watch');
assert.equal(reducePetState({ now: new Date('2026-05-11T20:00:00+08:00') }, config).action, 'edge-walk');
assert.equal(reducePetState({ now: new Date('2026-05-11T13:00:00+08:00'), userIdleMs: 600000, canPeek: true }, config).action, 'peek');

const screenRect = { x: 0, y: 0, width: 1000, height: 800 };
const largeWindow = { x: 0, y: 0, width: 800, height: 700 };
assert.equal(Math.round(windowCoverageRatio(largeWindow, screenRect) * 100), 70);
assert.equal(choosePetZone({ screenRect, frontWindowRect: largeWindow, mode: 'work' }, config).zone, 'bottom-right');

const fullscreenWindow = { x: 0, y: 0, width: 980, height: 780 };
assert.equal(choosePetZone({ screenRect, frontWindowRect: fullscreenWindow }, config).zone, 'hidden');

const placement = placePet({ screenRect, mode: 'work', petSize: { width: 96, height: 104 } }, config);
assert.equal(placement.zone, 'bottom-right');
assert.ok(placement.rect.x > 800);
assert.ok(placement.rect.y > 650);

console.log('Miu behavior-layer tests passed');
