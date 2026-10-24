module Parun.Types.ActiveObjectProhibition where

import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prohibition as Prohibition
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 611.2a / 613.11: a stored, resolution-generated prohibition over the
-- permanents it names or a class of them, held in GameState.objectProhibitions and left by
-- Parun.Types.Effect's Prohibit.
--
-- Read through Parun.Engine.RestrictedCreatures.prohibited, one
-- 'Prohibition.Prohibition' at a time: CR 602.5 at Parun.Engine.ActivationProhibition.cantActivate, CR
-- 509.1b at Parun.Engine.CombatRestriction.blockProhibited, CR 502.3 at
-- Parun.Engine.UntapRestriction.gathered -- each unioned beside its printed
-- carrier's rows, so no gate learns which road a prohibition took -- and CR
-- 701.19c at Parun.Engine.Event.resolveDestruction, which turns the destruction
-- it proposes into one that can't be regenerated.
--
-- OUTSIDE the layer system (CR 613.11): each modifies the rules rather than an
-- object's characteristics, so no Parun.Types.Modification arm could carry it
-- and an ability-removing effect leaves it standing.
--
-- A Named row holds the ObjectId the ref named as the ability resolved. CR 400.7
-- is answered by the id itself -- a zone change mints a fresh ObjectId, so a
-- permanent bounced and replayed is one this row never named and the row merely
-- dangles until its expiry sweeps it. Parun.ActivationProhibitionSpec's "a Troll
-- bounced by Unsummon and replayed the same turn is no longer prohibited"
-- proves it. A Matching row is CR 611.2c's class, read against the live board
-- whenever the prohibition is asked.
--
-- `expiry` decides when a Parun.Engine.Expiry sweep drops it (CR 514.2, 611.2a,
-- 611.2b). `timestamp` is stored for CR 613.7, and nothing observes it: two
-- prohibitions cannot conflict.
--
-- No CR 116.2d name: a row
-- a resolution stored has outlived the ability that made it, so
-- Parun.Engine.IgnoredAbility is never asked about one.
--
-- Runtime-only: card data writes Parun.Types.Prohibit, never one of these. It
-- has a codec (Parun.Codec.ActiveObjectProhibition) because a game in progress
-- has to be writable to JSON (#126).
data ActiveObjectProhibition = MkActiveObjectProhibition
  { source :: ObjectId.ObjectId,
    -- | CR 109.5's "you" for a Matching class, baked at resolution:
    -- Parun.Types.ActiveAttackRequirement's reason.
    controller :: PlayerId.PlayerId,
    timestamp :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry,
    what :: Prohibition.Prohibition,
    -- | The permanents the prohibition covers.
    affected :: RestrictedCreatures.RestrictedCreatures ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
