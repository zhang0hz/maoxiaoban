# Miu Phase 1 Visual QA Notes

## Passed

Generated and previewed all 11 Phase 1 extension actions:

- `loaf`
- `sleep`
- `wake`
- `stretch`
- `peek`
- `edge-walk`
- `groom`
- `purr`
- `sit-watch`
- `celebrate`
- `comfort`

All actions were extracted into transparent `192x208` frames with component-based extraction. No empty frames were detected.

## Notes

- `sit-watch` is usable but has stronger blue-gray coloration than the other rows. It should be considered a future visual repair candidate if strict identity consistency is required.
- Some source strips had slightly non-exact magenta backgrounds. Post-processing removed them cleanly.
- These actions are extension assets. The current Codex pet runtime atlas remains fixed at 8x9, so behavior-layer integration should consume these assets directly or remap selected actions into existing runtime slots.

## Preview Files

- Contact sheet: `qa/phase1-contact-sheet.png`
- Review JSON: `qa/phase1-review.json`
- GIF previews: `gifs/`
