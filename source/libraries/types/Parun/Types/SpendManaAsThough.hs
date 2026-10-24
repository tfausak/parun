module Parun.Types.SpendManaAsThough where

import qualified Data.Set as Set
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaType as ManaType

-- | The payload of Parun.Types.PlayerEffect's SpendManaAsThough arm: one clause
-- of CR 609.4b, "spend [this] mana as though it were mana of [these types]".
-- Parun.Types.GrantedAbility's SelfSpendManaAsThough carries one scoped to
-- casting its own object (Tome of the Infinite).
--
-- CR 609.4b's own limit is what this type is shaped by -- "this affects only how
-- the player may pay a cost. It doesn't change that cost, and it doesn't change
-- what mana was actually spent to pay that cost." So this never reaches a
-- Parun.Types.ManaCost and never reaches a Parun.Types.ManaUnit: Parun.Engine.Mana
-- applies it to the SUPPLY one unit offers, leaving the pool and the cost alone.
--
-- The SUPPLY side is what separates this from Parun.Types.ManaSpending, which is
-- CR 118.14's per-cost widening and is applied to a cost's DEMANDS. The two are
-- not interchangeable: a demand-side transform cannot depend on which unit is
-- being spent, and Celestial Dawn's sentence says different things about
-- different manas of the same pool.
data SpendManaAsThough = MkSpendManaAsThough
  { -- | Which of this player's mana the clause speaks about. Celestial Dawn's
    -- two clauses are exactly a type and its complement -- white, and "other
    -- mana".
    which :: ManaFilter.ManaFilter,
    -- | CR 106.1b's types that mana may be spent as. "Mana of any color" is the
    -- five of CR 106.1a and not the six, so a mana widened by it still cannot
    -- pay CR 107.4c's {C}; a set says which without the engine having to know
    -- the difference.
    --
    -- TYPES only, never Parun.Types.ProductionTag: {S} demands mana produced by a
    -- snow source, which is a fact about where the mana came from rather than
    -- about what it is, and CR 609.4b speaks only of types and colors. So the
    -- tags ride through untouched (Parun.Engine.Mana.rewriteSupply).
    asThough :: Set.Set ManaType.ManaType,
    -- | The card's own word: Celestial Dawn prints "You may spend other mana
    -- ONLY as though it were colorless mana", and that clause takes the mana's
    -- own type away as well as granting a new one. A clause without the word --
    -- Celestial Dawn's first, "you may spend white mana as though it were mana
    -- of any color" -- only adds, so the mana can still be spent as what it is.
    --
    -- A Bool and not two constructors, because it is one bit of one sentence and
    -- both halves are otherwise the same clause. What it does NOT mean is a
    -- prohibition in CR 101.2's sense: an exclusive clause still names types the
    -- mana may be spent as, so it replaces rather than forbids
    -- (Parun.Engine.Mana.spendableAs).
    --
    -- Sunglasses of Urza's clause names red and not white, so it is the card that
    -- tells adding from replacing: Parun.ManaSymbolSpec's "Sunglasses of Urza"
    -- cases prove white mana still pays {W} under it.
    only :: Bool
  }
  deriving (Eq, Ord, Show)
