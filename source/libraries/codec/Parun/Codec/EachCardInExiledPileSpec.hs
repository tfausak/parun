module Parun.Codec.EachCardInExiledPileSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.EachCardInExiledPile as EachCardInExiledPile
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.EachCardInExiledPile as EachCardInExiledPile
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EachCardInExiledPile" $ do
  Spec.it s "MkEachCardInExiledPile, a pile and a filter" $
    Common.assertCodec
      s
      EachCardInExiledPile.codec
      EachCardInExiledPile.MkEachCardInExiledPile {EachCardInExiledPile.pile = ExiledPile.OwnAbilities, EachCardInExiledPile.filter = Just (Filter.HasCardType CardType.Creature)}
      " {\"pile\":{\"type\":\"OwnAbilities\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- The whole pile, which Parun.Types.Filter has no tautological arm to say.
  Spec.it s "MkEachCardInExiledPile, the whole of a named ability's pile" $
    Common.assertCodec
      s
      EachCardInExiledPile.codec
      EachCardInExiledPile.MkEachCardInExiledPile {EachCardInExiledPile.pile = ExiledPile.OfAbility (AbilityName.MkAbilityName (Text.pack "warden")), EachCardInExiledPile.filter = Nothing}
      " {\"pile\":{\"type\":\"OfAbility\",\"value\":\"warden\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EachCardInExiledPile.codec
