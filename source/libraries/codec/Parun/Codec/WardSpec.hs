module Parun.Codec.WardSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Ward as Ward
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
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
                PlayerCounterTally.MkPlayerCounterTally
                  { PlayerCounterTally.player = PlayerRef.Relative PlayerRelation.You,
                    PlayerCounterTally.kind = PlayerCounterKind.Experience
                  }
          }
      )
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"perEach\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"kind\":{\"type\":\"Experience\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
