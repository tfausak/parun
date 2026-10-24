module Parun.Codec.PlayerControlSpec where

import qualified Parun.Codec.PlayerControl as PlayerControl
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlDuration as ControlDuration
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.PlayerControl as PlayerControl
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerControl" $ do
  -- CR 723.1's control, which is what Mindslaver installs: no rule 723.7
  -- restriction, so the key is elided.
  Spec.it s "MkPlayerControl, restriction elided" $
    Common.assertCodec
      s
      PlayerControl.codec
      ( PlayerControl.MkPlayerControl
          { PlayerControl.decider = Decider.MkDecider (PlayerId.MkPlayerId 1),
            PlayerControl.duration = ControlDuration.UntilTurnEnds,
            PlayerControl.manaFromLandsOnly = False,
            PlayerControl.timestamp = Timestamp.MkTimestamp 4
          }
      )
      " {\"decider\":1,\"duration\":{\"type\":\"UntilTurnEnds\"},\"timestamp\":4} "
  -- CR 723.2's, with rule 723.7's restriction written: Word of Command's row.
  Spec.it s "MkPlayerControl, restriction written" $
    Common.assertCodec
      s
      PlayerControl.codec
      ( PlayerControl.MkPlayerControl
          { PlayerControl.decider = Decider.MkDecider (PlayerId.MkPlayerId 2),
            PlayerControl.duration = ControlDuration.UntilResolutionEnds,
            PlayerControl.manaFromLandsOnly = True,
            PlayerControl.timestamp = Timestamp.MkTimestamp 9
          }
      )
      " {\"decider\":2,\"duration\":{\"type\":\"UntilResolutionEnds\"},\"manaFromLandsOnly\":true,\"timestamp\":9} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerControl.codec
