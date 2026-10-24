module Parun.Codec.PayingSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Paying as Paying
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Choices as Choices.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Paying as Paying.Type
import qualified Parun.Types.PaymentDecision as PaymentDecision.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Paying" $ do
  Spec.it s "a decision alone" $
    Common.assertCodec s Paying.codec (Paying.Type.MkPaying PaymentDecision.Type.Declines Choices.Type.none) " {\"decision\":{\"type\":\"Declines\"}} "
  Spec.it s "a decision and the mana that pays it" $
    Common.assertCodec
      s
      Paying.codec
      (Paying.Type.MkPaying PaymentDecision.Type.Pays Choices.Type.none {Choices.Type.manaSources = Seq.fromList [Just (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "island")))]})
      " {\"decision\":{\"type\":\"Pays\"},\"mana\":[\"$island\"]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Paying.codec
