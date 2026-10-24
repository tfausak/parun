module Parun.Codec.TurnWindow where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.TurnWindow as TurnWindow

-- | CR 603.7a: the STORED onset, which like Expiry beside it never appears in card
-- JSON -- a card carries an Onset and Parun.Engine.Event.armOnset turns it into
-- this. The one thing that serialises a TurnWindow is a DelayedTrigger.
codec :: Codec.Codec TurnWindow.TurnWindow
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AnyTurn" TurnWindow.AnyTurn,
      Arm.payload "NextTurnOf" PlayerId.codec TurnWindow.NextTurnOf (\x -> case x of TurnWindow.NextTurnOf y -> Just y; _ -> Nothing),
      Arm.payload "OnTurn" Common.natural TurnWindow.OnTurn (\x -> case x of TurnWindow.OnTurn y -> Just y; _ -> Nothing),
      Arm.payload "OnExtraTurn" Timestamp.codec TurnWindow.OnExtraTurn (\x -> case x of TurnWindow.OnExtraTurn y -> Just y; _ -> Nothing)
    ]

tagOf :: TurnWindow.TurnWindow -> String
tagOf x = case x of
  TurnWindow.AnyTurn {} -> "AnyTurn"
  TurnWindow.NextTurnOf {} -> "NextTurnOf"
  TurnWindow.OnTurn {} -> "OnTurn"
  TurnWindow.OnExtraTurn {} -> "OnExtraTurn"
