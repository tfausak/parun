module Parun.Codec.HowMany where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.HowMany as HowMany

-- | @UpTo@'s ceiling is an optional value, so "any number" writes the bare tag.
codec :: Codec.Codec HowMany.HowMany
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Exactly" Quantity.codec HowMany.Exactly (\x -> case x of HowMany.Exactly y -> Just y; _ -> Nothing),
      Arm.optionalPayload "UpTo" Quantity.codec HowMany.UpTo (\x -> case x of HowMany.UpTo y -> Just y; _ -> Nothing)
    ]

tagOf :: HowMany.HowMany -> String
tagOf x = case x of
  HowMany.Exactly {} -> "Exactly"
  HowMany.UpTo {} -> "UpTo"
