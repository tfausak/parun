module Pawl.Codec.RevealWindow where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.RevealWindow as RevealWindow

codec :: Codec.Codec RevealWindow.RevealWindow
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "WhileOnStack" ObjectId.codec RevealWindow.WhileOnStack (\x -> case x of RevealWindow.WhileOnStack y -> Just y; _ -> Nothing),
      Arm.nullary "UntilPriority" RevealWindow.UntilPriority,
      Arm.nullary "UntilFirstTurn" RevealWindow.UntilFirstTurn,
      Arm.payload "DuringUpkeep" Common.natural RevealWindow.DuringUpkeep (\x -> case x of RevealWindow.DuringUpkeep y -> Just y; _ -> Nothing)
    ]

tagOf :: RevealWindow.RevealWindow -> String
tagOf x = case x of
  RevealWindow.WhileOnStack {} -> "WhileOnStack"
  RevealWindow.UntilPriority {} -> "UntilPriority"
  RevealWindow.UntilFirstTurn {} -> "UntilFirstTurn"
  RevealWindow.DuringUpkeep {} -> "DuringUpkeep"
