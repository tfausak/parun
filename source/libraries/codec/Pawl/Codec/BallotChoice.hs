module Pawl.Codec.BallotChoice where

import qualified Pawl.Codec.ObjectSnapshot as ObjectSnapshot
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.BallotChoice as BallotChoice

-- | Runtime-only, as Pawl.Codec.Looked is.
codec :: Codec.Codec BallotChoice.BallotChoice
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "ForObject" ObjectSnapshot.codec BallotChoice.ForObject (\x -> case x of BallotChoice.ForObject y -> Just y; _ -> Nothing),
      Arm.payload "ForWord" SlotName.codec BallotChoice.ForWord (\x -> case x of BallotChoice.ForWord y -> Just y; _ -> Nothing)
    ]

tagOf :: BallotChoice.BallotChoice -> String
tagOf x = case x of
  BallotChoice.ForObject {} -> "ForObject"
  BallotChoice.ForWord {} -> "ForWord"
