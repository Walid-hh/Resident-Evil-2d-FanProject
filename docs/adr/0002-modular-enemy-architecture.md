# Modular Enemy Architecture

The enemy system uses a shared `Enemy` owner with small enemy-owned components and `EnemyConfig` resources instead of growing the old all-in-one enemy script. This keeps the first concrete `MeleeEnemy` direct while giving future enemy types clear extension points for sensing, movement, attacks, stats, and animation names without duplicating full scenes or building a deep subclass tree. Future ranged or special enemies should replace or extend the scene-owned attack component rather than adding ranged-specific branches to `Enemy`.
