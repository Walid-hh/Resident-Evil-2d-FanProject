# 0001. Replace Spatial Inventory With Fixed-Slot Quantities

## Status

Accepted

## Context

The project previously used a Resident Evil-style spatial inventory with grid cells, item footprints, rotation, held items, swaps, and a pause-menu grid UI. The current playable scope only needs predefined item quantities for weapon ammunition and future consumable/key-item state. The spatial model added interaction and data complexity that was not needed for current gameplay.

## Decision

Replace the spatial inventory with a Fixed-Slot Inventory owned by `PlayerInventory`. Each authored slot points to one non-spatial item definition and stores a runtime quantity. The Pause Menu remains a pause overlay only and does not display or manipulate inventory contents.

## Consequences

- Ammo-backed weapons and the HUD keep using item quantity helpers.
- Item movement, rotation, swaps, grid cells, and discard handling are removed.
- Future pickup, item-use, inventory display, and save/load work must build on fixed slots instead of spatial placement.
- Reintroducing spatial inventory later would be a separate design reversal rather than an extension of current behavior.
