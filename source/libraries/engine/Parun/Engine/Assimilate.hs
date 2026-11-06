-- | CR 701.72, "assimilate": the whole of the keyword action, as the
-- instructions rules 701.72a and 701.72b spell it out as.
--
-- Parun.Engine.Earthbend's and Parun.Engine.Airbend's sibling, standing on the
-- same ground: rule 701 is a keyword-action rule exactly as rule 702 is a
-- keyword rule, so the procedure lives in the engine rather than in card data.
-- Every instruction is already in the effect vocabulary -- a control change (CR
-- 613.1b), a counter placement (CR 122.6), a type change (CR 613.1d) and a move
-- (CR 400.7) -- so this module writes them as Effects and
-- Parun.Engine.Resolve.Arms.Counters's Effect.Assimilate arm runs them through
-- the same executor, without saying which effects they are.
--
-- Two instruction lists over two reserved slots, because the rule is two
-- rules: which applies is a question about each object's ZONE as the action is
-- performed, which the arm answers before any instruction runs.
module Parun.Engine.Assimilate where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Parun.Engine.Binding as Binding
import Parun.Types.Card (Card)
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChangeMode as ChangeMode
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Duration as Duration
import Parun.Types.Effect (Effect)
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import Parun.Types.Modification (Modification)
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Zone as Zone

-- | CR 701.72a / 701.72b's "Borg artifact creature", which CR 205.1b reads as
-- keeping every prior card type and subtype but the creature types, and
-- replacing those: the two card types added (Parun.Types.Modification's
-- CardType says why InAddition twice), then the creature types set.
--
-- In that order, though all three sit in layer 4 under one timestamp: CR
-- 205.3d refuses a creature type to an object that is not a creature, and CR
-- 701.72a's permanent need not be one before the action makes it one.
borgArtifactCreature :: [Modification ability]
borgArtifactCreature =
  [ Modification.CardType ChangeMode.InAddition CardType.Artifact,
    Modification.CardType ChangeMode.InAddition CardType.Creature,
    Modification.CreatureSubtype ChangeMode.Replace Subtype.Borg
  ]

-- | CR 701.72a over the permanents bound to Binding.assimilatedPermanents, in
-- written order (CR 608.2c): gain control, put the counter, then the type
-- change.
--
-- Duration.Indefinite throughout: rule 701.72a states no duration, so CR
-- 611.2a leaves both effects running until the permanent leaves the
-- battlefield and CR 400.7 makes it a new object.
--
-- The counter is put after the control change, so a counter replacement keyed
-- to "a creature you control" reads the permanent as already theirs.
permanentInstructions :: [Effect Card (GrantedAbility.GrantedAbility Card)]
permanentInstructions =
  let ref = ObjectRef.InSlot Binding.assimilatedPermanents
      becomes modification = Effect.ModifyTarget (ModifyTarget.MkModifyTarget Duration.Indefinite modification ref Nothing)
   in Effect.GainControl (GainControl.MkGainControl Duration.Indefinite ref (PlayerRef.Relative PlayerRelation.You))
        : Effect.PutCounters
          PutCounters.MkPutCounters
            { PutCounters.kind = CounterKind.PlusOnePlusOne,
              PutCounters.quantity = Quantity.Literal 1,
              PutCounters.ref = ref,
              PutCounters.totalAtMost = Nothing
            }
        : fmap becomes borgArtifactCreature

-- | CR 701.72b over the cards bound to Binding.assimilatedCards: one move, CR
-- 608.2f's single event, whose riders carry the counter (CR 122.6) and the type
-- change (CR 611.2e), so no permanent ever exists without either.
--
-- EntryRiders.under is its default, the instructed player: rule 701.72b's
-- "under your control" is CR 109.5's "you". The move links each arrival to the
-- source as every move onto the battlefield does, which is CR 701.72c's
-- "assimilated with" for this half of the rule.
cardInstruction :: Effect Card (GrantedAbility.GrantedAbility Card)
cardInstruction =
  Effect.MoveToZone
    MoveToZone.MkMoveToZone
      { MoveToZone.ref = ObjectRef.InSlot Binding.assimilatedCards,
        MoveToZone.zone = Zone.Battlefield,
        MoveToZone.riders =
          EntryRiders.defaultValue
            { EntryRiders.counters = Map.singleton CounterKind.PlusOnePlusOne (Quantity.Literal 1),
              EntryRiders.characteristics = Seq.fromList borgArtifactCreature
            },
        MoveToZone.slot = Nothing,
        MoveToZone.origin = Nothing,
        MoveToZone.placement = LibraryPlacement.defaultValue,
        MoveToZone.duration = Nothing
      }
