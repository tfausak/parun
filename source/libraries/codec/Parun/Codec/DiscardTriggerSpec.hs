module Parun.Codec.DiscardTriggerSpec where

import qualified Parun.Codec.DiscardTrigger as DiscardTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.DiscardSubject as DiscardSubject
import qualified Parun.Types.DiscardTrigger as DiscardTrigger
import qualified Parun.Types.DiscardWay as DiscardWay
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DiscardTrigger" $ do
  -- Bartered Cow: any discard of the card itself, so no defaulted key.
  Spec.it s "the defaults write no key" $
    Common.assertCodec
      s
      DiscardTrigger.codec
      (DiscardTrigger.MkDiscardTrigger DiscardSubject.Self DiscardWay.AnyDiscard Batching.EachOccurrence)
      " {\"subject\":{\"type\":\"Self\"}} "
  -- Prickly Marmoset's "whenever you cycle a card".
  Spec.it s "Cycled writes its key" $
    Common.assertCodec
      s
      DiscardTrigger.codec
      (DiscardTrigger.MkDiscardTrigger (DiscardSubject.Discarder youAnything) DiscardWay.Cycled Batching.EachOccurrence)
      " {\"subject\":{\"type\":\"Discarder\",\"value\":{\"player\":\"You\",\"filter\":{\"type\":\"And\",\"value\":[]}}},\"way\":\"Cycled\"} "
  -- Magmakin Artillerist's "whenever you discard one or more cards".
  Spec.it s "OneOrMore writes its key" $
    Common.assertCodec
      s
      DiscardTrigger.codec
      (DiscardTrigger.MkDiscardTrigger (DiscardSubject.Discarder youAnything) DiscardWay.AnyDiscard Batching.OneOrMore)
      " {\"subject\":{\"type\":\"Discarder\",\"value\":{\"player\":\"You\",\"filter\":{\"type\":\"And\",\"value\":[]}}},\"batching\":\"OneOrMore\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DiscardTrigger.codec
  where
    youAnything = PlayerActsOn.MkPlayerActsOn PlayerRelation.You (Filter.And [])
