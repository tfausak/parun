{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ManaAddition where

import qualified Parun.Codec.ManaProduction as ManaProduction
import qualified Parun.Codec.ManaRestriction as ManaRestriction
import qualified Parun.Codec.ManaRetention as ManaRetention
import qualified Parun.Codec.ManaRider as ManaRider
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.WhenSpent as WhenSpent
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ManaAddition as ManaAddition
import qualified Parun.Types.ManaRetention as ManaRetention
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

-- | CR 109.5's "you", the recipient a card that names nobody means.
defaultPlayer :: PlayerRef.PlayerRef
defaultPlayer = PlayerRef.Relative PlayerRelation.You

-- | A bare object keyed by the record's field names, Parun.Codec.PlayerCounters'
-- shape.
--
-- @player@ is DEFAULTED rather than required, and the default is the rule's own
-- reading: CR 106.3 has a mana effect instruct "a player" to add, and a card that
-- names nobody means CR 109.5's "you". Nearly every printing in the pool leaves
-- it out, so requiring it would make every card restate a rule.
--
-- @retention@ is DEFAULTED the same way and for the same reason: CR 106.4's
-- default is that the player loses the mana as the step ends, so a card that
-- says nothing means Ordinary. Shizuko, Caller of Autumn's "until end of turn,
-- they don't lose this mana" and Avatar Roku, Firebender's "until end of combat"
-- are the printings in the pool that write the key; CR 702.189a's firebending
-- means the same thing and writes no key at all, being minted from the keyword.
--
-- @count@ is DEFAULTED to @Literal 1@: an instruction adds one mana unless the
-- card says otherwise, which Stadium Vendors' "two mana of any one color they
-- choose" and Loot, the Pathfinder's "three mana of any one color" do. A whole
-- Quantity and not a number, so Cabal Coffers' "for each Swamp you control" has
-- a spelling too.
--
-- @restriction@ and @rider@ are CR 106.6's two shapes, each DEFAULTED to
-- Nothing: almost every printing says neither, and the two are independent --
-- Mishra's Workshop writes only the first key, Boseiju, Who Shelters All only
-- the second, Delighted Halfling both. @whenSpent@, the third shape, defaults the
-- same way; Pyromancer's Goggles writes it.
codec :: Codec.Codec ManaAddition.ManaAddition
codec = Fields.object $ do
  player <- Fields.defaulted "player" defaultPlayer PlayerRef.codec ManaAddition.player
  production <- Fields.required "production" ManaProduction.codec ManaAddition.production
  count <- Fields.defaulted "count" (Quantity.Literal 1) Quantity.codec ManaAddition.count
  retention <- Fields.defaulted "retention" ManaRetention.Ordinary ManaRetention.codec ManaAddition.retention
  restriction <- Fields.defaulted "restriction" Nothing (Common.maybe ManaRestriction.codec) ManaAddition.restriction
  rider <- Fields.defaulted "rider" Nothing (Common.maybe ManaRider.codec) ManaAddition.rider
  whenSpent <- Fields.defaulted "whenSpent" Nothing (Common.maybe WhenSpent.codec) ManaAddition.whenSpent
  pure
    ManaAddition.MkManaAddition
      { ManaAddition.player = player,
        ManaAddition.production = production,
        ManaAddition.count = count,
        ManaAddition.retention = retention,
        ManaAddition.restriction = restriction,
        ManaAddition.rider = rider,
        ManaAddition.whenSpent = whenSpent
      }
