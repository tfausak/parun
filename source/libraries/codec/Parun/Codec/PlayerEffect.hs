module Parun.Codec.PlayerEffect where

import qualified Parun.Codec.AlternativeActivationCost as AlternativeActivationCost
import qualified Parun.Codec.CantSearchLibraries as CantSearchLibraries
import qualified Parun.Codec.CastFromZone as CastFromZone
import qualified Parun.Codec.CombatDeclaration as CombatDeclaration
import qualified Parun.Codec.CostModifier as CostModifier
import qualified Parun.Codec.CounterProhibition as CounterProhibition
import qualified Parun.Codec.DamagePattern as DamagePattern
import qualified Parun.Codec.DrawReveal as DrawReveal
import qualified Parun.Codec.ExtraVotes as ExtraVotes
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.GameOutcome as GameOutcome
import qualified Parun.Codec.InZone as InZone
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.KeywordDesignator as KeywordDesignator
import qualified Parun.Codec.LandAllowance as LandAllowance
import qualified Parun.Codec.ManaFilter as ManaFilter
import qualified Parun.Codec.ModifiedRoll as ModifiedRoll
import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.Codec.PlotFromZone as PlotFromZone
import qualified Parun.Codec.Shows as Shows
import qualified Parun.Codec.SpendManaAsThough as SpendManaAsThough
import qualified Parun.Codec.StatedFlip as StatedFlip
import qualified Parun.Codec.TapForMana as TapForMana
import qualified Parun.Codec.TargetRestriction as TargetRestriction
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.PlayerEffect as PlayerEffect

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec PlayerEffect.PlayerEffect
codec =
  let filterCodec = Filter.codec Keyword.codec
      -- The designator absent is every ability; the source Filter absent, the
      -- empty And, every source.
      activationBan =
        Fields.object $
          (,)
            <$> Fields.defaulted "designator" Nothing (Common.maybe (KeywordDesignator.codec Keyword.codec)) fst
            <*> Fields.defaulted "sources" (Filter.Type.And []) filterCodec snd
   in Arm.tagged
        tagOf
        [ Arm.nullary "CantCastSpells" PlayerEffect.CantCastSpells,
          Arm.payload "CantActivateAbilities" activationBan (uncurry PlayerEffect.CantActivateAbilities) (\x -> case x of PlayerEffect.CantActivateAbilities y z -> Just (y, z); _ -> Nothing),
          Arm.payload "CantCastMoreThan" Common.natural PlayerEffect.CantCastMoreThan (\x -> case x of PlayerEffect.CantCastMoreThan y -> Just y; _ -> Nothing),
          Arm.payload "ModifyCost" CostModifier.codec PlayerEffect.ModifyCost (\x -> case x of PlayerEffect.ModifyCost y -> Just y; _ -> Nothing),
          Arm.payload "AlternativeActivationCost" AlternativeActivationCost.codec PlayerEffect.AlternativeActivationCost (\x -> case x of PlayerEffect.AlternativeActivationCost y -> Just y; _ -> Nothing),
          Arm.payload "PlayAdditionalLands" LandAllowance.codec PlayerEffect.PlayAdditionalLands (\x -> case x of PlayerEffect.PlayAdditionalLands y -> Just y; _ -> Nothing),
          Arm.nullary "NoMaximumHandSize" PlayerEffect.NoMaximumHandSize,
          Arm.payload "SetMaximumHandSize" Common.natural PlayerEffect.SetMaximumHandSize (\x -> case x of PlayerEffect.SetMaximumHandSize y -> Just y; _ -> Nothing),
          Arm.payload "IncreaseMaximumHandSize" Common.natural PlayerEffect.IncreaseMaximumHandSize (\x -> case x of PlayerEffect.IncreaseMaximumHandSize y -> Just y; _ -> Nothing),
          Arm.payload "ReduceMaximumHandSize" Common.natural PlayerEffect.ReduceMaximumHandSize (\x -> case x of PlayerEffect.ReduceMaximumHandSize y -> Just y; _ -> Nothing),
          Arm.payload "DontLoseUnspentMana" ManaFilter.codec PlayerEffect.DontLoseUnspentMana (\x -> case x of PlayerEffect.DontLoseUnspentMana y -> Just y; _ -> Nothing),
          Arm.nullary "LoseLifeForUnspentMana" PlayerEffect.LoseLifeForUnspentMana,
          Arm.payload "SpendManaAsThough" SpendManaAsThough.codec PlayerEffect.SpendManaAsThough (\x -> case x of PlayerEffect.SpendManaAsThough y -> Just y; _ -> Nothing),
          Arm.payload "CantBeTargetedBy" PlayerScope.codec PlayerEffect.CantBeTargetedBy (\x -> case x of PlayerEffect.CantBeTargetedBy y -> Just y; _ -> Nothing),
          Arm.payload "CastAsThoughItHadFlash" filterCodec PlayerEffect.CastAsThoughItHadFlash (\x -> case x of PlayerEffect.CastAsThoughItHadFlash y -> Just y; _ -> Nothing),
          Arm.payload "MayPlayAsThoughItHadFlash" filterCodec PlayerEffect.MayPlayAsThoughItHadFlash (\x -> case x of PlayerEffect.MayPlayAsThoughItHadFlash y -> Just y; _ -> Nothing),
          Arm.payload "ActivateKeywordAtInstantSpeed" (KeywordDesignator.codec Keyword.codec) PlayerEffect.ActivateKeywordAtInstantSpeed (\x -> case x of PlayerEffect.ActivateKeywordAtInstantSpeed y -> Just y; _ -> Nothing),
          Arm.payload "ActivateLoyaltyAtInstantSpeed" filterCodec PlayerEffect.ActivateLoyaltyAtInstantSpeed (\x -> case x of PlayerEffect.ActivateLoyaltyAtInstantSpeed y -> Just y; _ -> Nothing),
          Arm.payload "MayTapForMana" TapForMana.codec PlayerEffect.MayTapForMana (\x -> case x of PlayerEffect.MayTapForMana y -> Just y; _ -> Nothing),
          Arm.payload "CantBeCountered" CounterProhibition.codec PlayerEffect.CantBeCountered (\x -> case x of PlayerEffect.CantBeCountered y -> Just y; _ -> Nothing),
          Arm.payload "RestrictTargeting" (TargetRestriction.codec filterCodec) PlayerEffect.RestrictTargeting (\x -> case x of PlayerEffect.RestrictTargeting y -> Just y; _ -> Nothing),
          Arm.payload "DamageCantBePrevented" DamagePattern.codec PlayerEffect.DamageCantBePrevented (\x -> case x of PlayerEffect.DamageCantBePrevented y -> Just y; _ -> Nothing),
          Arm.payload "DamageCantBeRedirected" DamagePattern.codec PlayerEffect.DamageCantBeRedirected (\x -> case x of PlayerEffect.DamageCantBeRedirected y -> Just y; _ -> Nothing),
          Arm.payload "CantSearchLibraries" CantSearchLibraries.codec PlayerEffect.CantSearchLibraries (\x -> case x of PlayerEffect.CantSearchLibraries y -> Just y; _ -> Nothing),
          Arm.payload "HasProtectionFrom" filterCodec PlayerEffect.HasProtectionFrom (\x -> case x of PlayerEffect.HasProtectionFrom y -> Just y; _ -> Nothing),
          Arm.nullary "CantBecomeMonarch" PlayerEffect.CantBecomeMonarch,
          Arm.nullary "CantSetSchemesInMotion" PlayerEffect.CantSetSchemesInMotion,
          Arm.payload "EntriesDontTrigger" filterCodec PlayerEffect.EntriesDontTrigger (\x -> case x of PlayerEffect.EntriesDontTrigger y -> Just y; _ -> Nothing),
          Arm.nullary "ControlledWhileSearching" PlayerEffect.ControlledWhileSearching,
          Arm.payload "YouChoose" CombatDeclaration.codec PlayerEffect.YouChoose (\x -> case x of PlayerEffect.YouChoose y -> Just y; _ -> Nothing),
          Arm.nullary "ExilesFoundWhileSearching" PlayerEffect.ExilesFoundWhileSearching,
          Arm.nullary "CantAttackWithCreatures" PlayerEffect.CantAttackWithCreatures,
          Arm.payload "CantCastMatching" filterCodec PlayerEffect.CantCastMatching (\x -> case x of PlayerEffect.CantCastMatching y -> Just y; _ -> Nothing),
          Arm.nullary "CastOnlyAtSorcerySpeed" PlayerEffect.CastOnlyAtSorcerySpeed,
          Arm.payload "CantPlayLands" filterCodec PlayerEffect.CantPlayLands (\x -> case x of PlayerEffect.CantPlayLands y -> Just y; _ -> Nothing),
          Arm.payload "CastFrom" CastFromZone.codec PlayerEffect.CastFrom (\x -> case x of PlayerEffect.CastFrom y -> Just y; _ -> Nothing),
          Arm.payload "PlayLandsFrom" InZone.codec PlayerEffect.PlayLandsFrom (\x -> case x of PlayerEffect.PlayLandsFrom y -> Just y; _ -> Nothing),
          Arm.payload "PlotFrom" PlotFromZone.codec PlayerEffect.PlotFrom (\x -> case x of PlayerEffect.PlotFrom y -> Just y; _ -> Nothing),
          Arm.payload "CastFromHandWithoutPayingManaCost" filterCodec PlayerEffect.CastFromHandWithoutPayingManaCost (\x -> case x of PlayerEffect.CastFromHandWithoutPayingManaCost y -> Just y; _ -> Nothing),
          Arm.payload "CantGetCounters" (Common.maybe PlayerCounterKind.codec) PlayerEffect.CantGetCounters (\x -> case x of PlayerEffect.CantGetCounters y -> Just y; _ -> Nothing),
          Arm.payload "StateCoinFlip" StatedFlip.codec PlayerEffect.StateCoinFlip (\x -> case x of PlayerEffect.StateCoinFlip y -> Just y; _ -> Nothing),
          Arm.payload "ModifyDieRoll" ModifiedRoll.codec PlayerEffect.ModifyDieRoll (\x -> case x of PlayerEffect.ModifyDieRoll y -> Just y; _ -> Nothing),
          Arm.payload "AdditionalVotes" ExtraVotes.codec PlayerEffect.AdditionalVotes (\x -> case x of PlayerEffect.AdditionalVotes y -> Just y; _ -> Nothing),
          Arm.payload "AdditionalSurveilCards" Common.natural PlayerEffect.AdditionalSurveilCards (\x -> case x of PlayerEffect.AdditionalSurveilCards y -> Just y; _ -> Nothing),
          Arm.payload "PutTappedAsYouCascade" filterCodec PlayerEffect.PutTappedAsYouCascade (\x -> case x of PlayerEffect.PutTappedAsYouCascade y -> Just y; _ -> Nothing),
          Arm.nullary "CantGainLife" PlayerEffect.CantGainLife,
          Arm.nullary "CantLoseLife" PlayerEffect.CantLoseLife,
          Arm.payload "Precluded" GameOutcome.codec PlayerEffect.Precluded (\x -> case x of PlayerEffect.Precluded y -> Just y; _ -> Nothing),
          Arm.payload "Shows" Shows.codec PlayerEffect.Shows (\x -> case x of PlayerEffect.Shows y -> Just y; _ -> Nothing),
          Arm.payload "RevealsDraw" DrawReveal.codec PlayerEffect.RevealsDraw (\x -> case x of PlayerEffect.RevealsDraw y -> Just y; _ -> Nothing)
        ]

tagOf :: PlayerEffect.PlayerEffect -> String
tagOf x = case x of
  PlayerEffect.CantCastSpells {} -> "CantCastSpells"
  PlayerEffect.CantActivateAbilities {} -> "CantActivateAbilities"
  PlayerEffect.CantCastMoreThan {} -> "CantCastMoreThan"
  PlayerEffect.ModifyCost {} -> "ModifyCost"
  PlayerEffect.AlternativeActivationCost {} -> "AlternativeActivationCost"
  PlayerEffect.PlayAdditionalLands {} -> "PlayAdditionalLands"
  PlayerEffect.NoMaximumHandSize {} -> "NoMaximumHandSize"
  PlayerEffect.SetMaximumHandSize {} -> "SetMaximumHandSize"
  PlayerEffect.IncreaseMaximumHandSize {} -> "IncreaseMaximumHandSize"
  PlayerEffect.ReduceMaximumHandSize {} -> "ReduceMaximumHandSize"
  PlayerEffect.DontLoseUnspentMana {} -> "DontLoseUnspentMana"
  PlayerEffect.LoseLifeForUnspentMana {} -> "LoseLifeForUnspentMana"
  PlayerEffect.SpendManaAsThough {} -> "SpendManaAsThough"
  PlayerEffect.CantBeTargetedBy {} -> "CantBeTargetedBy"
  PlayerEffect.CastAsThoughItHadFlash {} -> "CastAsThoughItHadFlash"
  PlayerEffect.MayPlayAsThoughItHadFlash {} -> "MayPlayAsThoughItHadFlash"
  PlayerEffect.ActivateKeywordAtInstantSpeed {} -> "ActivateKeywordAtInstantSpeed"
  PlayerEffect.ActivateLoyaltyAtInstantSpeed {} -> "ActivateLoyaltyAtInstantSpeed"
  PlayerEffect.MayTapForMana {} -> "MayTapForMana"
  PlayerEffect.CantBeCountered {} -> "CantBeCountered"
  PlayerEffect.RestrictTargeting {} -> "RestrictTargeting"
  PlayerEffect.DamageCantBePrevented {} -> "DamageCantBePrevented"
  PlayerEffect.DamageCantBeRedirected {} -> "DamageCantBeRedirected"
  PlayerEffect.CantSearchLibraries {} -> "CantSearchLibraries"
  PlayerEffect.HasProtectionFrom {} -> "HasProtectionFrom"
  PlayerEffect.CantBecomeMonarch {} -> "CantBecomeMonarch"
  PlayerEffect.CantSetSchemesInMotion {} -> "CantSetSchemesInMotion"
  PlayerEffect.EntriesDontTrigger {} -> "EntriesDontTrigger"
  PlayerEffect.ControlledWhileSearching {} -> "ControlledWhileSearching"
  PlayerEffect.YouChoose {} -> "YouChoose"
  PlayerEffect.ExilesFoundWhileSearching {} -> "ExilesFoundWhileSearching"
  PlayerEffect.CantAttackWithCreatures {} -> "CantAttackWithCreatures"
  PlayerEffect.CantCastMatching {} -> "CantCastMatching"
  PlayerEffect.PutTappedAsYouCascade {} -> "PutTappedAsYouCascade"
  PlayerEffect.CastOnlyAtSorcerySpeed {} -> "CastOnlyAtSorcerySpeed"
  PlayerEffect.CantPlayLands {} -> "CantPlayLands"
  PlayerEffect.CastFrom {} -> "CastFrom"
  PlayerEffect.PlayLandsFrom {} -> "PlayLandsFrom"
  PlayerEffect.PlotFrom {} -> "PlotFrom"
  PlayerEffect.CastFromHandWithoutPayingManaCost {} -> "CastFromHandWithoutPayingManaCost"
  PlayerEffect.CantGetCounters {} -> "CantGetCounters"
  PlayerEffect.StateCoinFlip {} -> "StateCoinFlip"
  PlayerEffect.ModifyDieRoll {} -> "ModifyDieRoll"
  PlayerEffect.AdditionalVotes {} -> "AdditionalVotes"
  PlayerEffect.AdditionalSurveilCards {} -> "AdditionalSurveilCards"
  PlayerEffect.CantGainLife {} -> "CantGainLife"
  PlayerEffect.CantLoseLife {} -> "CantLoseLife"
  PlayerEffect.Precluded {} -> "Precluded"
  PlayerEffect.Shows {} -> "Shows"
  PlayerEffect.RevealsDraw {} -> "RevealsDraw"
