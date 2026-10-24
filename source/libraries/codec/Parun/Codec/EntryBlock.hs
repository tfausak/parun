module Parun.Codec.EntryBlock where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EntryBlock as EntryBlock

-- | CR 509.4's readings: chosen as it enters, or specified by the effect.
codec :: Codec.Codec EntryBlock.EntryBlock
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Chosen" EntryBlock.Chosen,
      Arm.payload "Specified" SlotName.codec EntryBlock.Specified (\x -> case x of EntryBlock.Specified y -> Just y; _ -> Nothing)
    ]

tagOf :: EntryBlock.EntryBlock -> String
tagOf x = case x of
  EntryBlock.Chosen {} -> "Chosen"
  EntryBlock.Specified {} -> "Specified"
