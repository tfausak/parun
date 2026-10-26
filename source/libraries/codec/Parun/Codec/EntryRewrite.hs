module Parun.Codec.EntryRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AsCopy as AsCopy
import qualified Parun.Codec.ChosenQuality as ChosenQuality
import qualified Parun.Codec.EntersWith as EntersWith
import qualified Parun.Codec.EntryFlip as EntryFlip
import qualified Parun.Codec.EntryOption as EntryOption
import qualified Parun.Codec.EntryPrice as EntryPrice
import qualified Parun.Codec.ExileFromGraveyard as ExileFromGraveyard
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SacrificeAnyNumber as SacrificeAnyNumber
import qualified Parun.Codec.SacrificeToEnter as SacrificeToEnter
import qualified Parun.Codec.WithCounters as WithCounters
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.EntryRewrite as EntryRewrite

-- | @AsCopy@ takes a required object payload: the eligible filter has no default
-- (#1512), so the bare tag a plain Clone used to write is no longer a legal
-- rewrite. CR 707.9's exceptions stay optional INSIDE that object.
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Codec.DamageR gives: @RunEffects@ carries a card's effects and neither
-- module may name the other.
codec ::
  (Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) =>
  Codec.Codec ability ->
  Codec.Codec effect ->
  Codec.Codec (EntryRewrite.EntryRewrite ability effect)
codec abilityCodec effectCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "AsCopy" (AsCopy.codec abilityCodec effectCodec) EntryRewrite.AsCopy (\x -> case x of EntryRewrite.AsCopy y -> Just y; _ -> Nothing),
      Arm.payload "ChoiceOf" (Common.list EntryOption.codec) EntryRewrite.ChoiceOf (\x -> case x of EntryRewrite.ChoiceOf y -> Just y; _ -> Nothing),
      Arm.payload "ChoiceByCoinFlip" EntryFlip.codec EntryRewrite.ChoiceByCoinFlip (\x -> case x of EntryRewrite.ChoiceByCoinFlip y -> Just y; _ -> Nothing),
      Arm.payload "WithCounters" WithCounters.codec EntryRewrite.WithCounters (\x -> case x of EntryRewrite.WithCounters y -> Just y; _ -> Nothing),
      Arm.payload "ChooseQuality" ChosenQuality.codec EntryRewrite.ChooseQuality (\x -> case x of EntryRewrite.ChooseQuality y -> Just y; _ -> Nothing),
      Arm.payload "ChoosePlayer" PlayerRelation.codec EntryRewrite.ChoosePlayer (\x -> case x of EntryRewrite.ChoosePlayer y -> Just y; _ -> Nothing),
      Arm.payload "ChooseCardNames" (Filter.codec Keyword.codec) EntryRewrite.ChooseCardNames (\x -> case x of EntryRewrite.ChooseCardNames y -> Just y; _ -> Nothing),
      Arm.payload "ChooseCardName" (Filter.codec Keyword.codec) EntryRewrite.ChooseCardName (\x -> case x of EntryRewrite.ChooseCardName y -> Just y; _ -> Nothing),
      Arm.payload "EntersWith" (EntersWith.codec abilityCodec) EntryRewrite.EntersWith (\x -> case x of EntryRewrite.EntersWith y -> Just y; _ -> Nothing),
      Arm.nullary "UnderSourceControl" EntryRewrite.UnderSourceControl,
      Arm.nullary "ReadAhead" EntryRewrite.ReadAhead,
      Arm.nullary "Riot" EntryRewrite.Riot,
      Arm.nullary "Unleash" EntryRewrite.Unleash,
      Arm.nullary "Sunburst" EntryRewrite.Sunburst,
      Arm.nullary "ModularSunburst" EntryRewrite.ModularSunburst,
      -- Optional for Parun.Codec.Keyword's reason: rule 702.54b's X is the absent
      -- "value" key, and the payload is that keyword's carried through.
      Arm.optionalPayload "Bloodthirst" Common.natural EntryRewrite.Bloodthirst (\x -> case x of EntryRewrite.Bloodthirst y -> Just y; _ -> Nothing),
      Arm.payload "Tribute" Common.natural EntryRewrite.Tribute (\x -> case x of EntryRewrite.Tribute y -> Just y; _ -> Nothing),
      Arm.payload "Amplify" Common.natural EntryRewrite.Amplify (\x -> case x of EntryRewrite.Amplify y -> Just y; _ -> Nothing),
      Arm.payload "Compleated" Common.natural EntryRewrite.Compleated (\x -> case x of EntryRewrite.Compleated y -> Just y; _ -> Nothing),
      Arm.nullary "Tapped" EntryRewrite.Tapped,
      Arm.nullary "EntersTransformed" EntryRewrite.EntersTransformed,
      Arm.payload "OrTapped" EntryPrice.codec EntryRewrite.OrTapped (\x -> case x of EntryRewrite.OrTapped y -> Just y; _ -> Nothing),
      Arm.payload "SacrificeAnyNumber" SacrificeAnyNumber.codec EntryRewrite.SacrificeAnyNumber (\x -> case x of EntryRewrite.SacrificeAnyNumber y -> Just y; _ -> Nothing),
      Arm.payload "SacrificeToEnter" SacrificeToEnter.codec EntryRewrite.SacrificeToEnter (\x -> case x of EntryRewrite.SacrificeToEnter y -> Just y; _ -> Nothing),
      Arm.payload "ExileFromGraveyard" ExileFromGraveyard.codec EntryRewrite.ExileFromGraveyard (\x -> case x of EntryRewrite.ExileFromGraveyard y -> Just y; _ -> Nothing),
      Arm.payload "EntersAttachedTo" (Filter.codec Keyword.codec) EntryRewrite.EntersAttachedTo (\x -> case x of EntryRewrite.EntersAttachedTo y -> Just y; _ -> Nothing),
      Arm.payload "RunEffects" (Common.seq effectCodec) EntryRewrite.RunEffects (\x -> case x of EntryRewrite.RunEffects y -> Just y; _ -> Nothing)
    ]

tagOf :: EntryRewrite.EntryRewrite ability effect -> String
tagOf x = case x of
  EntryRewrite.AsCopy {} -> "AsCopy"
  EntryRewrite.ChoiceOf {} -> "ChoiceOf"
  EntryRewrite.ChoiceByCoinFlip {} -> "ChoiceByCoinFlip"
  EntryRewrite.WithCounters {} -> "WithCounters"
  EntryRewrite.ChooseQuality {} -> "ChooseQuality"
  EntryRewrite.ChoosePlayer {} -> "ChoosePlayer"
  EntryRewrite.ChooseCardNames {} -> "ChooseCardNames"
  EntryRewrite.ChooseCardName {} -> "ChooseCardName"
  EntryRewrite.EntersWith {} -> "EntersWith"
  EntryRewrite.UnderSourceControl {} -> "UnderSourceControl"
  EntryRewrite.ReadAhead {} -> "ReadAhead"
  EntryRewrite.Riot {} -> "Riot"
  EntryRewrite.Unleash {} -> "Unleash"
  EntryRewrite.Sunburst {} -> "Sunburst"
  EntryRewrite.ModularSunburst {} -> "ModularSunburst"
  EntryRewrite.Bloodthirst {} -> "Bloodthirst"
  EntryRewrite.Tribute {} -> "Tribute"
  EntryRewrite.Amplify {} -> "Amplify"
  EntryRewrite.Compleated {} -> "Compleated"
  EntryRewrite.Tapped {} -> "Tapped"
  EntryRewrite.EntersTransformed {} -> "EntersTransformed"
  EntryRewrite.OrTapped {} -> "OrTapped"
  EntryRewrite.SacrificeAnyNumber {} -> "SacrificeAnyNumber"
  EntryRewrite.SacrificeToEnter {} -> "SacrificeToEnter"
  EntryRewrite.ExileFromGraveyard {} -> "ExileFromGraveyard"
  EntryRewrite.EntersAttachedTo {} -> "EntersAttachedTo"
  EntryRewrite.RunEffects {} -> "RunEffects"
