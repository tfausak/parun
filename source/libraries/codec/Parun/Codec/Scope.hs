module Parun.Codec.Scope where

import qualified Parun.Codec.EventShape as EventShape
import qualified Parun.Codec.InZone as InZone
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.BoundReading as BoundReading
import qualified Parun.Types.Scope as Scope

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema. OverBound's reading is its tag, so a slot stays a bare string.
codec :: Codec.Codec Scope.Scope
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "InZone" InZone.codec Scope.InZone (\x -> case x of Scope.InZone y -> Just y; _ -> Nothing),
      Arm.payload "InHistory" EventShape.codec Scope.InHistory (\x -> case x of Scope.InHistory y -> Just y; _ -> Nothing),
      Arm.payload "OverPlayers" PlayerRef.codec Scope.OverPlayers (\x -> case x of Scope.OverPlayers y -> Just y; _ -> Nothing),
      Arm.payload "OverBound" SlotName.codec (Scope.OverBound BoundReading.AsBound) (\x -> case x of Scope.OverBound BoundReading.AsBound y -> Just y; _ -> Nothing),
      Arm.payload "OverBoundBeforeMove" SlotName.codec (Scope.OverBound BoundReading.BeforeMove) (\x -> case x of Scope.OverBound BoundReading.BeforeMove y -> Just y; _ -> Nothing),
      Arm.payload "TopOf" InZone.codec Scope.TopOf (\x -> case x of Scope.TopOf y -> Just y; _ -> Nothing)
    ]

tagOf :: Scope.Scope -> String
tagOf x = case x of
  Scope.InZone {} -> "InZone"
  Scope.InHistory {} -> "InHistory"
  Scope.OverPlayers {} -> "OverPlayers"
  Scope.OverBound BoundReading.AsBound _ -> "OverBound"
  Scope.OverBound BoundReading.BeforeMove _ -> "OverBoundBeforeMove"
  Scope.TopOf {} -> "TopOf"
