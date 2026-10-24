module Pawl.Codec.EntryController where

import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.EntryController as EntryController

-- | CR 110.2a's readings: the player the effect instructs, or each owner.
codec :: Codec.Codec EntryController.EntryController
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Instructed" PlayerRef.codec EntryController.Instructed (\x -> case x of EntryController.Instructed y -> Just y; _ -> Nothing),
      Arm.nullary "Owner" EntryController.Owner
    ]

tagOf :: EntryController.EntryController -> String
tagOf x = case x of
  EntryController.Instructed {} -> "Instructed"
  EntryController.Owner {} -> "Owner"
