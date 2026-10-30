module Parun.Types.CastingPermission where

import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.ManaCost as ManaCost

-- | CR 113.6 / 601.3: a static permission to cast a card from a zone or under a
-- condition it normally could not. CastFromLibraryWhileSearching is Panglacial
-- Wurm's "while you're searching your library, you may cast this from your
-- library". The general "cast from the top of your library" (Garruk's Horde) is
-- a player permission rather than an object one and lives on
-- Parun.Types.PlayerEffect.CastFrom instead. Parun.Engine.Cast reads this type,
-- as a membership test per arm, and Parun.Engine.Projection folds the grants
-- into ProjectedCharacteristics.castingPermissions. Three producers: Face.castingPermissions (printed),
-- Modification.GainCastingPermission (a layer-6 grant) and
-- Parun.Engine.Keyword.castingPermissionsOf (what rule 702 gives for a keyword).
--
-- OBJECT-scoped throughout: every arm is a permission a CARD grants about
-- ITSELF. The player-scoped sibling -- a continuous effect that lets its player
-- cast any card from their graveyard (Yawgmoth's Will) -- is a different
-- carrier, and it is Parun.Types.PlayerEffect.CastFrom.
-- Parun.Engine.Cast.permitsCastFromGraveyard reads the two beside each other.
data CastingPermission
  = CastFromLibraryWhileSearching
  | -- | CR 601.3: cast this card from its owner's graveyard, using only the
    -- alternative costs a keyword of the named family offers (Tenacious
    -- Underdog's "using its blitz ability"); Nothing where the keyword granting
    -- the permission prices the cast itself, as CR 702.34a's, 702.81a's,
    -- 702.127a's, 702.133a's, 702.138a's and 702.187b's do.
    --
    -- Those keywords' permissions come from Parun.Engine.Keyword.castingPermissionsOf,
    -- a constructor here rather than a keyword read at the gate, so
    -- Parun.Engine.Cast keeps asking "may this be cast from the graveyard?" and
    -- never "does this have flashback?".
    CastFromGraveyard (Maybe KeywordFamily.KeywordFamily)
  | -- | CR 601.3c / 601.3d: cast this card as though it had flash (CR 702.8a)
    -- while the condition holds, paying the additional cost (CR 601.2f) only
    -- when the permission is used.
    CastAsThoughItHadFlash (Maybe Condition.Condition) (Maybe ManaCost.ManaCost)
  deriving (Eq, Ord, Show)
