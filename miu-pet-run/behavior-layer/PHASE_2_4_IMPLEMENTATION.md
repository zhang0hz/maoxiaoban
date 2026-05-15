# Miu Phase 2-4 Implementation

## Phase 2: State Machine

Implemented in `src/stateMachine.mjs`.

Inputs:

- current time
- task events
- user interaction
- focused / typing / idle context
- available visual actions

Outputs:

- `mode`
- `action`
- `animationIntensity`
- `shouldStealFocus`

Primary mappings:

- work + focused -> `loaf`
- work + relaxed -> `purr`
- busy task -> `sit-watch`
- idle + can peek -> `peek`
- leisure -> `edge-walk`
- night -> `sleep`
- success -> `celebrate`
- failed -> `comfort`

## Phase 3: Window Avoidance

Implemented in `src/windowAvoidance.mjs`.

Rules:

- fullscreen or presentation -> `hidden`
- work, typing, or large front window -> safe corner
- leisure with a window -> `window-edge`
- long idle -> `desktop-free`
- mouse-near-pet can force corner fallback

The strategy returns placement intent and a suggested pet rectangle. It does not take OS permissions or move real windows by itself.

## Phase 4: Beijing-Time Rhythm

Implemented in `src/dayNight.mjs`.

Default schedule:

- `07:30 - 09:00` -> `morning`
- `09:00 - 18:30` -> `work`
- `18:30 - 22:30` -> `leisure`
- `22:30 - 23:30` -> `sleepy`
- `23:30 - 07:30` -> `night`

Timezone:

- `Asia/Shanghai`

## Validation

Run:

```bash
node miu-pet-run/behavior-layer/test/behavior.test.mjs
```

Expected:

```text
Miu behavior-layer tests passed
```
