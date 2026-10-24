module Parun.Codec.TriggerSource where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TriggerSource as TriggerSource

-- | CR 113.7: an object id under `OfObject`, and a bare tag for the inherent
-- abilities rule 725.2 and rule 702.179d state without a card.
codec :: Codec.Codec TriggerSource.TriggerSource
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfObject" ObjectId.codec TriggerSource.OfObject (\x -> case x of TriggerSource.OfObject y -> Just y; _ -> Nothing),
      Arm.nullary "Sourceless" TriggerSource.Sourceless
    ]

tagOf :: TriggerSource.TriggerSource -> String
tagOf x = case x of
  TriggerSource.OfObject {} -> "OfObject"
  TriggerSource.Sourceless {} -> "Sourceless"
