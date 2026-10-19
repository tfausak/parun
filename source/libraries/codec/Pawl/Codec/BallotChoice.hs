module Pawl.Codec.BallotChoice where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.BallotChoice as BallotChoice

-- | Runtime-only, as Pawl.Codec.Looked is. The object's own codec is the
-- caller's (Pawl.Codec.Ballot's ObjectSnapshot).
codec :: (Typeable.Typeable o) => Codec.Codec o -> Codec.Codec (BallotChoice.BallotChoice o)
codec object =
  Arm.tagged
    tagOf
    [ Arm.payload "ForObject" object BallotChoice.ForObject (\x -> case x of BallotChoice.ForObject y -> Just y; _ -> Nothing),
      Arm.payload "ForWord" SlotName.codec BallotChoice.ForWord (\x -> case x of BallotChoice.ForWord y -> Just y; _ -> Nothing),
      Arm.payload "ForPlayer" PlayerId.codec BallotChoice.ForPlayer (\x -> case x of BallotChoice.ForPlayer y -> Just y; _ -> Nothing)
    ]

tagOf :: BallotChoice.BallotChoice o -> String
tagOf x = case x of
  BallotChoice.ForObject {} -> "ForObject"
  BallotChoice.ForWord {} -> "ForWord"
  BallotChoice.ForPlayer {} -> "ForPlayer"
