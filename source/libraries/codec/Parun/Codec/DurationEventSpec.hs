module Parun.Codec.DurationEventSpec where

import qualified Parun.Codec.DurationEvent as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DurationEvent" $ do
  -- CR 701.27b (Vesuvan Shapeshifter).
  Spec.it s "SourceTurnedFaceDown" $
    Common.assertCodec
      s
      Codec.codec
      DurationEvent.SourceTurnedFaceDown
      " {\"type\":\"SourceTurnedFaceDown\"} "
  -- CR 601.2i (Soul Sculptor's "a creature spell").
  Spec.it s "SpellCast carries its filter" $
    Common.assertCodec
      s
      Codec.codec
      (DurationEvent.SpellCast (Filter.HasCardType CardType.Creature))
      " {\"type\":\"SpellCast\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- CR 901.11 (Agyrem).
  Spec.it s "Planeswalked" $
    Common.assertCodec
      s
      Codec.codec
      DurationEvent.Planeswalked
      " {\"type\":\"Planeswalked\"} "
  -- CR 607.2a (Furious Rise).
  Spec.it s "SourceExiledCard" $
    Common.assertCodec
      s
      Codec.codec
      DurationEvent.SourceExiledCard
      " {\"type\":\"SourceExiledCard\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Codec.codec
