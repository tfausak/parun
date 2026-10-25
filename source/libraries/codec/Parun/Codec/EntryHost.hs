module Parun.Codec.EntryHost where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EntryHost as EntryHost

-- | CR 303.4i's specified host, or CR 303.4f's chosen one narrowed by a filter.
codec :: Codec.Codec EntryHost.EntryHost
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Specified" SlotName.codec EntryHost.Specified (\x -> case x of EntryHost.Specified y -> Just y; _ -> Nothing),
      Arm.payload "Chosen" (Filter.codec Keyword.codec) EntryHost.Chosen (\x -> case x of EntryHost.Chosen y -> Just y; _ -> Nothing)
    ]

tagOf :: EntryHost.EntryHost -> String
tagOf x = case x of
  EntryHost.Specified {} -> "Specified"
  EntryHost.Chosen {} -> "Chosen"
