module Parun.Codec.CounterRestrictionSpec where

import qualified Parun.Codec.CounterRestriction as CounterRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterRestriction as CounterRestriction
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterRestriction" $ do
  -- Solemnity's second sentence (CR 101.2 / CR 122.6), which names no kind, so
  -- the key is absent -- the wire form data/cards/solemnity.json writes.
  Spec.it s "MkCounterRestriction, no kind named" $
    Common.assertCodec
      s
      CounterRestriction.codec
      ( CounterRestriction.MkCounterRestriction
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          Nothing
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Melira, Sylvok Outcast's second sentence, which names one.
  Spec.it s "MkCounterRestriction, a named kind" $
    Common.assertCodec
      s
      CounterRestriction.codec
      ( CounterRestriction.MkCounterRestriction
          (Affected.Matching (Filter.HeldBy Holder.Controller PlayerRelation.You))
          (Just CounterKind.MinusOneMinusOne)
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}},\"kind\":{\"type\":\"MinusOneMinusOne\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterRestriction.codec
