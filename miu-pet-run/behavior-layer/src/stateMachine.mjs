import { DEFAULT_DAY_NIGHT_CONFIG, getDayNightPhase } from './dayNight.mjs';

export const EXTENSION_ACTIONS = Object.freeze({
  loaf: 'loaf',
  sleep: 'sleep',
  wake: 'wake',
  stretch: 'stretch',
  peek: 'peek',
  edgeWalk: 'edge-walk',
  groom: 'groom',
  purr: 'purr',
  sitWatch: 'sit-watch',
  celebrate: 'celebrate',
  comfort: 'comfort',
});

export const ATLAS_FALLBACK_ACTIONS = Object.freeze({
  idle: 'idle',
  runRight: 'running-right',
  runLeft: 'running-left',
  wave: 'waving',
  jump: 'jumping',
  failed: 'failed',
  waiting: 'waiting',
  running: 'running',
  review: 'review',
});

const DEFAULT_AVAILABLE_ACTIONS = new Set([
  ...Object.values(ATLAS_FALLBACK_ACTIONS),
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
]);

const ACTION_FALLBACKS = Object.freeze({
  loaf: 'idle',
  sleep: 'waiting',
  wake: 'idle',
  stretch: 'jumping',
  peek: 'waving',
  'edge-walk': 'running-right',
  groom: 'idle',
  purr: 'idle',
  'sit-watch': 'waiting',
  celebrate: 'jumping',
  comfort: 'failed',
});

function chooseAction(primary, availableActions = DEFAULT_AVAILABLE_ACTIONS) {
  const available = availableActions instanceof Set ? availableActions : new Set(availableActions);
  if (available.has(primary)) return primary;
  return ACTION_FALLBACKS[primary] ?? 'idle';
}

export function inferMode(context = {}, config = {}) {
  if (context.event === 'success') return 'success';
  if (context.event === 'failed') return 'failed';
  if (context.taskRunning) return 'busy';
  if (context.userInteraction === 'hover') return 'idle';
  if (context.userInteraction === 'single-click') return 'idle';
  if (context.userInteraction === 'double-click') return 'leisure';

  const dayNight = getDayNightPhase(
    context.now ?? new Date(),
    { ...DEFAULT_DAY_NIGHT_CONFIG, ...(config.dayNight ?? {}) },
  );
  if (dayNight === 'night') return 'night';
  if (dayNight === 'morning') return 'morning';
  if (dayNight === 'sleepy') return 'sleepy';

  if (context.userIdleMs >= (config.thresholds?.idleMs ?? 300000)) {
    return dayNight === 'work' ? 'idle' : 'leisure';
  }
  return dayNight;
}

export function actionForMode(mode, context = {}, config = {}) {
  const available = config.availableActions ?? DEFAULT_AVAILABLE_ACTIONS;
  const quiet = context.quietMode || context.fullscreen || context.userTyping;

  if (quiet && mode !== 'night' && mode !== 'failed') {
    return chooseAction('loaf', available);
  }

  switch (mode) {
    case 'night':
      return config.behavior?.nightSleepEnabled === false
        ? chooseAction('loaf', available)
        : chooseAction('sleep', available);
    case 'morning':
      return chooseAction(context.justWoke ? 'wake' : 'stretch', available);
    case 'sleepy':
      return chooseAction('groom', available);
    case 'work':
      return chooseAction(context.focused ? 'loaf' : 'purr', available);
    case 'busy':
      return chooseAction('sit-watch', available);
    case 'idle':
      return chooseAction(context.canPeek ? 'peek' : 'groom', available);
    case 'leisure':
      return chooseAction(config.behavior?.leisureWalkEnabled === false ? 'waving' : 'edge-walk', available);
    case 'success':
      return chooseAction('celebrate', available);
    case 'failed':
      return chooseAction('comfort', available);
    default:
      return chooseAction('idle', available);
  }
}

export function reducePetState(context = {}, config = {}) {
  const mode = inferMode(context, config);
  const action = actionForMode(mode, context, config);
  return {
    mode,
    action,
    animationIntensity: mode === 'work' || context.quietMode ? 'low' : 'medium',
    shouldStealFocus: false,
  };
}
