module Parun.Codec.WardSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Ward as Ward
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordCount as KeywordCount
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerCounterTally as PlayerCounterTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Ward as Ward

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Ward.Ward Keyword.Keyword)
codec = Ward.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Ward" $ do
  -- CR 702.21a: a printed cost, so perEach is Nothing and stays off the wire.
  Spec.it s "MkWard" $
    Common.assertCodec
      s
      codec
      ( Ward.MkWard
          { Ward.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 2]), Cost.components = []},
            Ward.perEach = Nothing
          }
      )
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":2}]}} "
  -- CR 702.21b: Minthara, Merciless Soul's ward {X}, one {1} per experience
  -- counter.
  Spec.it s "MkWard with CR 702.21b's X" $
    Common.assertCodec
      s
      codec
      ( Ward.MkWard
          { Ward.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 1]), Cost.components = []},
            Ward.perEach =
              Just
                ( KeywordCount.PlayerCounters
                    PlayerCounterTally.MkPlayerCounterTally
                      { PlayerCounterTally.player = PlayerRef.Relative PlayerRelation.You,
                        PlayerCounterTally.kind = PlayerCounterKind.Experience
                      }
                )
          }
      )
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"perEach\":{\"type\":\"PlayerCounters\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":\"You\"},\"kind\":\"Experience\"}}} "
  -- CR 702.21b: Phyrexian Fleshgorger's "pay life equal to this creature's
  -- power", one life per point of power.
  Spec.it s "MkWard with a power-sized life payment" $
    Common.assertCodec
      s
      codec
      ( Ward.MkWard
          { Ward.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost []), Cost.components = [CostComponent.PayLife (CostAmount.Fixed 1)]},
            Ward.perEach = Just KeywordCount.Power
          }
      )
      " {\"cost\":{\"mana\":[],\"components\":[{\"type\":\"PayLife\",\"value\":{\"type\":\"Fixed\",\"value\":1}}]},\"perEach\":{\"type\":\"Power\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
