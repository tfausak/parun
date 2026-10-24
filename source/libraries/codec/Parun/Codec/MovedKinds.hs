{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MovedKinds where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.EntryRiders as EntryRiders
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MovedKinds as MovedKinds

-- | The tag that picks an arm is written by Parun.Codec.MoveCounters' `kinds`
-- field, which defaults to a chosen kind and a count of one -- what "move a
-- counter" means -- so data/cards/agents-toolkit.json writes no key at all.
--
-- The named arm's payload is Parun.Codec.EntryRiders' `counter` and not a second
-- codec for the same pair: Parun.JsonSchema.Define keys a definition by the
-- type's Typeable name, so two codecs for one type quietly share one name and
-- the loser's wire spelling stops matching the schema the corpus is checked
-- against.
--
-- The whole-tally and any-number-of-a-kind arms share that same CounterKind
-- codec: a kind is a kind however the sentence settles its count, and a second
-- codec for the type would collide with this one in the schema's definitions.
codec :: Codec.Codec MovedKinds.MovedKinds
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Every" MovedKinds.Every,
      Arm.payload "Named" EntryRiders.counter (uncurry MovedKinds.Named) (\x -> case x of MovedKinds.Named kind quantity -> Just (kind, quantity); _ -> Nothing),
      Arm.payload "EveryOfKind" (CounterKind.codec Keyword.codec) MovedKinds.EveryOfKind (\x -> case x of MovedKinds.EveryOfKind kind -> Just kind; _ -> Nothing),
      Arm.payload "Chosen" Quantity.codec MovedKinds.Chosen (\x -> case x of MovedKinds.Chosen quantity -> Just quantity; _ -> Nothing),
      Arm.nullary "AnyNumber" MovedKinds.AnyNumber,
      Arm.nullary "AtLeastOne" MovedKinds.AtLeastOne,
      Arm.payload "AnyNumberOfKind" (CounterKind.codec Keyword.codec) MovedKinds.AnyNumberOfKind (\x -> case x of MovedKinds.AnyNumberOfKind kind -> Just kind; _ -> Nothing),
      Arm.nullary "EachAbsentKind" MovedKinds.EachAbsentKind,
      Arm.nullary "UpToOneChosen" MovedKinds.UpToOneChosen
    ]

tagOf :: MovedKinds.MovedKinds -> String
tagOf x = case x of
  MovedKinds.Every {} -> "Every"
  MovedKinds.Named {} -> "Named"
  MovedKinds.EveryOfKind {} -> "EveryOfKind"
  MovedKinds.Chosen {} -> "Chosen"
  MovedKinds.AnyNumber {} -> "AnyNumber"
  MovedKinds.AtLeastOne {} -> "AtLeastOne"
  MovedKinds.AnyNumberOfKind {} -> "AnyNumberOfKind"
  MovedKinds.EachAbsentKind {} -> "EachAbsentKind"
  MovedKinds.UpToOneChosen {} -> "UpToOneChosen"
