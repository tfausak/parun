module Parun.Codec.EntersTriggerSpec where

import qualified Parun.Codec.EntersTrigger as EntersTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.EntersTrigger as EntersTrigger
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntersTrigger" $ do
  Spec.it s "writes no key for the defaults" $
    Common.assertCodec s EntersTrigger.codec EntersTrigger.defaultValue " {} "
  Spec.it s "round-trips a Matching permanent" $
    Common.assertCodec
      s
      EntersTrigger.codec
      (EntersTrigger.matching (Filter.HasCardType CardType.Land))
      " {\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}} "
  Spec.it s "round-trips every field" $
    Common.assertCodec
      s
      EntersTrigger.codec
      (EntersTrigger.MkEntersTrigger (ActingPermanent.Matching (Filter.HasCardType CardType.Creature)) Batching.OneOrMore)
      " {\"batching\":{\"type\":\"OneOrMore\"},\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s EntersTrigger.codec
