module Parun.Types.CounterKindFamily where

-- | WHICH KIND a Parun.Types.CounterKind is, with its payload dropped.
-- Parun.Types.KeywordFamily's shape and, in the one place they differ, its
-- opposite: that type has a constructor only for the PAYLOAD-CARRYING keywords,
-- because a nullary keyword's family would say what the keyword already says,
-- while this one has a constructor for every 'Parun.Types.CounterKind'
-- constructor without exception. It is not asked what a card means; it is asked
-- what the whole set of kinds is, and a family missing its nullary kinds would
-- answer that question wrong.
--
-- THAT is the reason it exists. CR 122.1's last sentence makes counters with the
-- same name interchangeable, so Parun.Codec.CounterName must reject the spelling
-- of every kind below, and the set it rejects has to be COMPLETE. Deriving
-- Bounded and Enum here is the only complete enumeration of those constructors
-- the compiler will give: 'Parun.Types.CounterKind' cannot derive either, since
-- CR 122.1b's keyword arm and CR 122.1's named arm carry payloads.
-- Parun.Codec.CounterName.familyOf takes no wildcard, so a new kind cannot reach
-- the reserved set without passing through a constructor here.
--
-- It imports NOTHING, for Parun.Types.KeywordFamily's reason: 'Parun.Types.CounterKind'
-- names Parun.Types.CounterName, so a family type that named the kind back would
-- close a cycle around the type this whole mechanism exists to guard.
--
-- No codec. Nothing puts a family on the wire -- a card names a kind, never a
-- family -- so this is an internal classification, unlike Parun.Types.KeywordFamily,
-- which Parun.Types.Filter asks for by name.
data CounterKindFamily
  = -- | CR 122.1a: Parun.Types.CounterKind.PlusOnePlusOne.
    PlusOnePlusOne
  | -- | CR 122.1a: Parun.Types.CounterKind.MinusOneMinusOne.
    MinusOneMinusOne
  | -- | CR 122.1b: Parun.Types.CounterKind.Keyword, whichever keyword it carries.
    -- The payload is dropped exactly as Parun.Types.KeywordFamily drops toxic's N.
    Keyword
  | -- | CR 122.1e: Parun.Types.CounterKind.Loyalty.
    Loyalty
  | -- | CR 714.3: Parun.Types.CounterKind.Lore.
    Lore
  | -- | CR 122.1g: Parun.Types.CounterKind.Defense.
    Defense
  | -- | CR 702.62a / 702.63a: Parun.Types.CounterKind.Time.
    Time
  | -- | CR 702.32a: Parun.Types.CounterKind.Fade.
    Fade
  | -- | CR 702.24a: Parun.Types.CounterKind.Age.
    Age
  | -- | CR 122.1c: Parun.Types.CounterKind.Shield.
    Shield
  | -- | CR 122.1h: Parun.Types.CounterKind.Finality.
    Finality
  | -- | CR 122.1d: Parun.Types.CounterKind.Stun.
    Stun
  | -- | CR 711.2: Parun.Types.CounterKind.Level.
    Level
  | -- | CR 122.1j: Parun.Types.CounterKind.Hone.
    Hone
  | -- | CR 122.1a: Parun.Types.CounterKind.UnsafePowerToughness, whatever its
    -- numbers.
    PowerToughness
  | -- | CR 122.1: Parun.Types.CounterKind.Named, whichever name it carries. The
    -- open arm, and with PowerToughness one of the two that reserve no
    -- spelling -- the names it carries are what the reserved set is checked
    -- AGAINST.
    Named
  deriving (Bounded, Enum, Eq, Ord, Show)
