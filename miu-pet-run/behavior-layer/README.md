# Miu Behavior Layer

This folder implements Phase 2 to Phase 4 as a small standalone behavior module:

- Phase 2: core state machine.
- Phase 3: window avoidance and safe-zone placement.
- Phase 4: Beijing-time day/night rhythm.

It does not implement the reminder system. Reminder hooks can be added later as another event source.

## Concepts

`PetMode` is the high-level reason for Miu's behavior:

- `work`
- `leisure`
- `night`
- `busy`
- `idle`
- `success`
- `failed`
- `morning`
- `sleepy`

`PetAction` is the visual action the renderer should play:

- Phase 1 extension actions: `loaf`, `sleep`, `wake`, `stretch`, `peek`, `edge-walk`, `groom`, `purr`, `sit-watch`, `celebrate`, `comfort`
- Current atlas fallback actions: `idle`, `running-right`, `running-left`, `waving`, `jumping`, `failed`, `waiting`, `running`, `review`

## Files

- `src/dayNight.mjs`: Beijing-time rhythm.
- `src/stateMachine.mjs`: event/context to mode/action.
- `src/windowAvoidance.mjs`: safe zones and placement choice.
- `src/index.mjs`: public API.
- `config/defaults.json`: default behavior settings.
- `test/behavior.test.mjs`: executable tests.

## Run Tests

```bash
node miu-pet-run/behavior-layer/test/behavior.test.mjs
```
