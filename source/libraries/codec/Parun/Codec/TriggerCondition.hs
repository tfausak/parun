module Parun.Codec.TriggerCondition where

import qualified Parun.Codec.AbilityAddsMana as AbilityAddsMana
import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.AttackTrigger as AttackTrigger
import qualified Parun.Codec.BecomesTapState as BecomesTapState
import qualified Parun.Codec.BecomesTargetedTrigger as BecomesTargetedTrigger
import qualified Parun.Codec.BlockTrigger as BlockTrigger
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CausedBy as CausedBy
import qualified Parun.Codec.ClassLevel as ClassLevel
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.Codec.CounterTrigger as CounterTrigger
import qualified Parun.Codec.DamageTrigger as DamageTrigger
import qualified Parun.Codec.DieResult as DieResult
import qualified Parun.Codec.DiscardTrigger as DiscardTrigger
import qualified Parun.Codec.EntersTrigger as EntersTrigger
import qualified Parun.Codec.ExploitTrigger as ExploitTrigger
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.LeavesTrigger as LeavesTrigger
import qualified Parun.Codec.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.Codec.LifeTrigger as LifeTrigger
import qualified Parun.Codec.PermanentActed as PermanentActed
import qualified Parun.Codec.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Codec.PermanentIsDealtDamage as PermanentIsDealtDamage
import qualified Parun.Codec.PermanentTappedForMana as PermanentTappedForMana
import qualified Parun.Codec.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Codec.PlacesSticker as PlacesSticker
import qualified Parun.Codec.PlayerActed as PlayerActed
import qualified Parun.Codec.PlayerActsOn as PlayerActsOn
import qualified Parun.Codec.PlayerDrawsNthCard as PlayerDrawsNthCard
import qualified Parun.Codec.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.PlaysLand as PlaysLand
import qualified Parun.Codec.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.Codec.RevealedThisWay as RevealedThisWay
import qualified Parun.Codec.RoomIndex as RoomIndex
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.SpellCast as SpellCast
import qualified Parun.Codec.StepBegins as StepBegins
import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.TriggerCondition as TriggerCondition

-- | RECURSIVE, through the one arm that holds conditions: 'AnyOf' names 'codec'
-- inside its own definition. That terminates because 'Arm.tagged' reaches WHNF
-- as a 'Codec.MkCodec' without forcing its arm list, and the SCHEMA terminates
-- because 'Define.define' registers this type's name before running the body,
-- so the re-entry emits a @$ref@ rather than recursing.
--
-- The five two-element-array payloads this codec used to write are now named
-- objects with records behind them (#1305).
codec :: Codec.Codec TriggerCondition.TriggerCondition
codec =
  let filterCodec = Filter.codec Keyword.codec
   in Arm.tagged
        tagOf
        [ Arm.payload "Enters" EntersTrigger.codec TriggerCondition.Enters (\x -> case x of TriggerCondition.Enters y -> Just y; _ -> Nothing),
          Arm.payload "StepBegins" StepBegins.codec TriggerCondition.StepBegins (\x -> case x of TriggerCondition.StepBegins y -> Just y; _ -> Nothing),
          Arm.payload "StateIs" Condition.codec TriggerCondition.StateIs (\x -> case x of TriggerCondition.StateIs y -> Just y; _ -> Nothing),
          Arm.payload "DealsDamage" DamageTrigger.codec TriggerCondition.DealsDamage (\x -> case x of TriggerCondition.DealsDamage y -> Just y; _ -> Nothing),
          Arm.payload "IsDealtDamage" PermanentIsDealtDamage.codec TriggerCondition.IsDealtDamage (\x -> case x of TriggerCondition.IsDealtDamage y -> Just y; _ -> Nothing),
          Arm.payload "PlayerIsDealtDamage" PlayerIsDealtDamage.codec TriggerCondition.PlayerIsDealtDamage (\x -> case x of TriggerCondition.PlayerIsDealtDamage y -> Just y; _ -> Nothing),
          Arm.payload "PermanentsDealCombatDamageToPlayer" PermanentsDealCombatDamageToPlayer.codec TriggerCondition.PermanentsDealCombatDamageToPlayer (\x -> case x of TriggerCondition.PermanentsDealCombatDamageToPlayer y -> Just y; _ -> Nothing),
          Arm.nullary "CreatureDealtCombatDamageToMonarch" TriggerCondition.CreatureDealtCombatDamageToMonarch,
          Arm.nullary "CreaturesDealtCombatDamageToInitiative" TriggerCondition.CreaturesDealtCombatDamageToInitiative,
          Arm.nullary "PlayerTookInitiative" TriggerCondition.PlayerTookInitiative,
          Arm.payload "Attacks" AttackTrigger.codec TriggerCondition.Attacks (\x -> case x of TriggerCondition.Attacks y -> Just y; _ -> Nothing),
          Arm.payload "Blocks" BlockTrigger.codec TriggerCondition.Blocks (\x -> case x of TriggerCondition.Blocks y -> Just y; _ -> Nothing),
          Arm.nullary "SelfRevealedForMiracle" TriggerCondition.SelfRevealedForMiracle,
          Arm.payload "RevealedThisWay" RevealedThisWay.codec TriggerCondition.RevealedThisWay (\x -> case x of TriggerCondition.RevealedThisWay y -> Just y; _ -> Nothing),
          Arm.payload "Discards" DiscardTrigger.codec TriggerCondition.Discards (\x -> case x of TriggerCondition.Discards y -> Just y; _ -> Nothing),
          Arm.payload "PlayerDrawsNthCard" PlayerDrawsNthCard.codec TriggerCondition.PlayerDrawsNthCard (\x -> case x of TriggerCondition.PlayerDrawsNthCard y -> Just y; _ -> Nothing),
          Arm.payload "Leaves" LeavesTrigger.codec TriggerCondition.Leaves (\x -> case x of TriggerCondition.Leaves y -> Just y; _ -> Nothing),
          Arm.payload "LeavesZone" LeavesZoneTrigger.codec TriggerCondition.LeavesZone (\x -> case x of TriggerCondition.LeavesZone y -> Just y; _ -> Nothing),
          Arm.payload "PutIntoZone" PutIntoZoneTrigger.codec TriggerCondition.PutIntoZone (\x -> case x of TriggerCondition.PutIntoZone y -> Just y; _ -> Nothing),
          Arm.payload "BecomesTapState" BecomesTapState.codec TriggerCondition.BecomesTapState (\x -> case x of TriggerCondition.BecomesTapState y -> Just y; _ -> Nothing),
          Arm.payload "PermanentsBecomeTapped" filterCodec TriggerCondition.PermanentsBecomeTapped (\x -> case x of TriggerCondition.PermanentsBecomeTapped y -> Just y; _ -> Nothing),
          Arm.nullary "AttachedPermanentTappedForMana" TriggerCondition.AttachedPermanentTappedForMana,
          Arm.payload "PermanentTappedForMana" PermanentTappedForMana.codec TriggerCondition.PermanentTappedForMana (\x -> case x of TriggerCondition.PermanentTappedForMana y -> Just y; _ -> Nothing),
          Arm.payload "AbilityAddsMana" AbilityAddsMana.codec TriggerCondition.AbilityAddsMana (\x -> case x of TriggerCondition.AbilityAddsMana y -> Just y; _ -> Nothing),
          Arm.nullary "SelfManaAbilityResolves" TriggerCondition.SelfManaAbilityResolves,
          Arm.payload "SpellOrAbilityCounters" PlayerRelation.codec TriggerCondition.SpellOrAbilityCounters (\x -> case x of TriggerCondition.SpellOrAbilityCounters y -> Just y; _ -> Nothing),
          Arm.nullary "AbilityIsCountered" TriggerCondition.AbilityIsCountered,
          Arm.payload "DamageToPlayerPrevented" PlayerRelation.codec TriggerCondition.DamageToPlayerPrevented (\x -> case x of TriggerCondition.DamageToPlayerPrevented y -> Just y; _ -> Nothing),
          Arm.payload "SelfPreventsDamage" filterCodec TriggerCondition.SelfPreventsDamage (\x -> case x of TriggerCondition.SelfPreventsDamage y -> Just y; _ -> Nothing),
          Arm.payload "LifeChanges" LifeTrigger.codec TriggerCondition.LifeChanges (\x -> case x of TriggerCondition.LifeChanges y -> Just y; _ -> Nothing),
          Arm.payload "CountersChange" CounterTrigger.codec TriggerCondition.CountersChange (\x -> case x of TriggerCondition.CountersChange y -> Just y; _ -> Nothing),
          Arm.payload "SelfBecomesClassLevel" ClassLevel.codec TriggerCondition.SelfBecomesClassLevel (\x -> case x of TriggerCondition.SelfBecomesClassLevel y -> Just y; _ -> Nothing),
          Arm.payload "SpellCast" SpellCast.codec TriggerCondition.SpellCast (\x -> case x of TriggerCondition.SpellCast y -> Just y; _ -> Nothing),
          Arm.payload "AbilityActivated" filterCodec TriggerCondition.AbilityActivated (\x -> case x of TriggerCondition.AbilityActivated y -> Just y; _ -> Nothing),
          Arm.payload "BecomesTargeted" BecomesTargetedTrigger.codec TriggerCondition.BecomesTargeted (\x -> case x of TriggerCondition.BecomesTargeted y -> Just y; _ -> Nothing),
          Arm.payload "ControllerBecomesTarget" ControllerBecomesTarget.codec TriggerCondition.ControllerBecomesTarget (\x -> case x of TriggerCondition.ControllerBecomesTarget y -> Just y; _ -> Nothing),
          Arm.payload "SelfHalfUnlocked" CardName.codec TriggerCondition.SelfHalfUnlocked (\x -> case x of TriggerCondition.SelfHalfUnlocked y -> Just y; _ -> Nothing),
          Arm.payload "RoomFullyUnlocked" PlayerRelation.codec TriggerCondition.RoomFullyUnlocked (\x -> case x of TriggerCondition.RoomFullyUnlocked y -> Just y; _ -> Nothing),
          Arm.payload "AnyOf" (Common.list codec) TriggerCondition.AnyOf (\x -> case x of TriggerCondition.AnyOf y -> Just y; _ -> Nothing),
          Arm.payload "CausedBy" (CausedBy.codec codec) TriggerCondition.CausedBy (\x -> case x of TriggerCondition.CausedBy y -> Just y; _ -> Nothing),
          Arm.payload "TurnedFaceUp" ActingPermanent.codec TriggerCondition.TurnedFaceUp (\x -> case x of TriggerCondition.TurnedFaceUp y -> Just y; _ -> Nothing),
          Arm.payload "SelfTransformedInto" CardName.codec TriggerCondition.SelfTransformedInto (\x -> case x of TriggerCondition.SelfTransformedInto y -> Just y; _ -> Nothing),
          Arm.payload "PermanentTransforms" filterCodec TriggerCondition.PermanentTransforms (\x -> case x of TriggerCondition.PermanentTransforms y -> Just y; _ -> Nothing),
          Arm.payload "PermanentActs" (PermanentActed.codec ActingPermanent.codec) TriggerCondition.PermanentActs (\x -> case x of TriggerCondition.PermanentActs y -> Just y; _ -> Nothing),
          Arm.nullary "FaceDownPermanentLeavesRevealed" TriggerCondition.FaceDownPermanentLeavesRevealed,
          Arm.payload "PermanentBecomesDesignated" PermanentBecomesDesignated.codec TriggerCondition.PermanentBecomesDesignated (\x -> case x of TriggerCondition.PermanentBecomesDesignated y -> Just y; _ -> Nothing),
          Arm.nullary "AttachedCreatureMentors" TriggerCondition.AttachedCreatureMentors,
          Arm.payload "Exploits" ExploitTrigger.codec TriggerCondition.Exploits (\x -> case x of TriggerCondition.Exploits y -> Just y; _ -> Nothing),
          Arm.payload "SelfBecomesCrewed" TriggerFrequency.codec TriggerCondition.SelfBecomesCrewed (\x -> case x of TriggerCondition.SelfBecomesCrewed y -> Just y; _ -> Nothing),
          Arm.nullary "SelfCrewsVehicle" TriggerCondition.SelfCrewsVehicle,
          Arm.payload "PermanentSacrificed" PlayerActsOn.codec TriggerCondition.PermanentSacrificed (\x -> case x of TriggerCondition.PermanentSacrificed y -> Just y; _ -> Nothing),
          Arm.payload "SagaFinalChapterTriggers" PlayerRelation.codec TriggerCondition.SagaFinalChapterTriggers (\x -> case x of TriggerCondition.SagaFinalChapterTriggers y -> Just y; _ -> Nothing),
          Arm.payload "PlayerBecomesMonarch" PlayerRelation.codec TriggerCondition.PlayerBecomesMonarch (\x -> case x of TriggerCondition.PlayerBecomesMonarch y -> Just y; _ -> Nothing),
          Arm.payload "LoseControlOfBound" SlotName.codec TriggerCondition.LoseControlOfBound (\x -> case x of TriggerCondition.LoseControlOfBound y -> Just y; _ -> Nothing),
          Arm.nullary "LoseControlOfSelf" TriggerCondition.LoseControlOfSelf,
          Arm.payload "RoomEntered" RoomIndex.codec TriggerCondition.RoomEntered (\x -> case x of TriggerCondition.RoomEntered y -> Just y; _ -> Nothing),
          Arm.payload "PlayerActs" (PlayerActed.codec PlayerRelation.codec) TriggerCondition.PlayerActs (\x -> case x of TriggerCondition.PlayerActs y -> Just y; _ -> Nothing),
          Arm.payload "PlayerLosesGame" PlayerRelation.codec TriggerCondition.PlayerLosesGame (\x -> case x of TriggerCondition.PlayerLosesGame y -> Just y; _ -> Nothing),
          Arm.payload "PlayerPlaysLand" PlaysLand.codec TriggerCondition.PlayerPlaysLand (\x -> case x of TriggerCondition.PlayerPlaysLand y -> Just y; _ -> Nothing),
          Arm.payload "PlayerManifestsDread" PlayerRelation.codec TriggerCondition.PlayerManifestsDread (\x -> case x of TriggerCondition.PlayerManifestsDread y -> Just y; _ -> Nothing),
          Arm.payload "PlayerRollsResult" (DieResult.codec PlayerRelation.codec) TriggerCondition.PlayerRollsResult (\x -> case x of TriggerCondition.PlayerRollsResult y -> Just y; _ -> Nothing),
          Arm.nullary "Visit" TriggerCondition.Visit,
          Arm.nullary "ChaosEnsues" TriggerCondition.ChaosEnsues,
          Arm.payload "PlayerRollsPlaneswalker" PlayerRelation.codec TriggerCondition.PlayerRollsPlaneswalker (\x -> case x of TriggerCondition.PlayerRollsPlaneswalker y -> Just y; _ -> Nothing),
          Arm.nullary "SelfTurnedUpOffDeck" TriggerCondition.SelfTurnedUpOffDeck,
          Arm.nullary "SelfPlaneswalkedAwayFrom" TriggerCondition.SelfPlaneswalkedAwayFrom,
          Arm.payload "PlayerWinsCoinFlip" PlayerRelation.codec TriggerCondition.PlayerWinsCoinFlip (\x -> case x of TriggerCondition.PlayerWinsCoinFlip y -> Just y; _ -> Nothing),
          Arm.payload "PlayerLosesCoinFlip" PlayerRelation.codec TriggerCondition.PlayerLosesCoinFlip (\x -> case x of TriggerCondition.PlayerLosesCoinFlip y -> Just y; _ -> Nothing),
          Arm.nullary "SelfBecomesPlotted" TriggerCondition.SelfBecomesPlotted,
          Arm.nullary "Reflexive" TriggerCondition.Reflexive,
          Arm.payload "SelfBecomesAttachedBy" filterCodec TriggerCondition.SelfBecomesAttachedBy (\x -> case x of TriggerCondition.SelfBecomesAttachedBy y -> Just y; _ -> Nothing),
          -- CR 701.3a read from the attachment, and CR 701.3d's mirror of it. Same
          -- shape as the arm above with the Filter over the HOST instead.
          Arm.payload "SelfBecomesAttachedTo" filterCodec TriggerCondition.SelfBecomesAttachedTo (\x -> case x of TriggerCondition.SelfBecomesAttachedTo y -> Just y; _ -> Nothing),
          Arm.payload "SelfBecomesUnattachedFrom" filterCodec TriggerCondition.SelfBecomesUnattachedFrom (\x -> case x of TriggerCondition.SelfBecomesUnattachedFrom y -> Just y; _ -> Nothing),
          Arm.payload "PlacesSticker" PlacesSticker.codec TriggerCondition.PlacesSticker (\x -> case x of TriggerCondition.PlacesSticker y -> Just y; _ -> Nothing)
        ]

tagOf :: TriggerCondition.TriggerCondition -> String
tagOf x = case x of
  TriggerCondition.Enters {} -> "Enters"
  TriggerCondition.StepBegins {} -> "StepBegins"
  TriggerCondition.StateIs {} -> "StateIs"
  TriggerCondition.DealsDamage {} -> "DealsDamage"
  TriggerCondition.IsDealtDamage {} -> "IsDealtDamage"
  TriggerCondition.PlayerIsDealtDamage {} -> "PlayerIsDealtDamage"
  TriggerCondition.PermanentsDealCombatDamageToPlayer {} -> "PermanentsDealCombatDamageToPlayer"
  TriggerCondition.CreatureDealtCombatDamageToMonarch {} -> "CreatureDealtCombatDamageToMonarch"
  TriggerCondition.CreaturesDealtCombatDamageToInitiative {} -> "CreaturesDealtCombatDamageToInitiative"
  TriggerCondition.PlayerTookInitiative {} -> "PlayerTookInitiative"
  TriggerCondition.Attacks {} -> "Attacks"
  TriggerCondition.Blocks {} -> "Blocks"
  TriggerCondition.SelfRevealedForMiracle {} -> "SelfRevealedForMiracle"
  TriggerCondition.RevealedThisWay {} -> "RevealedThisWay"
  TriggerCondition.Discards {} -> "Discards"
  TriggerCondition.PlayerDrawsNthCard {} -> "PlayerDrawsNthCard"
  TriggerCondition.Leaves {} -> "Leaves"
  TriggerCondition.LeavesZone {} -> "LeavesZone"
  TriggerCondition.PutIntoZone {} -> "PutIntoZone"
  TriggerCondition.BecomesTapState {} -> "BecomesTapState"
  TriggerCondition.PermanentsBecomeTapped {} -> "PermanentsBecomeTapped"
  TriggerCondition.AttachedPermanentTappedForMana {} -> "AttachedPermanentTappedForMana"
  TriggerCondition.PermanentTappedForMana {} -> "PermanentTappedForMana"
  TriggerCondition.AbilityAddsMana {} -> "AbilityAddsMana"
  TriggerCondition.SelfManaAbilityResolves {} -> "SelfManaAbilityResolves"
  TriggerCondition.SpellOrAbilityCounters {} -> "SpellOrAbilityCounters"
  TriggerCondition.AbilityIsCountered {} -> "AbilityIsCountered"
  TriggerCondition.DamageToPlayerPrevented {} -> "DamageToPlayerPrevented"
  TriggerCondition.SelfPreventsDamage {} -> "SelfPreventsDamage"
  TriggerCondition.LifeChanges {} -> "LifeChanges"
  TriggerCondition.CountersChange {} -> "CountersChange"
  TriggerCondition.SelfBecomesClassLevel {} -> "SelfBecomesClassLevel"
  TriggerCondition.SpellCast {} -> "SpellCast"
  TriggerCondition.AbilityActivated {} -> "AbilityActivated"
  TriggerCondition.BecomesTargeted {} -> "BecomesTargeted"
  TriggerCondition.ControllerBecomesTarget {} -> "ControllerBecomesTarget"
  TriggerCondition.SelfHalfUnlocked {} -> "SelfHalfUnlocked"
  TriggerCondition.RoomFullyUnlocked {} -> "RoomFullyUnlocked"
  TriggerCondition.AnyOf {} -> "AnyOf"
  TriggerCondition.CausedBy {} -> "CausedBy"
  TriggerCondition.TurnedFaceUp {} -> "TurnedFaceUp"
  TriggerCondition.SelfTransformedInto {} -> "SelfTransformedInto"
  TriggerCondition.PermanentTransforms {} -> "PermanentTransforms"
  TriggerCondition.PermanentActs {} -> "PermanentActs"
  TriggerCondition.FaceDownPermanentLeavesRevealed {} -> "FaceDownPermanentLeavesRevealed"
  TriggerCondition.PermanentBecomesDesignated {} -> "PermanentBecomesDesignated"
  TriggerCondition.AttachedCreatureMentors {} -> "AttachedCreatureMentors"
  TriggerCondition.Exploits {} -> "Exploits"
  TriggerCondition.SelfBecomesCrewed {} -> "SelfBecomesCrewed"
  TriggerCondition.SelfCrewsVehicle {} -> "SelfCrewsVehicle"
  TriggerCondition.PermanentSacrificed {} -> "PermanentSacrificed"
  TriggerCondition.SagaFinalChapterTriggers {} -> "SagaFinalChapterTriggers"
  TriggerCondition.PlayerBecomesMonarch {} -> "PlayerBecomesMonarch"
  TriggerCondition.LoseControlOfBound {} -> "LoseControlOfBound"
  TriggerCondition.LoseControlOfSelf {} -> "LoseControlOfSelf"
  TriggerCondition.RoomEntered {} -> "RoomEntered"
  TriggerCondition.PlayerActs {} -> "PlayerActs"
  TriggerCondition.PlayerLosesGame {} -> "PlayerLosesGame"
  TriggerCondition.PlayerPlaysLand {} -> "PlayerPlaysLand"
  TriggerCondition.PlayerManifestsDread {} -> "PlayerManifestsDread"
  TriggerCondition.PlayerRollsResult {} -> "PlayerRollsResult"
  TriggerCondition.Visit {} -> "Visit"
  TriggerCondition.ChaosEnsues {} -> "ChaosEnsues"
  TriggerCondition.PlayerRollsPlaneswalker {} -> "PlayerRollsPlaneswalker"
  TriggerCondition.SelfTurnedUpOffDeck {} -> "SelfTurnedUpOffDeck"
  TriggerCondition.SelfPlaneswalkedAwayFrom {} -> "SelfPlaneswalkedAwayFrom"
  TriggerCondition.PlayerWinsCoinFlip {} -> "PlayerWinsCoinFlip"
  TriggerCondition.PlayerLosesCoinFlip {} -> "PlayerLosesCoinFlip"
  TriggerCondition.SelfBecomesPlotted {} -> "SelfBecomesPlotted"
  TriggerCondition.Reflexive {} -> "Reflexive"
  TriggerCondition.SelfBecomesAttachedBy {} -> "SelfBecomesAttachedBy"
  TriggerCondition.SelfBecomesAttachedTo {} -> "SelfBecomesAttachedTo"
  TriggerCondition.SelfBecomesUnattachedFrom {} -> "SelfBecomesUnattachedFrom"
  TriggerCondition.PlacesSticker {} -> "PlacesSticker"
