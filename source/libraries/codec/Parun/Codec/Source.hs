module Parun.Codec.Source where

import qualified Parun.Codec.ActivatedAbilitySource as ActivatedAbilitySource
import qualified Parun.Codec.InherentTriggerSource as InherentTriggerSource
import qualified Parun.Codec.MeldSource as MeldSource
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.Codec.ShownComponent as ShownComponent
import qualified Parun.Codec.TriggeredAbilitySource as TriggeredAbilitySource
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Source as Source

codec :: Codec.Codec Source.Source
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "OfCard" PrintingId.codec Source.OfCard (\x -> case x of Source.OfCard y -> Just y; _ -> Nothing),
      Arm.payload "OfMeld" MeldSource.codec Source.OfMeld (\x -> case x of Source.OfMeld y -> Just y; _ -> Nothing),
      Arm.payload "OfMerge" (Common.nonEmpty ShownComponent.codec) Source.OfMerge (\x -> case x of Source.OfMerge y -> Just y; _ -> Nothing),
      Arm.payload "OfToken" PrintingId.codec Source.OfToken (\x -> case x of Source.OfToken y -> Just y; _ -> Nothing),
      Arm.payload "OfAbility" ActivatedAbilitySource.codec Source.OfAbility (\x -> case x of Source.OfAbility y -> Just y; _ -> Nothing),
      Arm.payload "OfTrigger" TriggeredAbilitySource.codec Source.OfTrigger (\x -> case x of Source.OfTrigger y -> Just y; _ -> Nothing),
      Arm.payload "OfEmblem" PrintingId.codec Source.OfEmblem (\x -> case x of Source.OfEmblem y -> Just y; _ -> Nothing),
      Arm.payload "OfSpellCopy" PrintingId.codec Source.OfSpellCopy (\x -> case x of Source.OfSpellCopy y -> Just y; _ -> Nothing),
      Arm.payload "OfCardCopy" PrintingId.codec Source.OfCardCopy (\x -> case x of Source.OfCardCopy y -> Just y; _ -> Nothing),
      Arm.payload "OfInherentTrigger" InherentTriggerSource.codec Source.OfInherentTrigger (\x -> case x of Source.OfInherentTrigger y -> Just y; _ -> Nothing)
    ]

tagOf :: Source.Source -> String
tagOf x = case x of
  Source.OfCard {} -> "OfCard"
  Source.OfMeld {} -> "OfMeld"
  Source.OfMerge {} -> "OfMerge"
  Source.OfToken {} -> "OfToken"
  Source.OfAbility {} -> "OfAbility"
  Source.OfTrigger {} -> "OfTrigger"
  Source.OfEmblem {} -> "OfEmblem"
  Source.OfSpellCopy {} -> "OfSpellCopy"
  Source.OfCardCopy {} -> "OfCardCopy"
  Source.OfInherentTrigger {} -> "OfInherentTrigger"
