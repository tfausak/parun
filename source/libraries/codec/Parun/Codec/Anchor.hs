module Parun.Codec.Anchor where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Anchor as Anchor

-- | Parametric in the filter's codec, which Parun.Codec.Filter supplies.
codec :: (Typeable.Typeable nested, Eq nested) => Codec.Codec nested -> Codec.Codec (Anchor.Anchor nested)
codec filterCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "Bound" SlotName.codec Anchor.Bound (\x -> case x of Anchor.Bound y -> Just y; _ -> Nothing),
      Arm.nullary "Evaluated" Anchor.Evaluated,
      Arm.nullary "Source" Anchor.Source,
      Arm.payload "AnyPermanent" filterCodec Anchor.AnyPermanent (\x -> case x of Anchor.AnyPermanent y -> Just y; _ -> Nothing)
    ]

tagOf :: Anchor.Anchor nested -> String
tagOf x = case x of
  Anchor.Bound {} -> "Bound"
  Anchor.Evaluated {} -> "Evaluated"
  Anchor.Source {} -> "Source"
  Anchor.AnyPermanent {} -> "AnyPermanent"
