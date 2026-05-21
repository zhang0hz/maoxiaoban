export const ZONES = Object.freeze([
  'bottom-right',
  'bottom-left',
  'top-right',
  'top-left',
  'window-edge',
  'desktop-free',
  'hidden',
]);

export function rectArea(rect) {
  return Math.max(0, rect.width) * Math.max(0, rect.height);
}

export function windowCoverageRatio(windowRect, screenRect) {
  if (!windowRect || !screenRect) return 0;
  return rectArea(windowRect) / Math.max(1, rectArea(screenRect));
}

function cornerRect(zone, screen, petSize, margin) {
  const xRight = screen.x + screen.width - petSize.width - margin;
  const xLeft = screen.x + margin;
  const yTop = screen.y + margin;
  const yBottom = screen.y + screen.height - petSize.height - margin;
  switch (zone) {
    case 'bottom-left':
      return { x: xLeft, y: yBottom, width: petSize.width, height: petSize.height };
    case 'top-right':
      return { x: xRight, y: yTop, width: petSize.width, height: petSize.height };
    case 'top-left':
      return { x: xLeft, y: yTop, width: petSize.width, height: petSize.height };
    case 'bottom-right':
    default:
      return { x: xRight, y: yBottom, width: petSize.width, height: petSize.height };
  }
}

function intersects(a, b) {
  return (
    a.x < b.x + b.width
    && a.x + a.width > b.x
    && a.y < b.y + b.height
    && a.y + a.height > b.y
  );
}

function distanceToRect(point, rect) {
  const dx = Math.max(rect.x - point.x, 0, point.x - (rect.x + rect.width));
  const dy = Math.max(rect.y - point.y, 0, point.y - (rect.y + rect.height));
  return Math.hypot(dx, dy);
}

export function choosePetZone(context = {}, config = {}) {
  const thresholds = {
    largeFrontWindowRatio: 0.6,
    fullscreenWindowRatio: 0.92,
    mouseNearPetPx: 96,
    ...(config.thresholds ?? {}),
  };
  const screen = context.screenRect ?? { x: 0, y: 0, width: 1440, height: 900 };
  const frontWindow = context.frontWindowRect;
  const ratio = windowCoverageRatio(frontWindow, screen);

  if (context.presentationMode || ratio >= thresholds.fullscreenWindowRatio) {
    return { zone: 'hidden', reason: 'fullscreen-or-presentation' };
  }

  if (context.mode === 'work' || context.userTyping || ratio >= thresholds.largeFrontWindowRatio) {
    return { zone: config.behavior?.defaultZone ?? 'bottom-right', reason: 'quiet-work-corner' };
  }

  if (context.mode === 'leisure' && config.behavior?.leisureWalkEnabled !== false && frontWindow) {
    return { zone: 'window-edge', reason: 'leisure-edge-walk' };
  }

  if (context.userIdleMs >= (config.thresholds?.idleMs ?? 300000)) {
    return { zone: 'desktop-free', reason: 'idle-free-roam' };
  }

  return { zone: config.behavior?.defaultZone ?? 'bottom-right', reason: 'default-safe-zone' };
}

export function placePet(context = {}, config = {}) {
  const petSize = context.petSize ?? { width: 96, height: 104 };
  const margin = context.margin ?? 16;
  const screen = context.screenRect ?? { x: 0, y: 0, width: 1440, height: 900 };
  const { zone, reason } = choosePetZone(context, config);
  if (zone === 'hidden') return { zone, reason, rect: null };

  if (zone === 'window-edge' && context.frontWindowRect) {
    const w = context.frontWindowRect;
    const rect = {
      x: Math.min(screen.x + screen.width - petSize.width - margin, w.x + w.width - petSize.width),
      y: Math.min(screen.y + screen.height - petSize.height - margin, w.y + w.height + margin),
      width: petSize.width,
      height: petSize.height,
    };
    return { zone, reason, rect };
  }

  const preferredZones = [zone, 'bottom-right', 'bottom-left', 'top-right', 'top-left'];
  for (const candidate of preferredZones) {
    if (!ZONES.includes(candidate) || candidate === 'window-edge' || candidate === 'desktop-free') continue;
    const rect = cornerRect(candidate, screen, petSize, margin);
    if (context.frontWindowRect && intersects(rect, context.frontWindowRect)) continue;
    if (
      context.mouse
      && distanceToRect(context.mouse, rect) < (config.thresholds?.mouseNearPetPx ?? 96)
    ) {
      continue;
    }
    return { zone: candidate, reason, rect };
  }

  return { zone: 'bottom-right', reason: 'fallback-corner', rect: cornerRect('bottom-right', screen, petSize, margin) };
}
