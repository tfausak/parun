-- | CR 701.66, "earthbend N": the whole of the keyword action, as the three
-- instructions rule 701.66a spells it out as.
--
-- Parun.Engine.Blight's and Parun.Engine.Amass's sibling, standing on the same
-- ground: rule 701 is a keyword-action rule exactly as rule 702 is a keyword
-- rule, so the procedure lives in the engine rather than in card data. The
-- closed\/open invariant forbids the rules core casing on an EFFECT's identity,
-- and nothing here does -- Parun.Engine.Resolve.Arms.Counters's Effect.Earthbend arm
-- calls in without saying which effect it is.
--
-- What is DIFFERENT from those two is that rule 701.66a's three instructions are
-- already in the effect vocabulary: an animation (CR 611, layers 4, 6 and 7b), a
-- counter placement (CR 122.6) and a CR 603.7 delayed ability. So this module
-- writes them as Effects and lets the same executor run them, rather than
-- reaching past it into the board. The one thing it cannot write as card data is
-- the delayed ability itself, which is why that lives here and is filed on
-- Parun.Engine.Keyword's minted roster.
--
-- CR 701.66b's "whenever a player earthbends" is written from
-- Parun.Engine.Resolve.Arms.Counters's Effect.Earthbend arm rather than from here, since
-- rule 701.66b puts the moment at the CREATION of the delayed ability 'arm'
-- mints and this module only describes it. GameEvent.PlayerActed is the entry and
-- TriggerCondition.PlayerActs reads it.
module Parun.Engine.Earthbend where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Mint as Mint
import Parun.Types.AbilityName (AbilityName)
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import Parun.Types.Card (Card)
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Earthbend as Earthbend
import Parun.Types.Effect (Effect)
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Onset as Onset
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TriggerCondition as TriggerCondition
import Parun.Types.TriggeredAbility (TriggeredAbility)
import qualified Parun.Types.Zone as Zone

-- | CR 701.66a's first two sentences, in written order (CR 608.2c): the
-- animation, then the counters. Handed to Parun.Engine.Resolve.Arms.Counters's executor
-- one at a time, so each runs exactly as the same instruction printed on a card
-- would.
--
-- THREE Modifications and so three continuous effects, where the rule prints one
-- sentence. CR 613 is what makes that indistinguishable: the three sit in layers
-- 4, 7b and 6, and a timestamp orders only effects competing within one layer,
-- so no third effect can be interleaved between them. Parun.Types.Modification is
-- one modification per effect and a sum over them would be a new type for this
-- one sentence.
--
-- NO Land card type is added. Rule 701.66a says "0\/0 land creature", and the
-- object is already a land -- rule 701.66a's own "target land you control" is
-- what guarantees it, and CR 608.2b re-checks that at resolution. An
-- AddCardType Land would be a layer-4 no-op on every board that reaches here.
--
-- Duration.Indefinite and not UntilEndOfTurn: rule 701.66a states no duration,
-- so CR 611.2a leaves the effect running until the game ends -- which in
-- practice means until the land leaves the battlefield and CR 400.7 makes it a
-- new object the frozen CR 611.2c set no longer names.
instructions :: Earthbend.Earthbend -> [Effect Card (GrantedAbility.GrantedAbility Card)]
instructions earthbend =
  let ref = Earthbend.ref earthbend
      animate modification = Effect.ModifyTarget (ModifyTarget.MkModifyTarget Duration.Indefinite modification ref Nothing)
   in [ animate (Modification.AddCardType CardType.Creature),
        animate (Modification.SetBasePowerToughness (SetBasePowerToughness.MkSetBasePowerToughness (Just (Quantity.Literal 0)) (Just (Quantity.Literal 0)))),
        animate (Modification.GainKeyword Keyword.Haste),
        Effect.PutCounters
          PutCounters.MkPutCounters
            { PutCounters.kind = CounterKind.PlusOnePlusOne,
              PutCounters.quantity = Earthbend.quantity earthbend,
              PutCounters.ref = ref
            }
      ]

-- | CR 701.66a's third sentence, as the opcode that creates it. Onset.Immediately
-- with no stated duration -- CR 603.7a's floor and CR 603.7b's default -- because
-- rule 701.66a gates neither end of the envelope: the ability watches from the
-- moment it is created and fires once.
arm :: Effect Card (GrantedAbility.GrantedAbility Card)
arm =
  Effect.ArmDelayedTrigger
    ArmDelayedTrigger.MkArmDelayedTrigger
      { ArmDelayedTrigger.name = returnName,
        ArmDelayedTrigger.onset = Onset.Immediately,
        ArmDelayedTrigger.duration = Nothing,
        ArmDelayedTrigger.ability = Nothing
      }

-- | The name rule 701.66a's delayed ability is filed under on
-- Parun.Engine.Keyword.mintedDelayedAbilities. A card may not declare one under
-- this name (Parun.CardSpec), which is what makes the fallback order in
-- Parun.Engine.Resolve.Effect immaterial.
returnName :: AbilityName
returnName = AbilityName.MkAbilityName (Text.pack "earthbend")

-- | CR 701.66a: "when that land dies or is put into exile, return it to the
-- battlefield tapped under your control".
--
-- The condition names Parun.Engine.Binding.earthbentLand, which the arming
-- resolution stamped onto the resolving object: CR 603.7c captures that whole
-- environment, so the entry still remembers which land it was about long after
-- the spell has gone.
--
-- The payload acts on Binding.became and NOT on the earthbent land, which is the
-- CR 400.7 incarnation split undying and persist meet one rule over: the id the
-- condition matched is the battlefield permanent, which no longer exists, while
-- `became` is the card in the graveyard or in exile that the return has to move.
--
-- EntryRiders.under is its default, the instructed player, which is CR 110.2a read literally: rule
-- 701.66a states otherwise -- "under your control" -- and "you" is the delayed
-- ability's controller (CR 603.7d), the player who earthbent.
returnAbility :: TriggeredAbility Card (GrantedAbility.GrantedAbility Card)
returnAbility =
  let effect =
        Effect.MoveToZone
          MoveToZone.MkMoveToZone
            { MoveToZone.ref = ObjectRef.InSlot Binding.became,
              MoveToZone.zone = Zone.Battlefield,
              MoveToZone.riders =
                EntryRiders.defaultValue {EntryRiders.tapped = TapState.Tapped},
              MoveToZone.slot = Nothing,
              MoveToZone.origin = Nothing,
              MoveToZone.placement = LibraryPlacement.defaultValue,
              MoveToZone.duration = Nothing
            }
   in Mint.trigger (TriggerCondition.BoundDiesOrIsExiled Binding.earthbentLand) (Seq.singleton effect)
