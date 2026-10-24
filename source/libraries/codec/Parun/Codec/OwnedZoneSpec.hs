module Parun.Codec.OwnedZoneSpec where

import qualified Parun.Codec.OwnedZone as OwnedZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OwnedZone" $ do
  -- God-Eternal Oketra's "exile", the owner defaulted.
  Spec.it s "MkOwnedZone, any owner" $
    Common.assertCodec
      s
      OwnedZone.codec
      (OwnedZone.MkOwnedZone {OwnedZone.zone = Zone.Exile, OwnedZone.owner = PlayerRelation.AnyPlayer})
      " {\"zone\":{\"type\":\"Exile\"}} "
  -- Enigma Sphinx's "your graveyard".
  Spec.it s "MkOwnedZone, yours" $
    Common.assertCodec
      s
      OwnedZone.codec
      (OwnedZone.MkOwnedZone {OwnedZone.zone = Zone.Graveyard, OwnedZone.owner = PlayerRelation.You})
      " {\"owner\":{\"type\":\"You\"},\"zone\":{\"type\":\"Graveyard\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s OwnedZone.codec
