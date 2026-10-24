module Parun.Codec.MergeComponent where

import qualified Parun.Codec.ComponentCard as ComponentCard
import qualified Parun.Codec.MeldSource as MeldSource
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MergeComponent as MergeComponent

codec :: Codec.Codec MergeComponent.MergeComponent
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfCard" ComponentCard.codec MergeComponent.OfCard (\x -> case x of MergeComponent.OfCard y -> Just y; _ -> Nothing),
      Arm.payload "OfToken" PrintingId.codec MergeComponent.OfToken (\x -> case x of MergeComponent.OfToken y -> Just y; _ -> Nothing),
      Arm.payload "OfMeld" MeldSource.codec MergeComponent.OfMeld (\x -> case x of MergeComponent.OfMeld y -> Just y; _ -> Nothing),
      Arm.payload "OfSpellCopy" PrintingId.codec MergeComponent.OfSpellCopy (\x -> case x of MergeComponent.OfSpellCopy y -> Just y; _ -> Nothing)
    ]

tagOf :: MergeComponent.MergeComponent -> String
tagOf x = case x of
  MergeComponent.OfCard {} -> "OfCard"
  MergeComponent.OfToken {} -> "OfToken"
  MergeComponent.OfMeld {} -> "OfMeld"
  MergeComponent.OfSpellCopy {} -> "OfSpellCopy"
