module Parun.Codec.ManaCountSpec where

import qualified Parun.Codec.ManaCount as ManaCount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ManaCount as ManaCount
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaCount" $ do
  -- Omnath, Locus of Mana's "each unspent green mana you have".
  Spec.it s "MkManaCount, your own green" $
    Common.assertCodec
      s
      ManaCount.codec
      (ManaCount.MkManaCount (PlayerRef.Relative PlayerRelation.You) (ManaFilter.OfType (ManaType.Colored Color.Green)))
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"filter\":{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Green\"}}}} "
  -- The other end of both fields, so a codec that dropped either payload would
  -- round-trip one of these and not both.
  Spec.it s "MkManaCount, every player's whole pool" $
    Common.assertCodec
      s
      ManaCount.codec
      (ManaCount.MkManaCount (PlayerRef.Relative PlayerRelation.AnyPlayer) ManaFilter.Any)
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"filter\":{\"type\":\"Any\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaCount.codec
