module Pawl.Codec.EachCardInExiledPileSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.EachCardInExiledPile as EachCardInExiledPile
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AbilityName as AbilityName
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.EachCardInExiledPile as EachCardInExiledPile
import qualified Pawl.Types.ExiledPile as ExiledPile
import qualified Pawl.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.EachCardInExiledPile" $ do
  Spec.it s "MkEachCardInExiledPile, a pile and a filter" $
    Common.assertCodec
      s
      EachCardInExiledPile.codec
      EachCardInExiledPile.MkEachCardInExiledPile {EachCardInExiledPile.pile = ExiledPile.OwnAbilities, EachCardInExiledPile.filter = Just (Filter.HasCardType CardType.Creature)}
      " {\"pile\":{\"type\":\"OwnAbilities\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- The whole pile, which Pawl.Types.Filter has no tautological arm to say.
  Spec.it s "MkEachCardInExiledPile, the whole of a named ability's pile" $
    Common.assertCodec
      s
      EachCardInExiledPile.codec
      EachCardInExiledPile.MkEachCardInExiledPile {EachCardInExiledPile.pile = ExiledPile.OfAbility (AbilityName.MkAbilityName (Text.pack "warden")), EachCardInExiledPile.filter = Nothing}
      " {\"pile\":{\"type\":\"OfAbility\",\"value\":\"warden\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EachCardInExiledPile.codec
