# Miu Phase 1 Actions

This folder contains the Phase 1 visual-action expansion for Miu.

Current Codex pet packages use a fixed 8x9 atlas with these runtime states:

- `idle`
- `running-right`
- `running-left`
- `waving`
- `jumping`
- `failed`
- `waiting`
- `running`
- `review`

Phase 1 adds extra visual actions as an extension asset library first. Behavior-layer work can later map these actions to work, leisure, night, and interaction states. Actions that fit the current fixed runtime states can also be remapped into the 8x9 atlas in a later compatibility pass.

## Phase 1 Scope

Priority actions:

1. `loaf`
2. `sleep`
3. `wake`
4. `stretch`
5. `peek`
6. `edge-walk`
7. `groom`
8. `purr`
9. `sit-watch`
10. `celebrate`
11. `comfort`

## Visual Contract

- Keep Miu as the same blue bicolor ragdoll cat.
- Preserve bright blue eyes, pink nose, white blaze, cool gray-blue ears and mask, fluffy white body.
- Use Codex digital pet style: compact chibi, pixel-art-adjacent, thick dark outline, flat cel shading.
- Use pure magenta `#FF00FF` chroma-key background in source strips.
- No text, labels, shadows, glows, scenery, detached effects, or UI objects.

## Output Structure

- `prompts/`: per-action generation prompts.
- `sources/`: selected imagegen source strips.
- `frames/`: extracted transparent 192x208 frames.
- `gifs/`: preview GIFs.
- `qa/`: contact sheet and QA notes.
- `tools/`: deterministic post-processing helpers for generated sources.
