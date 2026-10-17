module Pawl.Codec.DurationEventSpec where

import qualified Pawl.Codec.DurationEvent as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.DurationEvent as DurationEvent
import qualified Pawl.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.DurationEvent" $ do
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
  Spec.it s "has a schema" $ Common.assertHasSchema s Codec.codec
