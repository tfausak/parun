module Parun.Codec.PermissionCostSpec where

import qualified Parun.Codec.PermissionCost as PermissionCost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.PermissionCost as PermissionCost

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermissionCost" $ do
  -- Rule 701.65a's airbend: "by paying {2} rather than paying its mana cost".
  Spec.it s "InsteadOfManaCost" $
    Common.assertCodec
      s
      PermissionCost.codec
      (PermissionCost.InsteadOfManaCost (ManaCost.MkManaCost [ManaSymbol.Generic 2]))
      " {\"type\":\"InsteadOfManaCost\",\"value\":[{\"type\":\"Generic\",\"value\":2}]} "
  -- Hama, the Bloodbender.
  Spec.it s "WaterbendManaValue" $
    Common.assertCodec
      s
      PermissionCost.codec
      PermissionCost.WaterbendManaValue
      " {\"type\":\"WaterbendManaValue\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermissionCost.codec
