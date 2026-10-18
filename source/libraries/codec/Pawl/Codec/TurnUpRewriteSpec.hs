module Pawl.Codec.TurnUpRewriteSpec where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.TurnUpRewrite as TurnUpRewrite
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AsCopy as AsCopy
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.CopyDomain as CopyDomain
import qualified Pawl.Types.CopyRecipient as CopyRecipient
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.DurationEvent as DurationEvent
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.TurnUpRewrite as TurnUpRewrite
import qualified Pawl.Types.WithCounters as WithCounters
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TurnUpRewrite" $ do
  Spec.it s "WithCounters (megamorph, CR 702.37b)" $
    Common.assertCodec
      s
      (TurnUpRewrite.codec Common.text Common.text)
      (TurnUpRewrite.WithCounters (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 1)))
      " {\"type\":\"WithCounters\",\"value\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":1}}]} "
  Spec.it s "MayAttachTo (Gift of Doom, CR 303.4k)" $
    Common.assertCodec
      s
      (TurnUpRewrite.codec Common.text Common.text)
      (TurnUpRewrite.MayAttachTo (Filter.HasCardType CardType.Creature))
      " {\"type\":\"MayAttachTo\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Vesuvan Shapeshifter's "as this is turned face up ... until this creature
  -- is turned face down, it becomes a copy", the AsCopy payload EntryRewrite's
  -- arm carries.
  Spec.it s "AsCopy (Vesuvan Shapeshifter, CR 707.4)" $
    Common.assertCodec
      s
      (TurnUpRewrite.codec Common.text Common.text)
      (TurnUpRewrite.AsCopy (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty (CopyDomain.InZone Zone.Battlefield) (Just (Duration.UntilEvent DurationEvent.SourceTurnedFaceDown)) CopyRecipient.ThisObject True))
      " {\"type\":\"AsCopy\",\"value\":{\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"duration\":{\"type\":\"UntilEvent\",\"value\":{\"type\":\"SourceTurnedFaceDown\"}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s (TurnUpRewrite.codec Common.text Common.text)
