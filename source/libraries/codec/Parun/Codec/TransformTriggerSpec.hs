module Parun.Codec.TransformTriggerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.TransformTrigger as TransformTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TransformTrigger as TransformTrigger

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TransformTrigger" $ do
  Spec.it s "writes no key for the defaults" $
    Common.assertCodec s TransformTrigger.codec TransformTrigger.defaultValue " {} "
  -- Howlpack Piper's "transforms into Wildsong Howler".
  Spec.it s "round-trips the face a Self subject names" $
    Common.assertCodec
      s
      TransformTrigger.codec
      TransformTrigger.defaultValue {TransformTrigger.into = Just (CardName.MkCardName (Text.pack "Wildsong Howler"))}
      " {\"into\":\"Wildsong Howler\"} "
  -- Cult of the Waxing Moon's bystander Filter, and a face beside it so both
  -- keys ride the trip.
  Spec.it s "round-trips every field" $
    Common.assertCodec
      s
      TransformTrigger.codec
      (TransformTrigger.MkTransformTrigger (ActingPermanent.Matching (Filter.Not (Filter.HasSubtype Subtype.Human))) (Just (CardName.MkCardName (Text.pack "Wildsong Howler"))))
      " {\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Human\"}}}},\"into\":\"Wildsong Howler\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TransformTrigger.codec
