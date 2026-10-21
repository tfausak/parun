module Pawl.Types.Zone where

data Zone
  = Library
  | Hand
  | Graveyard
  | Battlefield
  | Stack
  | Exile
  | -- | CR 400.1 / 408.1: the command zone -- a game area for objects with an
    -- overarching effect that are not permanents and cannot be destroyed. Shared
    -- across players (not per-player), like Battlefield and Exile. Emblems (CR
    -- 114) are its first resident.
    Command
  | -- | CR 400.1 / 400.2 / 407: the ante zone, shared and public, like exile.
    Ante
  deriving (Bounded, Enum, Eq, Ord, Show)

-- | CR 400.1: "each player has their own library, hand, and graveyard. The other
-- zones are shared by all players." Exhaustive rather than a fallthrough, so a
-- new zone has to say which half of that sentence it is in and @-Werror@ is what
-- asks.
shared :: Zone -> Bool
shared zone = case zone of
  Library -> False
  Hand -> False
  Graveyard -> False
  Battlefield -> True
  Stack -> True
  Exile -> True
  Command -> True
  Ante -> True
