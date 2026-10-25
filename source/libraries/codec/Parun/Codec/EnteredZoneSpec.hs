module Parun.Codec.EnteredZoneSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.EnteredZone as EnteredZone
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EnteredZone as EnteredZone
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EnteredZone" $ do
  Spec.it s "MkEnteredZone, from anywhere" $
    Common.assertCodec
      s
      EnteredZone.codec
      (EnteredZone.MkEnteredZone {EnteredZone.to = Zone.Battlefield, EnteredZone.from = Set.empty})
      " {\"to\":{\"type\":\"Battlefield\"}} "
  -- Asymmetric on purpose, Parun.Codec.MovedBetweenSpec's reason: both keys
  -- carry a Zone.
  Spec.it s "MkEnteredZone, a named origin" $
    Common.assertCodec
      s
      EnteredZone.codec
      (EnteredZone.MkEnteredZone {EnteredZone.to = Zone.Graveyard, EnteredZone.from = Set.singleton Zone.Battlefield})
      " {\"from\":[{\"type\":\"Battlefield\"}],\"to\":{\"type\":\"Graveyard\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EnteredZone.codec
