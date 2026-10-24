module Parun.Codec.PlaysLandSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.PlaysLand as PlaysLand
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlaysLand as PlaysLand
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlaysLand" $ do
  -- Urianger Augurelt's "whenever you play a land from exile".
  Spec.it s "MkPlaysLand, both keys" $
    Common.assertCodec
      s
      PlaysLand.codec
      ( PlaysLand.MkPlaysLand
          { PlaysLand.player = PlayerRelation.You,
            PlaysLand.from = Zone.Exile,
            PlaysLand.filter = Filter.IsBound (SlotName.MkSlotName (Text.pack "exiled"))
          }
      )
      " {\"player\":{\"type\":\"You\"},\"from\":{\"type\":\"Exile\"},\"filter\":{\"type\":\"IsBound\",\"value\":\"exiled\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlaysLand.codec
