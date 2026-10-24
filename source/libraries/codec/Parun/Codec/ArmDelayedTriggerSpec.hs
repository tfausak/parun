module Parun.Codec.ArmDelayedTriggerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Onset as Onset
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ArmDelayedTrigger" $ do
  -- CR 603.7a/603.7b: both halves of the envelope at their default, which is
  -- Tidal Wave's shape and by far the common one.
  Spec.it s "MkArmDelayedTrigger, both defaults elided" $
    Common.assertCodec
      s
      (ArmDelayedTrigger.codec Common.text)
      ( ArmDelayedTrigger.MkArmDelayedTrigger
          { ArmDelayedTrigger.name = AbilityName.MkAbilityName (Text.pack "sacrifice it"),
            ArmDelayedTrigger.onset = Onset.Immediately,
            ArmDelayedTrigger.duration = Nothing,
            ArmDelayedTrigger.ability = Nothing
          }
      )
      " {\"name\":\"sacrifice it\"} "
  -- CR 603.7b's stated duration alone -- Full Throttle's "this turn".
  Spec.it s "MkArmDelayedTrigger, duration alone" $
    Common.assertCodec
      s
      (ArmDelayedTrigger.codec Common.text)
      ( ArmDelayedTrigger.MkArmDelayedTrigger
          { ArmDelayedTrigger.name = AbilityName.MkAbilityName (Text.pack "each combat"),
            ArmDelayedTrigger.onset = Onset.Immediately,
            ArmDelayedTrigger.duration = Just Duration.UntilEndOfTurn,
            ArmDelayedTrigger.ability = Nothing
          }
      )
      " {\"name\":\"each combat\",\"duration\":{\"type\":\"UntilEndOfTurn\"}} "
  -- Meandering Towershell's "on your next turn": the onset alone. Under the
  -- positional payload this was the three-element form, and only its LENGTH
  -- separated it from the case above -- an onset and a duration are both
  -- tagged objects.
  Spec.it s "MkArmDelayedTrigger, onset alone" $
    Common.assertCodec
      s
      (ArmDelayedTrigger.codec Common.text)
      ( ArmDelayedTrigger.MkArmDelayedTrigger
          { ArmDelayedTrigger.name = AbilityName.MkAbilityName (Text.pack "return it"),
            ArmDelayedTrigger.onset = Onset.FromNextTurnOf (PlayerRef.Relative PlayerRelation.You),
            ArmDelayedTrigger.duration = Nothing,
            ArmDelayedTrigger.ability = Nothing
          }
      )
      " {\"name\":\"return it\",\"onset\":{\"type\":\"FromNextTurnOf\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}} "
  -- CR 603.7a: the declaration carried by the arm itself, Splinter Twin's quoted
  -- "Exile that token at the beginning of the next end step".
  Spec.it s "MkArmDelayedTrigger, carried ability" $
    Common.assertCodec
      s
      (ArmDelayedTrigger.codec Common.text)
      ( ArmDelayedTrigger.MkArmDelayedTrigger
          { ArmDelayedTrigger.name = AbilityName.MkAbilityName (Text.pack "exile that token"),
            ArmDelayedTrigger.onset = Onset.Immediately,
            ArmDelayedTrigger.duration = Nothing,
            ArmDelayedTrigger.ability = Just (Text.pack "at end step")
          }
      )
      " {\"name\":\"exile that token\",\"ability\":\"at end step\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (ArmDelayedTrigger.codec Common.text)
