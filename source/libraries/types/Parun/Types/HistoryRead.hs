module Parun.Types.HistoryRead where

-- | CR 732.3: which part of the turn's history -- GameState.events, or
-- GameState.activationsThisTurn -- a construct reads, as
-- Parun.Engine.Interchangeable.Mentions classifies the effect DSL and
-- Parun.Engine.Fragmented asks. Loop-local, so no codec.
data HistoryRead
  = -- | Activations begun this turn, GameState.activationsThisTurn (CR 602.2).
    Activations
  | -- | Attackers declared (CR 508.1).
    Attacks
  | -- | Bending actions taken (CR 701.65b, 701.66b, 701.67c, 702.189b).
    Bendings
  | -- | Attackers that became blocked (CR 509.1h).
    Blocks
  | -- | Spells cast (CR 601.2i).
    Casts
  | -- | Coins flipped (CR 705.1).
    CoinFlips
  | -- | Spells convoked (CR 702.51a).
    Convokes
  | -- | Vehicles crewed, and creatures crewing them (CR 702.122a).
    Crews
  | -- | Damage dealt (CR 120.1).
    Damage
  | -- | Permanents that died (CR 700.4).
    Deaths
  | -- | Cards discarded (CR 701.9a).
    Discards
  | -- | Permanents that entered the battlefield (CR 603.6a).
    Entries
  | -- | Life gained (CR 119.3).
    LifeGains
  | -- | Life lost (CR 119.3).
    LifeLosses
  | -- | Loyalty abilities activated (CR 606.3).
    LoyaltyActivations
  | -- | Players who became the monarch (CR 725.1).
    MonarchChanges
  | -- | Cards milled (CR 701.17a).
    Mills
  | -- | Zone changes, and players leaving the game (CR 400.7, 800.4a).
    Moves
  | -- | Planar die rolls (CR 901.9).
    PlanarRolls
  | -- | Abilities that resolved (CR 608.2).
    Resolutions
  | -- | Mounts saddled, and creatures saddling them (CR 702.171a).
    Saddles
  | -- | Steps and phases that began (CR 500.1).
    StepBegins
  | -- | Abilities that triggered (CR 603.2).
    Triggers
  deriving (Bounded, Enum, Eq, Ord, Show)
