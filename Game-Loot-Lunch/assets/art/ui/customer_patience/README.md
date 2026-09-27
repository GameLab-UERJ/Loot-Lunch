# Customer patience UI assets

Assets designed for the customer patience bar above NPCs.

- Base size: 96x16 px for the frame, 88x8 px for the fill.
- Intended display size: 96x16 px at 1x, or an integer multiple with nearest filtering.
- `patience_frame.svg`: decorative border and inner track.
- `patience_fill_green.svg`: calm state.
- `patience_fill_yellow.svg`: warning state.
- `patience_fill_red.svg`: critical/angry state.
- `customer_irritated.svg`: 16x16 irritated customer indicator.
- PNG equivalents are included for direct Godot import: `patience_frame.png`,
  `patience_fill_green.png`, `patience_fill_yellow.png`,
  `patience_fill_red.png`, and `customer_irritated.png`.

The reusable `res://restaurante/clientes/componentes/customer_patience_bar.tscn`
scene already uses the PNG assets and is instanced above Johnny, Mandy, and
Patolino. Call `set_patience(value)` on the `CustomerPatienceBar` node with a
value from 0 to 100 to update the fill and irritation icon.

Suggested Godot setup: use the frame as `texture_over`, one fill as `texture_progress`, and set `nine_patch_stretch` on the `TextureProgressBar`. Swap the fill texture when the patience thresholds change.
