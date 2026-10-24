module Parun.Codec.CardsPutIntoZoneSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.CardsPutIntoZone as CardsPutIntoZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardsPutIntoZone as CardsPutIntoZone
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardsPutIntoZone" $ do
  -- Dutiful Knowledge Seeker's payload: "cards" into a library from anywhere.
  Spec.it s "MkCardsPutIntoZone, from anywhere" $
    Common.assertCodec
      s
      CardsPutIntoZone.codec
      ( CardsPutIntoZone.MkCardsPutIntoZone
          { CardsPutIntoZone.filter = Filter.Not Filter.IsToken,
            CardsPutIntoZone.scope = TurnScope.EachTurn,
            CardsPutIntoZone.from = Set.empty,
            CardsPutIntoZone.to = Zone.Library
          }
      )
      " {\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}},\"scope\":{\"type\":\"EachTurn\"},\"to\":{\"type\":\"Library\"}} "
  Spec.it s "MkCardsPutIntoZone, from named zones" $
    Common.assertCodec
      s
      CardsPutIntoZone.codec
      ( CardsPutIntoZone.MkCardsPutIntoZone
          { CardsPutIntoZone.filter = Filter.And [],
            CardsPutIntoZone.scope = TurnScope.ControllersTurn,
            CardsPutIntoZone.from = Set.fromList [Zone.Graveyard],
            CardsPutIntoZone.to = Zone.Hand
          }
      )
      " {\"filter\":{\"type\":\"And\",\"value\":[]},\"from\":[{\"type\":\"Graveyard\"}],\"scope\":{\"type\":\"ControllersTurn\"},\"to\":{\"type\":\"Hand\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CardsPutIntoZone.codec
