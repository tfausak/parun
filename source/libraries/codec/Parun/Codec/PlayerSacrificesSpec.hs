module Parun.Codec.PlayerSacrificesSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.PlayerSacrifices as PlayerSacrifices
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerSacrifices as PlayerSacrifices
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerSacrifices" $ do
  -- CR 701.21: the players the reference names each sacrifice this many
  -- permanents matching the filter -- the filter, not the reference, says which
  -- permanents qualify.
  Spec.it s "MkPlayerSacrifices, all three keys" $
    Common.assertCodec
      s
      PlayerSacrifices.codec
      ( PlayerSacrifices.MkPlayerSacrifices
          { PlayerSacrifices.players = PlayerRef.EachInSlot (SlotName.MkSlotName (Text.pack "player")),
            PlayerSacrifices.filter = Filter.HasCardType CardType.Creature,
            PlayerSacrifices.quantity = Quantity.Literal 1
          }
      )
      " {\"players\":{\"type\":\"EachInSlot\",\"value\":\"player\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"quantity\":{\"type\":\"Literal\",\"value\":1}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerSacrifices.codec
