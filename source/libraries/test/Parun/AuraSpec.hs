-- Pattern matching on Parun.Types.Prompt, a GADT, in aimAt below.
{-# LANGUAGE GADTs #-}
-- replenishSpec's `run` takes an ANSWERER, which is polymorphic in the prompt's
-- answer type -- Parun.CostSpec's reason for the same pragma.
{-# LANGUAGE RankNTypes #-}

-- Covers Parun.Engine.Stack's Aura branch and Parun.Engine.Resolve.targetsAllIllegal -- a
-- resolving Aura spell either fizzles (CR 608.2b) or enters the battlefield
-- already attached to its target (CR 303.4) -- together with the rest of the
-- attachment substrate that shares Object.attachedTo: Parun.Engine.Resolve's Attach
-- opcode over Parun.Engine.Attach (CR 701.3) and Parun.Engine.Sba's three attachment
-- state-based actions (CR 704.5m, 704.5n, 704.5p). Resolution is not the only door
-- onto the battlefield: CR 303.4f's Aura entering from anywhere else has its host
-- chosen inside Parun.Engine.Event.changeZoneAttaching, which is replenishSpec's,
-- and a search whose destination NAMES the host seeds that same funnel instead,
-- which data/scenarios/aura's Sovereigns of Lost Alara scenario proves.
-- Rule 701.3's OTHER caller, CR 303.4k's attachment as an Aura is turned face up,
-- is Parun.FaceDownSpec's: CR 708.11 puts it inside the turning-over rather than in
-- a resolution.
--
-- Also Parun.Engine.Replacement's CR 614.1c as-enters basic-land-type choice,
-- since the pool's one producer of it is an Aura (Convincing Mirage) and
-- proving it needs a real cast through this file's machinery.
module Parun.AuraSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Engine.Action as Action
import qualified Parun.Engine.Activatable as Activatable
import qualified Parun.Engine.Activate as Activate
import qualified Parun.Engine.Card as Card
import qualified Parun.Engine.Cast as Cast
import qualified Parun.Engine.Combat as Combat
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.EndEffect as EndEffect
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Interchangeable as Interchangeable
import qualified Parun.Engine.Modal as Modal
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Engine.Stack as Stack
import qualified Parun.Engine.Target as Target
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.Action as Action.Type
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.AnyNumberOf as AnyNumberOf
import qualified Parun.Types.AttachTarget as AttachTarget
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackerDeclared as AttackerDeclared
import qualified Parun.Types.BlocksDeclared as BlocksDeclared
import qualified Parun.Types.CandidateCost as CandidateCost
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Cost as Cost.Type
import qualified Parun.Types.Departure as Departure.Type
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerChoice as PlayerChoice
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Printing as Printing
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Protection as Protection
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Regenerability as Regenerability
import qualified Parun.Types.Response as Response
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.StepBegan as StepBegan
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TextWord as TextWord
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.Zone as Zone

-- Answers every CR 601.2c target offer with the named object when it is offered
-- at all, and with the smallest of the rest when it is not. Top level so that it
-- stays rank-1 polymorphic in the prompt's result; a `let` binding under the
-- monomorphism restriction cannot answer two prompts of different result types.
aimedAtObject :: ObjectId.ObjectId -> Prompt.Prompt r -> r
aimedAtObject oid p = case p of
  Prompt.ChooseTargets _ _ _ sets -> S.preferring ((==) (Just oid) . Recipient.objectOf) sets
  _ -> S.identityAnswer p

-- CR 301.5 / 702.6: Equipment. Shares the attachment substrate with Auras --
-- Object.attachedTo, and an affected set read off it -- so what is genuinely new
-- is the CR 701.3 Attach keyword action that MOVES an already-on-the-battlefield permanent,
-- and CR 704.5n's detach-rather-than-bury state-based action; see #193. The
-- Reattach group below is the same keyword action aimed the other way, at a
-- permanent the effect TARGETS rather than at its own source.
equipmentSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
equipmentSpec s registry = Spec.describe s "Equipment" $ do
  -- CR 301.5a: "The creature an Equipment is attached to is called the
  -- 'equipped creature'." CR 301.5f makes the phrase name a creature and not
  -- merely a host, so Bonesplitter's affected set spells the type out beside the
  -- attachment; Parun.ProjectionSpec's HoneCounter group is where the difference
  -- shows, and its Basilisk Collar case is what proves the type gate bites.
  Spec.it s "CR 301.5a the equipped creature gets the Equipment's bonus" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.alice base
        (equip, gs) = S.addPermanent bonesplitter S.alice withCreature
        attached = S.attach equip creature gs
    Spec.assertEqWith s "unequipped, the Piker is 2/1" (Projection.powerOf creature gs) (Just 2)
    Spec.assertEqWith s "equipped, it is 4/1" (Projection.powerOf creature attached) (Just 4)
    Spec.assertEqWith s "toughness is untouched by +2/+0" (Projection.toughnessOf creature attached) (Just 1)
  -- The gameplay-level proof design.md section 4 asks for: cast Bonesplitter,
  -- activate the equip ability rule 702.6a mints from its keyword through the
  -- real activation path, let
  -- it resolve, and see the creature actually hit harder. Everything above
  -- drives Effect.Attach directly; this drives the CARD.
  Spec.it s "CR 702.6 whole card: cast Bonesplitter, equip a Piker, and it swings for 4" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    let base0 = S.landsInPlay mountain 2 -- {1} to cast, {1} to equip
        (creature, base1) = S.addPermanent piker S.alice base0
        (withSpell, spellId) = S.handOne bonesplitter base1
        cast = snd (Engine.runGamePure S.identityAnswer withSpell (S.cast S.alice spellId))
        resolved = snd (Engine.runGamePure S.identityAnswer cast Stack.resolveTop)
        equipId = case filter (\oid -> Game.cardOf oid resolved == Just (Printing.card bonesplitter)) (Set.toList (GameState.battlefield resolved)) of
          oid : _ -> Just oid
          [] -> Nothing
    case equipId of
      Nothing -> Spec.assertFailure s "Bonesplitter should have resolved onto the battlefield"
      Just equip -> do
        -- From the PROJECTION, not the face: rule 702.6a's ability is minted
        -- from the keyword Bonesplitter declares, so its card file lists no
        -- activated ability at all.
        let ability = case Projection.abilitiesOf equip resolved of
              ab : _ -> Just ab
              [] -> Nothing
        case ability of
          Nothing -> Spec.assertFailure s "Bonesplitter should offer rule 702.6a's minted equip ability"
          Just equipAbility -> do
            let ready = resolved {GameState.priority = Just S.alice}
                activated = snd (Engine.runGamePure S.identityAnswer ready (Activate.activateAbility S.alice equip equipAbility))
                after = snd (Engine.runGamePure S.identityAnswer activated Stack.resolveTop)
            Spec.assertEqWith s "unequipped the Piker is 2/1" (Projection.powerOf creature resolved) (Just 2)
            Spec.assertEqWith s "the equip ability attached it" (fmap Object.attachedTo (Game.lookupObject equip after)) (Just (Just (Recipient.ToCreature creature)))
            Spec.assertEqWith s "and the Piker is now 4/1" (Projection.powerOf creature after) (Just 4)
            Spec.assertEqWith s "toughness unchanged" (Projection.toughnessOf creature after) (Just 1)
  -- CR 702.6c: "These equip abilities may legally target only a creature that's
  -- controlled by the player activating the ability and that has the chosen
  -- quality." Dúnedain Blade prints "Equip Human {1}" beside a plain "Equip
  -- {3}", so one card drives that narrowing and CR 702.6d's "any of its equip
  -- abilities may be activated" at once.
  --
  -- The PAIR is the proof: one board, one answerer that always prefers the
  -- Goblin, and the only difference is WHICH of the Blade's two minted abilities
  -- is activated. Three lands pay either cost, so neither half can pass for want
  -- of mana. The Goblin is the only other creature alice controls, which is what
  -- makes the quality ability's candidate list a singleton.
  Spec.it s "CR 702.6c an equip Human ability can't reach the Goblin, and CR 702.6d the plain one on the same card can" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    evangel <- S.printingOf s registry "Cabal Evangel"
    blade <- S.printingOf s registry "Dúnedain Blade"
    let (goblin, base1) = S.addPermanent piker S.alice (S.landsInPlay mountain 3)
        (human, base2) = S.addPermanent evangel S.alice base1
        (bladeId, base3) = S.addPermanent blade S.alice base2
        board = base3 {GameState.priority = Just S.alice}
        abilityCosting n =
          List.find
            ((==) (Just (ManaCost.MkManaCost [ManaSymbol.Generic n])) . Cost.Type.mana . ActivatedAbility.cost)
            (Projection.abilitiesOf bladeId board)
        equipWith ability =
          let activated = snd (Engine.runGamePure (aimedAtObject goblin) board (Activate.activateAbility S.alice bladeId ability))
           in snd (Engine.runGamePure (aimedAtObject goblin) activated Stack.resolveTop)
    case (abilityCosting 1, abilityCosting 3) of
      (Just quality, Just plain) -> do
        let afterQuality = equipWith quality
            afterPlain = equipWith plain
        Spec.assertEqWith s "CR 702.6c the quality ability attached the Blade to the Human" (fmap Object.attachedTo (Game.lookupObject bladeId afterQuality)) (Just (Just (Recipient.ToCreature human)))
        Spec.assertEqWith s "so the Goblin is still 2/1" (Projection.powerOf goblin afterQuality) (Just 2)
        Spec.assertEqWith s "and the Human is 4/3" (Projection.powerOf human afterQuality) (Just 4)
        Spec.assertEqWith s "CR 702.6d the plain ability, on the same board, attached it to the Goblin" (fmap Object.attachedTo (Game.lookupObject bladeId afterPlain)) (Just (Just (Recipient.ToCreature goblin)))
        Spec.assertEqWith s "which is then 4/1" (Projection.powerOf goblin afterPlain) (Just 4)
      _ -> Spec.assertFailure s "Dúnedain Blade should offer both of rule 702.6's minted abilities"
  -- CR 702.151a's first ability -- "[Cost]: Attach this permanent to another
  -- target creature you control. Activate only as a sorcery" -- driven as the
  -- whole card, plus the two rules that make it mean anything: CR 301.5c's
  -- "an Equipment that's also a creature can't equip a creature unless that
  -- Equipment has reconfigure", and CR 702.151b's "attaching an Equipment with
  -- reconfigure to another creature causes the Equipment to stop being a
  -- creature until it becomes unattached from that creature".
  --
  -- Rabbit Battery ({R} Artifact Creature -- Equipment Rabbit, 1/1: "Haste" /
  -- "Equipped creature gets +1\/+1 and has haste." / "Reconfigure {R}", checked
  -- against Scryfall on 2026-09-18) is the producer, and the Goblin Piker the
  -- host: 2\/1 unequipped and hasteless, so both halves of the Battery's grant
  -- change something.
  --
  -- The attachment is read BEFORE state-based actions and the card type AFTER,
  -- which is what keeps the two assertions apart. Without rule 702.151b the
  -- Battery is an attached creature and CR 704.5p (Parun.Engine.Sba's
  -- cannotBeAttached) detaches it on the next pass, so the third assertion is
  -- rule 702.151b's consequence rather than a restatement of it.
  Spec.it s "CR 702.151b an attached Rabbit Battery is not a creature and stays attached" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    battery <- S.printingOf s registry "Rabbit Battery"
    let (creature, g1) = S.addPermanent piker S.alice (S.landsInPlay mountain 1)
        (batteryId, g2) = S.addPermanent battery S.alice g1
        board = g2 {GameState.priority = Just S.alice}
        minted = case Projection.abilitiesOf batteryId board of
          ab : _ -> Just ab
          [] -> Nothing
    case minted of
      Nothing -> Spec.assertFailure s "Rabbit Battery should offer rule 702.151a's minted ability"
      Just ability -> do
        let activated = snd (Engine.runGamePure (aimedAtObject creature) board (Activate.activateAbility S.alice batteryId ability))
            resolved = snd (Engine.runGamePure (aimedAtObject creature) activated Stack.resolveTop)
            after = S.settleSba resolved
        Spec.assertEqWith s "CR 301.5c the Equipment creature equipped, reconfigure being that rule's exception" (fmap Object.attachedTo (Game.lookupObject batteryId resolved)) (Just (Just (Recipient.ToCreature creature)))
        Spec.assertBool s (not (Projection.isCreatureOf batteryId after)) "CR 702.151b and stopped being a creature while attached"
        Spec.assertEqWith s "CR 704.5p so nothing detaches it" (fmap Object.attachedTo (Game.lookupObject batteryId after)) (Just (Just (Recipient.ToCreature creature)))
        Spec.assertEqWith s "and the Piker is 3 power" (Projection.powerOf creature after) (Just 3)
        Spec.assertBool s (Projection.hasKeyword Keyword.Haste creature after) "with haste"
  -- CR 702.151a's SECOND ability's restriction, "Activate only if this
  -- permanent is attached to a creature": one board with the Battery on the
  -- Piker and one with it loose, the same Mountain and the same sorcery-speed
  -- window on both (CR 307.5). The unattach itself
  -- is data/scenarios/unattach's reconfigure scenario.
  Spec.it s "CR 702.151a Rabbit Battery's unattach ability is offered only while it is attached" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    battery <- S.printingOf s registry "Rabbit Battery"
    let (creature, g1) = S.addPermanent piker S.alice (S.landsInPlay mountain 1)
        (batteryId, loose) = S.addPermanent battery S.alice g1
        attached = S.attach batteryId creature loose
        offered g = case Projection.abilitiesOf batteryId g of
          _ : off : _ -> Activatable.activatable S.alice batteryId off g {GameState.phase = Phase.PrecombatMain, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}
          _ -> False
    Spec.assertBool s (offered attached) "attached to the Piker, it can be unattached"
    Spec.assertBool s (not (offered loose)) "loose, it cannot"
  -- Tamiyo's Compleation ({3}{U} Aura, Flash: "Enchant artifact, creature, or
  -- planeswalker / When this Aura enters, tap enchanted permanent. If it's an
  -- Equipment, unattach it. / Enchanted permanent loses all abilities and
  -- doesn't untap during its controller's untap step.", Scryfall 2026-10-01).
  -- Losing all abilities already takes the Bonesplitter's bonus away, so the
  -- unattach is read off Object.attachedTo, on a pair differing only in the
  -- target: on the Bonesplitter it comes off; on the Piker, the Bonesplitter
  -- stays, since "it" is the enchanted permanent and not what is attached to it.
  --
  -- The card's "if it's an Equipment" is a regression fence: only an enchanted
  -- permanent that is itself attached to something and is no Equipment observes
  -- it, and neither board builds one.
  Spec.it s "CR 701.3d Tamiyo's Compleation unattaches the Equipment it enchants, not a creature's Equipment" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    compleation <- S.printingOf s registry "Tamiyo's Compleation"
    let (creature, g1) = S.addPermanent piker S.alice (S.landsInPlay island 4)
        (equip, g2) = S.addPermanent bonesplitter S.alice g1
        (withSpell, spellId) = S.handOne compleation (S.attach equip creature g2)
        triggeredOn target = S.runPure S.identityAnswer (S.runPure S.identityAnswer (S.runPure (aimedAtObject target) withSpell (S.cast S.alice spellId)) Stack.resolveTop) Engine.settleForPriority
        enchanting target = S.runPure S.identityAnswer (triggeredOn target) Stack.resolveTop
        hostOf g = fmap Object.attachedTo (Game.lookupObject equip g)
    Spec.assertEqWith s "on the Bonesplitter, it comes off the Piker" (hostOf (enchanting equip)) (Just Nothing)
    Spec.assertEqWith s "on the Piker, its Bonesplitter stays on" (hostOf (enchanting creature)) (Just (Just (Recipient.ToCreature creature)))
    Spec.assertEqWith s "each enchanted permanent is tapped" (fmap Object.tapped (Game.lookupObject equip (enchanting equip)), fmap Object.tapped (Game.lookupObject creature (enchanting creature))) (Just TapState.Tapped, Just TapState.Tapped)
    Spec.assertBool s (not (any (null . GameState.stack . triggeredOn) [equip, creature])) "the enters trigger really was on the stack both times"
  -- CR 608.2h / 113.7a: Bewitching Leechcraft ({1}{U} Aura, "When this Aura
  -- enters, tap enchanted creature.", Scryfall 2026-10-13) destroyed in response
  -- to its own enters trigger. The trigger still taps the creature the Aura
  -- enchanted as it left (Parun.Types.LastKnown.host). Bob's second Piker is the
  -- bystander: it stays untapped, and while the trigger waits it is no longer
  -- interchangeable with the enchanted one (Parun.Engine.Interchangeable's
  -- namedByAnother), since only one of them is about to be tapped. A third
  -- Piker the Aura never touched is the control leg, alike with the bystander.
  -- The gameplay case is data/scenarios/aura's Leechcraft scenario.
  Spec.it s "CR 608.2h a departed Aura's enters trigger still names the creature it enchanted" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    leechcraft <- S.printingOf s registry "Bewitching Leechcraft"
    let (enchanted, g1) = S.addPermanent piker S.bob (S.landsInPlay island 2)
        (bystander, g2) = S.addPermanent piker S.bob g1
        (untouched, g3) = S.addPermanent piker S.bob g2
        (withSpell, spellId) = S.handOne leechcraft g3
        triggered = S.runPure S.identityAnswer (S.runPure S.identityAnswer (S.runPure (aimedAtObject enchanted) withSpell (S.cast S.alice spellId)) Stack.resolveTop) Engine.settleForPriority
        auras = Set.toList (Game.attachments enchanted triggered)
        destroyed = List.foldl' (\g aura -> S.runPure S.identityAnswer g (Event.changeZone (pure ()) aura Zone.Graveyard)) triggered auras
        resolved = S.runPure S.identityAnswer destroyed Stack.resolveTop
        tappedOf oid g = fmap Object.tapped (Game.lookupObject oid g)
        alike = Interchangeable.objects (Projection.projectAll destroyed) destroyed
    Spec.assertEqWith s "the enchanted Piker is tapped, the bystander is not" (tappedOf enchanted resolved, tappedOf bystander resolved) (Just TapState.Tapped, Just TapState.Untapped)
    Spec.assertEqWith s "while the trigger waits, the enchanted Piker is not alike with the bystander" (alike enchanted bystander, alike bystander enchanted) (False, False)
    Spec.assertEqWith s "control leg: two Pikers the Aura never touched are alike" (alike bystander untouched) True
    Spec.assertEqWith s "CR 608.2h the departed Aura's view names the host it had" (fmap (fmap Filter.attachedTo . Projection.viewWithLastKnownAnywhere destroyed) auras) [Just (Just enchanted)]
    Spec.assertEqWith s "setup: one Aura, gone, its trigger waiting, the Piker untapped" (length auras, any (`Set.member` GameState.battlefield destroyed) auras, length (GameState.stack destroyed), tappedOf enchanted destroyed) (1, False, 1, Just TapState.Untapped)
  -- CR 301.5c's RESTRICTION, the arm the case above is the exception to. One
  -- board, one move, and the only difference is a Humility on the battlefield:
  -- CR 613.1f strips the Battery's reconfigure (it is a creature while
  -- unattached), leaving an Equipment that is also a creature and has no
  -- reconfigure, which is exactly the permanent rule 301.5c forbids to equip.
  --
  -- Effect.Attach directly rather than the minted ability, because Humility has
  -- taken that ability away too: the question here is what
  -- Parun.Engine.Attach.attachmentFor permits, not what may be activated.
  Spec.it s "CR 301.5c an Equipment creature whose reconfigure Humility removes can't equip" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    battery <- S.printingOf s registry "Rabbit Battery"
    humility <- S.printingOf s registry "Humility"
    let (creature, g1) = S.addPermanent piker S.alice (S.landsInPlay mountain 1)
        (batteryId, plain) = S.addPermanent battery S.alice g1
        (_, humbled) = S.addPermanent humility S.alice plain
        slot = SlotName.MkSlotName (Text.pack "target")
        recipients = Map.singleton slot (Set.singleton (Recipient.ToCreature creature))
        attachOn g = S.runPure S.identityAnswer g (Resolve.applyEffect batteryId batteryId S.alice recipients recipients (Effect.Attach slot))
    Spec.assertEqWith s "with reconfigure the Equipment creature equips" (fmap Object.attachedTo (Game.lookupObject batteryId (attachOn plain))) (Just (Just (Recipient.ToCreature creature)))
    Spec.assertEqWith s "CR 301.5c without it the same move does nothing" (fmap Object.attachedTo (Game.lookupObject batteryId (attachOn humbled))) (Just Nothing)
  -- CR 704.5n: "If an Equipment or Fortification is attached to an illegal
  -- permanent or to a player, it becomes unattached from that permanent or
  -- player. It REMAINS ON THE BATTLEFIELD." The shape difference from an
  -- Aura, which CR 704.5m buries instead; see #193.
  Spec.it s "CR 704.5n an Equipment whose creature dies detaches and stays on the battlefield" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.alice base
        (equip, g2) = S.addPermanent bonesplitter S.alice withCreature
        attached = S.attach equip creature g2
        gone = S.runPure S.identityAnswer attached (Event.changeZone (pure ()) creature Zone.Graveyard)
        after = S.settleSba gone
    Spec.assertBool s (Set.member equip (GameState.battlefield after)) "the Equipment survives"
    Spec.assertEqWith s "and is unattached" (fmap Object.attachedTo (Game.lookupObject equip after)) (Just Nothing)
  -- CR 301.5: "It can't legally be attached to anything that isn't a
  -- creature." An Equipment left on a noncreature permanent detaches too --
  -- the same SBA, a different way of becoming illegal.
  Spec.it s "CR 301.5 an Equipment attached to a noncreature permanent detaches" $ do
    mountain <- S.printingOf s registry "Mountain"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    let base = Setup.emptyGame S.bothPlayers
        (land, withLand) = S.addPermanent mountain S.alice base
        (equip, g2) = S.addPermanent bonesplitter S.alice withLand
        attached = S.attach equip land g2
        after = S.settleSba attached
    Spec.assertBool s (Set.member equip (GameState.battlefield after)) "the Equipment survives"
    Spec.assertEqWith s "and is unattached" (fmap Object.attachedTo (Game.lookupObject equip after)) (Just Nothing)

-- alice's board for the fortify cases: Dryad Arbor (a land that is also a
-- creature), Tower of the Magistrate, Darksteel Garrison, and four Forests to
-- pay with. Sorcery-speed timing is set here rather than left to
-- Setup.emptyGame's untap step, because CR 702.67a's "activate only as a
-- sorcery" is a real gate (CR 307.5).
--
-- The Arbor is left UNTAPPED and is never tapped by any case below: Darksteel
-- Garrison's own "whenever fortified land becomes tapped" trigger would
-- otherwise fire and put a second object on the stack.
fortifyBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, GameState.GameState)
fortifyBoard s registry = do
  forest <- S.printingOf s registry "Forest"
  dryadArbor <- S.printingOf s registry "Dryad Arbor"
  tower <- S.printingOf s registry "Tower of the Magistrate"
  garrison <- S.printingOf s registry "Darksteel Garrison"
  let base = S.landsInPlay forest 4
      (arborId, g1) = S.addPermanent dryadArbor S.alice base
      (towerId, g2) = S.addPermanent tower S.alice g1
      (garrisonId, g3) = S.addPermanent garrison S.alice g2
  pure
    ( arborId,
      towerId,
      garrisonId,
      g3 {GameState.phase = Phase.PrecombatMain, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}
    )

-- CR 702.16a's "protection from artifacts", the quality Tower of the Magistrate
-- grants and the one Darksteel Garrison has.
protectionFromArtifacts :: Keyword.Keyword
protectionFromArtifacts = Keyword.Protection Protection.MkProtection {Protection.quality = Filter.Type.HasCardType CardType.Artifact, Protection.spares = Nothing}

-- CR 301.6 / 702.67: Fortifications, the Equipment group above one card type
-- over -- a Fortification attaches to a LAND, and CR 301.6 says the two are
-- otherwise the same rule ("rules 301.5a-f apply to Fortifications in relation
-- to lands just as they apply to Equipment in relation to creatures").
--
-- Darksteel Garrison ({2} Artifact -- Fortification, "Fortified land has
-- indestructible." / "Whenever fortified land becomes tapped, target creature
-- gets +1/+1 until end of turn." / "Fortify {3}", checked against Scryfall on
-- 2026-08-27) is the producer, and Dryad Arbor the host: rule 301.6 wants a
-- land, and CR 702.16d's clause below wants that land to be able to gain
-- protection, which no grant in the pool offers anything but a creature: Tower
-- of the Magistrate targets one, and Synthetic Emblem Forge's emblem and
-- Synthetic Grave Bulwark's graveyard ability both name creatures you control.
--
-- Tower of the Magistrate ("{T}: Add {C}." / "{1}, {T}: Target creature gains
-- protection from artifacts until end of turn.", same fetch) is the grant. The
-- Garrison is a colorless artifact, so "artifacts" is the one quality of it a
-- printed card can name.
fortificationSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
fortificationSpec s registry = Spec.describe s "Fortification" $ do
  -- CR 702.67a: "Fortify is an activated ability of Fortification cards.
  -- 'Fortify [cost]' means '[Cost]: Attach this Fortification to target land you
  -- control. Activate only as a sorcery.'" MINTED from the keyword, so the card
  -- file declares Keyword.Fortify and prints no activated ability -- equip's
  -- arrangement one rule over, and the single-ability match is the same trap
  -- assertion.
  Spec.it s "CR 702.67a the fortify ability is minted from the keyword, not printed" $ do
    garrison <- S.printingOf s registry "Darksteel Garrison"
    (_, _, garrisonId, gs) <- fortifyBoard s registry
    Spec.assertEqWith s "the card itself prints no activated ability" (Face.activatedAbilities (S.combinedFace garrison)) []
    case Projection.abilitiesOf garrisonId gs of
      [ability] ->
        Spec.assertEqWith
          s
          "the printed {3}, with nothing appended -- rule 702.67a states no tap symbol"
          (ActivatedAbility.cost ability)
          (Cost.Type.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 3])) [])
      abilities -> Spec.assertFailure s ("expected exactly one fortify ability, got " <> show (length abilities))
  -- CR 702.16b, and NOT rule 702.16d's first sentence, which is why the
  -- state-based case above is the one that proves this unit: a Fortification is
  -- the source of its own fortify ability, so a land already protected from
  -- artifacts is out of rule 702.67a's offered set on the TARGETING rule before
  -- rule 702.16d's "can't be fortified" is reached. The two readings agree here
  -- and attachRestrictionSpec's header says why nothing in this pool separates
  -- them. Same board and same two activations as the case above, in the other
  -- order.
  Spec.it s "CR 702.16b a land with protection from artifacts is not offered to the fortify ability" $ do
    (arborId, towerId, garrisonId, gs) <- fortifyBoard s registry
    case (Projection.abilitiesOf garrisonId gs, Projection.abilitiesOf towerId gs) of
      ([fortifyAbility], [_, protect]) -> do
        let protected =
              let activated = S.runPure (aimAtOffered arborId) gs (Activate.activateAbility S.alice towerId protect)
               in S.runPure (aimAtOffered arborId) activated Stack.resolveTop
            after =
              let activated = S.runPure (aimAtOffered arborId) protected (Activate.activateAbility S.alice garrisonId fortifyAbility)
               in S.runPure (aimAtOffered arborId) activated Stack.resolveTop
        Spec.assertEqWith s "the fortify resolved onto nothing" (fmap Object.attachedTo (Game.lookupObject garrisonId after)) (Just Nothing)
        Spec.assertBool s (Projection.hasKeyword protectionFromArtifacts arborId protected) "the land had the protection when the fortify resolved"
      abilities -> Spec.assertFailure s ("expected one fortify ability and two Tower abilities, got " <> show (fmap length abilities))
  -- CR 301.6: "It can't legally be attached to an object that isn't a land."
  -- CR 704.5n's illegal-host conjunct, the Equipment group's CR 301.5 case with
  -- the card types swapped. Hand-built, because rule 702.67a's own target slot
  -- would never offer a creature.
  Spec.it s "CR 301.6 a Fortification attached to a nonland detaches and stays on the battlefield" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    garrison <- S.printingOf s registry "Darksteel Garrison"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.alice base
        (garrisonId, g2) = S.addPermanent garrison S.alice withCreature
        attached = S.attachTo garrisonId (Recipient.ToObject creature) g2
        after = S.settleSba attached
    Spec.assertEqWith s "the Fortification is unattached" (fmap Object.attachedTo (Game.lookupObject garrisonId after)) (Just Nothing)
    Spec.assertBool s (Set.member garrisonId (GameState.battlefield after)) "and survives"

-- An answerer that aims every target slot at one object, deferring everything
-- else to S.identityAnswer (ModalSpec.chooseModeAt's shape). The CR 303.4d case
-- below needs it because both of its target choices are real ones -- alice
-- controls other permanents that each target slot admits -- so they cannot be forced by
-- board construction the way the sibling cases above force theirs.
aimAt :: ObjectId.ObjectId -> Prompt.Prompt r -> r
aimAt oid p = case p of
  Prompt.ChooseTargets _ _ _ sets -> fmap (const (Set.singleton (Recipient.ToObject oid))) sets
  _ -> S.identityAnswer p

-- CR 704.5p, the sibling of CR 704.5n above: 704.5n asks whether the HOST is
-- still legal, and this asks whether the attached permanent may be attached to
-- anything at all. Both detach and leave the permanent on the battlefield.
unattachableSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
unattachableSpec s registry = Spec.describe s "Unattachable" $ do
  -- CR 704.5p, first sentence: "If a battle or creature is attached to an
  -- object or player, it becomes unattached and remains on the battlefield."
  -- CR 301.5c says the same from the card type's side -- "An Equipment that's
  -- also a creature can't equip a creature unless that Equipment has
  -- reconfigure" -- and so does Skilled Animator's own ruling: "If an
  -- Equipment becomes an artifact creature, it usually can't be attached to
  -- another creature. If it was attached to a creature, it becomes
  -- unattached." (Bonesplitter has no reconfigure; Rabbit Battery does, and the
  -- "CR 702.151" group below is where that exception is proved.)
  --
  -- Note which SBA does NOT fire here: CR 704.5n needs an ILLEGAL host, and
  -- the Piker is a perfectly legal one. It is the Equipment itself that has
  -- stopped being attachable.
  --
  -- Whole card, through the real pipeline: cast Skilled Animator, let its
  -- CR 603.6a enters-the-battlefield trigger target the equipped
  -- Bonesplitter, and watch the equipped creature lose the bonus.
  Spec.it s "CR 704.5p whole card: animating an equipped Bonesplitter detaches it and the Piker loses the bonus" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    animator <- S.printingOf s registry "Skilled Animator"
    let base = S.landsInPlay island 3 -- {2}{U}
        (creature, g1) = S.addPermanent piker S.alice base
        (equip, g2) = S.addPermanent bonesplitter S.alice g1
        attached = S.attach equip creature g2
        (withSpell, spellId) = S.handOne animator attached
        cast = snd (Engine.runGamePure S.identityAnswer withSpell (S.cast S.alice spellId))
        resolved = snd (Engine.runGamePure S.identityAnswer cast Stack.resolveTop)
        -- The ETB trigger goes on the stack here, with its target chosen:
        -- Bonesplitter is the only artifact alice controls, so CR 603.3d's
        -- choice is forced.
        triggered = snd (Engine.runGamePure S.identityAnswer resolved Engine.settleForPriority)
        animated = snd (Engine.runGamePure S.identityAnswer triggered Stack.resolveTop)
        after = snd (Engine.runGamePure S.identityAnswer animated Engine.settleForPriority)
    Spec.assertEqWith s "equipped, the Piker was 4/1" (Projection.powerOf creature attached) (Just 4)
    Spec.assertBool s (not (null (GameState.stack triggered))) "the enters-the-battlefield trigger really was on the stack"
    Spec.assertEqWith s "the Equipment is now a 5/5 creature" (Projection.powerOf equip after) (Just 5)
    Spec.assertBool s (Set.member equip (GameState.battlefield after)) "it stays on the battlefield"
    Spec.assertEqWith s "and is unattached" (fmap Object.attachedTo (Game.lookupObject equip after)) (Just Nothing)
    Spec.assertEqWith s "so the Piker is back to 2 power" (Projection.powerOf creature after) (Just 2)
  -- CR 704.5p, second sentence: "if any nonbattle, noncreature permanent
  -- that's neither an Aura, an Equipment, nor a Fortification is attached to
  -- an object or player, it becomes unattached and remains on the
  -- battlefield." No card can produce this state -- nothing in the pool
  -- strips the Equipment subtype, and nothing attaches a land -- so the
  -- attachment is hand-built, the way the CR 301.5 case in the Equipment
  -- group above hand-builds an Equipment on a land. What it pins is that the
  -- branch reads the permanent's own types and not its host's: the Piker here
  -- is a legal host for anything that may be attached at all.
  Spec.it s "CR 704.5p a land attached to a creature detaches and stays on the battlefield" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.alice base
        (land, g2) = S.addPermanent mountain S.alice withCreature
        attached = S.attach land creature g2
        after = S.settleSba attached
    Spec.assertBool s (Set.member land (GameState.battlefield after)) "the land survives"
    Spec.assertEqWith s "and is unattached" (fmap Object.attachedTo (Game.lookupObject land after)) (Just Nothing)
  -- CR 303.4d's second clause: "An Aura that's also a creature can't enchant
  -- anything. If this occurs somehow, the Aura becomes unattached, then is
  -- put into its owner's graveyard. (These are state-based actions.)"
  --
  -- Two state-based actions, in that order, and this drives them one pass at
  -- a time to prove the order rather than only the end state: CR 704.5p
  -- unattaches the Aura (it is a creature that is attached), and only then
  -- does CR 704.5m see an Aura attached to nothing and bury it. Neither rule
  -- names CR 303.4d; between them they are what enforces it.
  --
  -- Reaching the clause at all takes two cards, because every printed
  -- enchantment animator carefully excludes Auras -- Opalescence and
  -- Starfield of Nyx both say "non-Aura enchantment", and so does Zur,
  -- Eternal Schemer. So the Aura is made
  -- an ARTIFACT first (Liquimetal Coating), which nothing excludes it from,
  -- and Skilled Animator then animates it as one.
  Spec.it s "CR 303.4d whole cards: an Aura made a creature unattaches, then is buried" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    coating <- S.printingOf s registry "Liquimetal Coating"
    animator <- S.printingOf s registry "Skilled Animator"
    let base = S.landsInPlay island 3 -- {2}{U} for the Animator
        (creature, g1) = S.addPermanent piker S.alice base
        (aura, g2) = S.addPermanent unholyStrength S.alice g1
        attached = S.attach aura creature g2
        (coatingId, g3) = S.addPermanent coating S.alice attached
        ability = case Face.activatedAbilities (S.combinedFace coating) of
          ab : _ -> Just ab
          [] -> Nothing
    case ability of
      Nothing -> Spec.assertFailure s "Liquimetal Coating should print one activated ability"
      Just coat -> do
        let ready = g3 {GameState.priority = Just S.alice}
            activated = snd (Engine.runGamePure (aimAt aura) ready (Activate.activateAbility S.alice coatingId coat))
            coated = snd (Engine.runGamePure (aimAt aura) activated Stack.resolveTop)
            (withSpell, spellId) = S.handOne animator coated
            cast = snd (Engine.runGamePure (aimAt aura) withSpell (S.cast S.alice spellId))
            entered = snd (Engine.runGamePure (aimAt aura) cast Stack.resolveTop)
            triggered = snd (Engine.runGamePure (aimAt aura) entered Engine.settleForPriority)
            animated = snd (Engine.runGamePure (aimAt aura) triggered Stack.resolveTop)
            -- S.settleSba is ONE pass (the CR 704.3 repeat lives in
            -- Engine.settleForPriority), which is what makes the two steps
            -- separately observable.
            unattachedNow = S.settleSba animated
            buried = S.settleSba unattachedNow
        Spec.assertBool s (Set.member CardType.Artifact (Projection.cardTypesOf aura coated)) "the Aura is an artifact now"
        Spec.assertEqWith s "and once animated it is a 5/5 creature" (Projection.powerOf aura animated) (Just 5)
        Spec.assertEqWith s "still enchanting the Piker at that moment" (fmap Object.attachedTo (Game.lookupObject aura animated)) (Just (Just (Recipient.ToCreature creature)))
        Spec.assertEqWith s "which is still 2/1 + 2/+1" (Projection.powerOf creature animated) (Just 4)
        -- Step one: unattached, and still on the battlefield.
        Spec.assertEqWith s "one SBA pass unattaches it" (fmap Object.attachedTo (Game.lookupObject aura unattachedNow)) (Just Nothing)
        Spec.assertBool s (Set.member aura (GameState.battlefield unattachedNow)) "and it has not been buried yet"
        -- Step two: CR 704.5m buries the now-unattached Aura.
        Spec.assertBool s (not (Set.member aura (GameState.battlefield buried))) "the next pass buries it"
        -- CR 400.7: it is a new object there, so this counts the zone rather
        -- than looking the battlefield id up again.
        Spec.assertEqWith s "in its OWNER's graveyard" (length (Game.zoneMembers Zone.Graveyard S.alice buried)) 1
        Spec.assertEqWith s "so the Piker loses the +2/+1" (Projection.powerOf creature buried) (Just 2)

-- CR 702.5d: "Auras that can enchant a player can target and be attached to
-- players. Such Auras can't target permanents and can't be attached to
-- permanents." Curse of Death's Hold is the proving card -- "Enchant player.
-- Creatures enchanted player controls get -1/-1" -- and it is the one that needs
-- BOTH halves of an enchant-player Aura: the Pool.Players enchant slot, which
-- Face.enchant could already express, and a static ability whose affected set is
-- reached THROUGH the enchanted player (Affected.AttachedPlayerControls).
enchantPlayerSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
enchantPlayerSpec s registry = Spec.describe s "EnchantPlayer" $ do
  -- The affected set is DYNAMIC in its controller half, which is what makes it
  -- a set rather than a list of ids: CR 613.1b applies control changes in
  -- layer 2, before the layer 7c this ability lands in, so a creature the
  -- enchanted player no longer controls is out of the set on the very next
  -- projection. Control Magic moves it: `data/cards/`'s control-changing Auras
  -- are it, Confiscate and Synthetic Puppeteer's Yoke, and Control Magic's
  -- creature-only enchant slot is the narrower fit. Synthetic Goblin Dominion
  -- and the Yoke move control too, but by a predicate rather than by naming an
  -- object, so neither can be pointed at one creature.
  Spec.it s "CR 613.1b: a creature stolen from the enchanted player leaves the Curse's affected set" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    curse <- S.printingOf s registry "Curse of Death's Hold"
    controlMagic <- S.printingOf s registry "Control Magic"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.bob base
        (aura, withAura) = S.addPermanent curse S.alice withCreature
        cursed = S.attachTo aura (Recipient.ToPlayer S.bob) withAura
        (steal, withSteal) = S.addPermanent controlMagic S.alice cursed
        stolen = S.attach steal creature withSteal
    Spec.assertEqWith s "bob controls it and it is shrunk" (S.powerToughnessOf creature cursed) (Just (1, 0))
    Spec.assertEqWith s "alice controls it now, so the Curse does not reach it" (S.powerToughnessOf creature stolen) (Just (2, 1))
  -- SYNTHETIC. "Synthetic Puppeteer's Yoke" {3}{U}{U} Enchantment - Aura:
  -- "Enchant player. You control all permanents enchanted player controls." The
  -- control-granting twin of Curse of Death's Hold, and the only shape that
  -- reaches Affected.AttachedPlayerControls through the CR 613.1b layer-2 fold
  -- rather than through a later layer.
  --
  -- Scryfall with a User-Agent, 2026-09-08: o:"you control all permanents",
  -- o:"permanents enchanted player controls" and o:"controls all permanents"
  -- match nothing at all, and the eight hits for o:"enchanted player controls"
  -- -o:"gain control" -t:instant -t:sorcery are every one of them
  -- characteristic-modifying or triggered -- Curse of Death's Hold, Curse of
  -- Conformity, Overwhelming Splendor, Trespasser's Curse and the rest. Nothing
  -- printed hands control over through the enchanted player. Curse of Death's
  -- Hold would refute this the moment its text said "you control" instead of
  -- "get -1/-1".
  --
  -- Gameplay-level, and over two card types: bob's Piker moves and so does his
  -- Forest, which is what "all permanents" says and a creature-only filter could
  -- not show. CR 302.6: the Piker settles under bob first, so only alice's own
  -- untap step lets her attack with it.
  --
  -- THREE SEATS, because the set is "enchanted player controls" and a two-player
  -- board collapses that onto "not the Aura's controller": carol's own Piker is
  -- what a set that dropped the controller conjunct would sweep up too.
  Spec.it s "CR 613.1b/303.4m a static grant reached through the enchanted player hands over every permanent they control" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    forest <- S.printingOf s registry "Forest"
    yoke <- S.printingOf s registry "Synthetic Puppeteer's Yoke"
    let (creature, withCreature) = S.addPermanent piker S.bob S.threePlayerGame
        (land, withLand) = S.addPermanent forest S.bob withCreature
        (hers, withHers) = S.addPermanent piker S.carol withLand
        his = S.runPure S.identityAnswer withHers (Engine.settleAll S.bob)
        (aura, withAura) = S.addPermanent yoke S.alice his
        yoked = S.attachTo aura (Recipient.ToPlayer S.bob) withAura
        settled = S.runPure S.identityAnswer yoked (Engine.settleAll S.alice)
        gone = S.runPure S.identityAnswer settled (Event.changeZone (pure ()) aura Zone.Graveyard)
    Spec.assertBool s (Combat.canAttack S.alice creature settled) "alice attacks with the creature the enchanted player owns"
    Spec.assertEqWith s "his Forest is hers too -- permanents, not creatures -- and carol's Piker is nobody's business" (fmap (\oid -> Projection.controllerOf oid settled) [land, hers]) [Just S.alice, Just S.carol]
    Spec.assertEqWith s "CR 604.2: the Yoke leaves and bob has his Piker back" (Projection.controllerOf creature gone) (Just S.bob)
  -- CR 613.8a/613.8b the other way round: a steal that hands carol's Piker TO
  -- the enchanted player changes what the Yoke applies to, so the Yoke waits
  -- for it even though it is older, and then takes the Piker. In timestamp
  -- order alone the Yoke would apply first, find the Piker carol's, and leave
  -- it to the steal. The steal is a stored layer-2 effect with its own
  -- timestamp, as an Act of Treason bob cast would leave.
  Spec.it s "CR 613.8b a permanent stolen for the enchanted player after the Yoke is handed over" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    forest <- S.printingOf s registry "Forest"
    yoke <- S.printingOf s registry "Synthetic Puppeteer's Yoke"
    let (creature, withCreature) = S.addPermanent piker S.carol S.threePlayerGame
        (_, withLand) = S.addPermanent forest S.bob withCreature
        (aura, withAura) = S.addPermanent yoke S.alice withLand
        stolen = S.giveControl creature S.bob (S.attachTo aura (Recipient.ToPlayer S.bob) withAura)
    Spec.assertEqWith s "alice controls carol's Piker" (Projection.controllerOf creature stolen) (Just S.alice)
  -- CR 704.5m's remaining clause, and the one only an enchant-player Aura can
  -- reach: CR 303.4c spells it out as "the player it was attached to has left
  -- the game". Three seats, because CR 104.2a ends a two-player game the
  -- moment anyone leaves and no state-based action would ever be checked
  -- again.
  Spec.it s "CR 704.5m / 303.4c: a Curse attached to a player who has left the game is put into its owner's graveyard" $ do
    curse <- S.printingOf s registry "Curse of Death's Hold"
    let (aura, withAura) = S.addPermanent curse S.alice S.threePlayerGame
        attached = S.attachTo aura (Recipient.ToPlayer S.carol) withAura
        before = S.settleSba attached
        departed = S.departs Departure.Type.Conceded S.carol before
        after = S.settleSba departed
    Spec.assertBool s (Set.member aura (GameState.battlefield before)) "while carol is in the game the Curse is legally attached"
    Spec.assertBool s (not (Set.member aura (GameState.battlefield after))) "she leaves, and it is off the battlefield after one pass"
    Spec.assertEqWith s "in its OWNER's graveyard -- a put-into-graveyard, not a destruction" (length (Game.zoneMembers Zone.Graveyard S.alice after)) 1
  -- CR 702.5d's second sentence -- such Auras "can't target permanents and
  -- can't be attached to permanents" -- at the reattach door, and it needs no
  -- clause of its own: Crown of the Ages moves "target Aura attached to a
  -- creature", and CR 701.3a's AttachedTo reads the attachment for the OBJECT
  -- it names, which a player attachment does not name at all. So
  -- the Curse is not a legal target and there is nothing to refuse later.
  Spec.it s "CR 702.5d: a Curse attached to a player is not an Aura attached to a creature" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    curse <- S.printingOf s registry "Curse of Death's Hold"
    crown <- S.printingOf s registry "Crown of the Ages"
    let base = Setup.emptyGame S.bothPlayers
        (creature, g1) = S.addPermanent piker S.alice base
        (onCreature, g2) = S.addPermanent unholyStrength S.alice g1
        (onPlayer, g3) = S.addPermanent curse S.alice g2
        (crownId, g4) = S.addPermanent crown S.alice g3
        gs = S.attachTo onPlayer (Recipient.ToPlayer S.bob) (S.attach onCreature creature g4)
    case activatedTargetSlot crown of
      Nothing -> Spec.assertFailure s "the fixture wanted Crown of the Ages' one printed target slot"
      Just theSlot ->
        Spec.assertEqWith
          s
          "only the Aura on a creature is offered"
          (Target.legalRecipients StackObjectKind.Spell (Just S.alice) crownId theSlot gs)
          (Set.singleton (Recipient.ToObject onCreature))

-- Replenish {3}{W} Sorcery -- "Return all enchantment cards from your graveyard to
-- the battlefield. (Auras with nothing to enchant remain in your graveyard.)" (name,
-- cost, type line and Oracle text checked against api.scryfall.com). The
-- parenthetical is reminder text (CR 207.2) restating CR 303.4g, so the card
-- transcribes only the first sentence and the rules do the rest.
--
-- The pool's first producer of an Aura entering the battlefield by any means other
-- than resolving as an Aura spell, so the first card to reach CR 303.4f's host
-- choice in Parun.Engine.Event.changeZoneAttaching. Its effect is Rise of the Dark
-- Realms' shape one card type over.
replenishSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
replenishSpec s registry =
  let -- Eight Plains for a {3}{W} sorcery -- twice its cost, so a payment that taps
      -- one source at a time cannot fail for reasons of its own, on both boards
      -- below (the cast-gate vacuity trap).
      board plains replenish creatures buried =
        let withLands = S.landsFor plains S.alice 8 (Setup.emptyGame S.bothPlayers)
            step add (acc, g) printing = let (oid, g2) = add printing S.alice g in (acc <> [oid], g2)
            (creatureIds, withCreatures) = List.foldl' (step S.addPermanent) ([], withLands) creatures
            (buriedIds, withBuried) = List.foldl' (step S.addGraveyardCard) ([], withCreatures) buried
            (ready, spell) = S.handOne replenish withBuried
         in (spell, creatureIds, buriedIds, ready)
      -- Cast, resolve, and take one CR 704.3 pass, so an Aura that entered
      -- unattached has actually been buried by CR 704.5m before anything looks. The
      -- responses come back beside the board, so one call answers both "what
      -- happened" and "who was asked".
      run :: (forall r. Prompt.Prompt r -> r) -> ObjectId.ObjectId -> GameState.GameState -> (GameState.GameState, [Response.Response])
      run answer spell gs =
        let ((_, resolved), responses) = Replay.record answer gs (S.cast S.alice spell >> Stack.resolveTop)
         in (S.settleSba resolved, responses)
      hostsChosen responses = length (Maybe.mapMaybe (\response -> case response of Response.ChoseAttachment _ -> Just (); _ -> Nothing) responses)
      -- Which card is on this host, read through attachedTo: CR 400.7 minted a
      -- fresh id at the destination, so the Aura cannot be named by the id it was
      -- buried under.
      auraOn host gs = fmap (\oid -> Game.cardOf oid gs) (attachedTo host gs)
      copiesOn printing gs =
        length (filter (\oid -> Game.cardOf oid gs == Just (Printing.card printing)) (Set.toList (GameState.battlefield gs)))
      nth n candidates = case drop (n - 1) (NonEmpty.toList candidates) of
        x : _ -> x
        [] -> NonEmpty.head candidates
   in Spec.describe s "Replenish" $ do
        -- CR 303.4f. THREE creatures for TWO Auras, so the prompt cannot pass by
        -- short-circuiting (Attach.chooseHost elides at one candidate), and the two
        -- Auras are pinned to DIFFERENT candidates so neither answer can stand in
        -- for the other's.
        Spec.it s "CR 303.4f each returned Aura's controller chooses what it enchants" $ do
          plains <- S.printingOf s registry "Plains"
          replenish <- S.printingOf s registry "Replenish"
          unholy <- S.printingOf s registry "Unholy Strength"
          pacifism <- S.printingOf s registry "Pacifism"
          piker <- S.printingOf s registry "Goblin Piker"
          mammoth <- S.printingOf s registry "War Mammoth"
          maiden <- S.printingOf s registry "Bird Maiden"
          let (spell, creatureIds, buriedIds, gs) = board plains replenish [piker, mammoth, maiden] [unholy, pacifism]
          case (creatureIds, buriedIds) of
            ([pikerId, mammothId, maidenId], [unholyId, pacifismId]) -> do
              -- Pinned BY THE SUBJECT the prompt names, which is the Aura's
              -- GRAVEYARD incarnation: CR 303.4f's choice is made as it enters, so
              -- before the CR 400.7 move. Pinned by INDEX, never by searching for a
              -- legal option, so no mutation can let the answerer repair the
              -- assertion. Attach.hostsFor sorts ascending, and the creatures went
              -- in in this order, so candidate 2 is the Mammoth and 3 the Maiden.
              let choosing :: Prompt.Prompt r -> r
                  choosing p = case p of
                    Prompt.ChooseAttachment _ _ subject offered
                      | subject == unholyId -> nth 2 offered
                      | subject == pacifismId -> nth 3 offered
                    _ -> S.castAnswer p
                  (after, responses) = run choosing spell gs
              Spec.assertEqWith s "both Auras' controllers were asked" (hostsChosen responses) 2
              Spec.assertEqWith s "Unholy Strength enchants the creature its own answer named" (auraOn mammothId after) [Just (Printing.card unholy)]
              Spec.assertEqWith s "and Pacifism the creature its answer named" (auraOn maidenId after) [Just (Printing.card pacifism)]
              Spec.assertEqWith s "nothing landed on the first candidate" (auraOn pikerId after) []
              -- The choice is made AS the Aura enters, so a state-based pass leaves
              -- both alone and the bonus is already applying -- which is what proves
              -- the attachment is real rather than a field nothing reads.
              Spec.assertEqWith s "the Piker is a plain 2/1" (S.powerToughnessOf pikerId after) (Just (2, 1))
              Spec.assertEqWith s "the Mammoth is 3/3 plus Unholy Strength's +2/+1" (S.powerToughnessOf mammothId after) (Just (5, 4))
              Spec.assertEqWith s "and Pacifism, which changes no characteristic, leaves the Maiden 1/2" (S.powerToughnessOf maidenId after) (Just (1, 2))
            _ -> Spec.assertFailure s "the board should hold three creatures and two graveyard cards"
        -- The paired control, and the whole reason there are three creatures: the
        -- same cast on the same board with an answerer that takes every FIRST
        -- candidate. If the engine were picking the host, the two legs could not
        -- disagree.
        Spec.it s "CR 303.4f the engine does not pick: another answer puts both Auras elsewhere" $ do
          plains <- S.printingOf s registry "Plains"
          replenish <- S.printingOf s registry "Replenish"
          unholy <- S.printingOf s registry "Unholy Strength"
          pacifism <- S.printingOf s registry "Pacifism"
          piker <- S.printingOf s registry "Goblin Piker"
          mammoth <- S.printingOf s registry "War Mammoth"
          maiden <- S.printingOf s registry "Bird Maiden"
          let (spell, creatureIds, _, gs) = board plains replenish [piker, mammoth, maiden] [unholy, pacifism]
          case creatureIds of
            [pikerId, mammothId, maidenId] -> do
              let takingFirst :: Prompt.Prompt r -> r
                  takingFirst p = case p of
                    Prompt.ChooseAttachment _ _ _ offered -> NonEmpty.head offered
                    _ -> S.castAnswer p
                  (after, responses) = run takingFirst spell gs
              Spec.assertEqWith s "both controllers were asked here too" (hostsChosen responses) 2
              Spec.assertEqWith s "both Auras went onto the first candidate" (List.sort (auraOn pikerId after)) (List.sort [Just (Printing.card unholy), Just (Printing.card pacifism)])
              Spec.assertEqWith s "the Mammoth has none" (auraOn mammothId after) []
              Spec.assertEqWith s "the Maiden has none" (auraOn maidenId after) []
              Spec.assertEqWith s "and the Piker carries the +2/+1 instead" (S.powerToughnessOf pikerId after) (Just (4, 2))
            _ -> Spec.assertFailure s "the board should hold three creatures"
        -- CR 303.4g's "remains in its current zone". ONE board, TWO enchantment
        -- cards: the non-Aura comes back and the Aura does not, so the same
        -- resolution proves the effect ran and that the Aura was left alone.
        --
        -- The DISCRIMINATOR is the ObjectId, not the zone. "Remains in the
        -- graveyard" and "was put into its owner's graveyard by CR 704.5m" are the
        -- same zone on this board, so no zone assertion can tell them apart. A
        -- completed move deletes the old id and mints a new one (CR 400.7), so an
        -- Aura that entered and was buried has NO object under its original id while
        -- one that never moved still does. The rule's TOKEN clause is asked in the
        -- AuraToken group below, over Preston Garvey, Minuteman, and its STACK
        -- branch in Parun.CopySpec, over Copy Enchantment copying Betrayal.
        Spec.it s "CR 303.4g an Aura with nothing to enchant never leaves the graveyard" $ do
          plains <- S.printingOf s registry "Plains"
          replenish <- S.printingOf s registry "Replenish"
          unholy <- S.printingOf s registry "Unholy Strength"
          scales <- S.printingOf s registry "Hardened Scales"
          -- NO creatures: Unholy Strength's enchant pool is Creatures, so its legal
          -- host set is empty and alice's Plains are the only permanents.
          let (spell, _, buriedIds, gs) = board plains replenish [] [unholy, scales]
          case buriedIds of
            [auraId, _] -> do
              let (after, responses) = run S.castAnswer spell gs
              Spec.assertEqWith s "nobody was asked -- there was nothing to choose" (hostsChosen responses) 0
              Spec.assertEqWith s "the Aura is the same object it always was, still in the graveyard" (fmap Object.zone (Game.lookupObject auraId after)) (Just Zone.Graveyard)
              Spec.assertEqWith s "and no Aura reached the battlefield" (copiesOn unholy after) 0
              Spec.assertEqWith s "while the non-Aura enchantment did come back, so the effect really ran" (copiesOn scales after) 1
            _ -> Spec.assertFailure s "the board should hold two graveyard cards"
        -- THE PROVING TEST for #1738, and the CR 303.4f half of it. CR 608.2f makes
        -- Replenish's return ONE event, so each Aura's host choice is made against
        -- the board the batch began on -- where a would-be host returned in the
        -- same batch is not on the battlefield at all. Master of the Feast is that
        -- would-be host: an enchantment card, so Replenish returns it, and a
        -- creature, so Unholy Strength's "enchant creature" would admit it.
        --
        -- NO creature on the battlefield, which is what makes the board
        -- discriminate: one already there would be a legal host under both
        -- readings, and every assertion below would pass either way.
        --
        -- TWO LEGS in the two sweep orders, because visibility of a sibling
        -- inherently depends on which member moved first: Resolve.graveyardCardsOf
        -- sorts ascending ObjectId and S.addGraveyardCard mints in call order, so
        -- the `buried` list pins the order exactly. The per-object reading answers
        -- differently in the two orders and CR 608.2f says it may not, so the legs
        -- must AGREE.
        --
        -- The prompt count is deliberately not the evidence: Attach.chooseHost
        -- elides at one candidate, so nobody is asked under either reading. The
        -- gameplay-level quantity is the host's power and toughness, and the zone
        -- is read through the Aura's ORIGINAL ObjectId -- "remains in the
        -- graveyard" (CR 303.4g) and "entered and was buried" (CR 704.5m) are the
        -- same zone, and only the surviving id separates them (CR 400.7), exactly
        -- as the case above argues.
        Spec.it s "CR 608.2f a returned Aura cannot enchant a permanent returned beside it (#1738)" $ do
          plains <- S.printingOf s registry "Plains"
          replenish <- S.printingOf s registry "Replenish"
          unholy <- S.printingOf s registry "Unholy Strength"
          master <- S.printingOf s registry "Master of the Feast"
          let outcome buried =
                let (spell, _, buriedIds, gs) = board plains replenish [] buried
                    (after, responses) = run S.castAnswer spell gs
                    -- The Aura's GRAVEYARD id, whichever slot of the batch it took.
                    auraId = Maybe.listToMaybe (fmap fst (filter (\(_, printing) -> Printing.card printing == Printing.card unholy) (zip buriedIds buried)))
                    -- By CARD: CR 400.7 minted a fresh id at the battlefield.
                    masterNew = List.find (\oid -> Game.cardOf oid after == Just (Printing.card master)) (Set.toList (GameState.battlefield after))
                 in ( fmap (`S.powerToughnessOf` after) masterNew,
                      fmap (\oid -> fmap Object.zone (Game.lookupObject oid after)) auraId,
                      copiesOn unholy after,
                      hostsChosen responses
                    )
              hostFirst = outcome [master, unholy]
              auraFirst = outcome [unholy, master]
          Spec.assertEqWith
            s
            "the host came back a plain 5/5, the Aura is the same object still in the graveyard, and nobody was asked"
            hostFirst
            (Just (Just (5, 5)), Just (Just Zone.Graveyard), 0, 0)
          Spec.assertEqWith
            s
            "and the batch's processing order changes nothing (CR 608.2f)"
            auraFirst
            hostFirst
        -- CR 303.4f's "a legal object OR PLAYER", with CR 702.5d: Replenish
        -- returns Curse of Death's Hold ("Enchant player. Creatures enchanted
        -- player controls get -1/-1."), and its controller picks the player.
        -- Three seats, answered by INDEX at the third, so neither alice (the
        -- first candidate) nor bob can stand in for carol.
        Spec.it s "CR 303.4f a returned Curse's controller chooses the player it enchants" $ do
          plains <- S.printingOf s registry "Plains"
          replenish <- S.printingOf s registry "Replenish"
          curse <- S.printingOf s registry "Curse of Death's Hold"
          mammoth <- S.printingOf s registry "War Mammoth"
          maiden <- S.printingOf s registry "Bird Maiden"
          let withLands = S.landsFor plains S.alice 8 S.threePlayerGame
              (mammothId, withMammoth) = S.addPermanent mammoth S.bob withLands
              (maidenId, withMaiden) = S.addPermanent maiden S.carol withMammoth
              (_, withCurse) = S.addGraveyardCard curse S.alice withMaiden
              (gs, spell) = S.handOne replenish withCurse
              choosing :: Prompt.Prompt r -> r
              choosing p = case p of
                Prompt.ChoosePlayer _ _ _ offered -> nth 3 offered
                _ -> S.castAnswer p
              (after, _) = run choosing spell gs
          Spec.assertEqWith s "carol's Bird Maiden gets -1/-1" (S.powerToughnessOf maidenId after) (Just (0, 1))
          Spec.assertEqWith s "and bob's War Mammoth does not" (S.powerToughnessOf mammothId after) (Just (3, 3))
        -- The same choice for "Enchant opponent" (Archnemesis), whose offer
        -- leaves alice out, so it is Prompt.ChooseOpponent's; carol is the
        -- second of two.
        Spec.it s "CR 303.4f a returned enchant-opponent Aura's controller chooses the opponent" $ do
          plains <- S.printingOf s registry "Plains"
          replenish <- S.printingOf s registry "Replenish"
          archnemesis <- S.printingOf s registry "Archnemesis"
          let withLands = S.landsFor plains S.alice 8 S.threePlayerGame
              (_, withAura) = S.addGraveyardCard archnemesis S.alice withLands
              (gs, spell) = S.handOne replenish withAura
              choosing :: Prompt.Prompt r -> r
              choosing p = case p of
                Prompt.ChooseOpponent _ _ _ _ offered -> nth 2 offered
                _ -> S.castAnswer p
              (after, _) = run choosing spell gs
              hosts = [Game.lookupObject oid after >>= Object.attachedTo | oid <- Set.toList (GameState.battlefield after), Game.cardOf oid after == Just (Printing.card archnemesis)]
          Spec.assertEqWith s "Archnemesis enchants carol" hosts [Just (Recipient.ToPlayer S.carol)]
        -- CR 708.2a against CR 303.4f, on Soul Summons rather than Replenish: an
        -- Aura card MANIFESTED off a library (CR 701.40a) enters as a 2/2 with no
        -- subtypes and no enchant ability, so it is not an Aura the rule speaks
        -- about and nobody is asked -- even though the card is an Aura in the zone
        -- it is leaving, which is where the gate's projection reads. It enters
        -- unattached, and CR 704.5m leaves it alone because Sba.fallsOff reads the
        -- same substituted face.
        --
        -- The Piker is the whole point: it is a legal host for a face-UP Unholy
        -- Strength, so a gate that read the projection alone would find it and
        -- attach.
        Spec.it s "CR 708.2a a manifested Aura card is not an Aura, so nobody chooses a host" $ do
          plains <- S.printingOf s registry "Plains"
          summons <- S.printingOf s registry "Soul Summons"
          unholy <- S.printingOf s registry "Unholy Strength"
          piker <- S.printingOf s registry "Goblin Piker"
          mammoth <- S.printingOf s registry "War Mammoth"
          let (host, base0) = S.addPermanent piker S.alice (S.landsInPlay plains 2)
              -- TWO creatures, so Attach.chooseHost's one-candidate elision cannot
              -- make "nobody was asked" pass for the wrong reason.
              (host2, base1) = S.addPermanent mammoth S.alice base0
              -- A second library card keeps CR 104.3c off the board; Unholy Strength
              -- goes on top of it, so the manifest reaches the Aura.
              (_, base2) = S.addLibraryCard piker S.alice base1
              (_, base3) = S.addLibraryCard unholy S.alice base2
              (gs, spell) = S.handOne summons base3
              (after, responses) = run S.castAnswer spell gs
              -- By CARD, since CR 400.7 minted a fresh id at the destination.
              manifested = filter (\oid -> Game.cardOf oid after == Just (Printing.card unholy)) (Set.toList (GameState.battlefield after))
          Spec.assertEqWith s "nobody was asked -- a face-down permanent has no enchant ability" (hostsChosen responses) 0
          Spec.assertEqWith s "and it did not land on the Piker, which would have hosted it face up" (auraOn host after) []
          Spec.assertEqWith s "nor on the Mammoth" (auraOn host2 after) []
          case manifested of
            [oid] -> do
              Spec.assertEqWith s "the manifested card is on the battlefield, unattached" (fmap Object.attachedTo (Game.lookupObject oid after)) (Just Nothing)
              Spec.assertEqWith s "CR 708.2a as a 2/2, not Unholy Strength" (S.powerToughnessOf oid after) (Just (2, 2))
            _ -> Spec.assertFailure s "the manifest should have put Unholy Strength onto the battlefield"

-- Crime // Punishment: "Put target creature or enchantment card from an
-- opponent's graveyard onto the battlefield under your control." / "Destroy each
-- artifact, creature, and enchantment with mana value X." CR 303.4f's Aura
-- entering under a player who does not own it: alice takes bob's Archnemesis
-- ("Enchant opponent"), so CR 109.5's "you" on its enchant ability and CR
-- 702.16k's "Auras that player controls" are both alice, never bob, its owner.
--
-- A PAIR differing in bob's Absolute Virtue alone. Without it, bob is alice's
-- one opponent and the Aura enchants him; with it, he has protection from her,
-- so nothing is legal and CR 303.4g leaves the card where it was. Judged as
-- bob's, the Aura would go onto alice in both, and CR 704.5m would bury it.
crimeSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
crimeSpec s registry =
  let crime = CardName.MkCardName (Text.pack "Crime")
      punishment = CardName.MkCardName (Text.pack "Punishment")
      -- Eight lands for a {3}{W}{B} sorcery, for replenishSpec's reason.
      lands plains swamp = S.landsFor swamp S.alice 4 (S.landsFor plains S.alice 4 (Setup.emptyGame S.bothPlayers))
      -- Cast the named half, resolve, and take one CR 704.3 pass.
      run :: (forall r. Prompt.Prompt r -> r) -> CardName.CardName -> ObjectId.ObjectId -> GameState.GameState -> GameState.GameState
      run answer half spell gs =
        S.settleSba (snd (Engine.runGamePure answer gs (Cast.castSpell S.manaPerformer S.alice spell half Facing.FaceUp >> Stack.resolveTop)))
      archnemesisBoard withVirtue = do
        plains <- S.printingOf s registry "Plains"
        swamp <- S.printingOf s registry "Swamp"
        card <- S.printingOf s registry "Crime"
        archnemesis <- S.printingOf s registry "Archnemesis"
        virtue <- S.printingOf s registry "Absolute Virtue"
        let base = lands plains swamp
            guarded = if withVirtue then snd (S.addPermanent virtue S.bob base) else base
            (auraId, withAura) = S.addGraveyardCard archnemesis S.bob guarded
            (gs, spell) = S.handOne card withAura
            after = run S.castAnswer crime spell gs
            returned = filter (\oid -> Game.cardOf oid after == Just (Printing.card archnemesis)) (Set.toList (GameState.battlefield after))
        pure (auraId, spell, returned, after)
   in Spec.describe s "Crime // Punishment" $ do
        Spec.it s "CR 303.4f bob's Archnemesis enters under alice enchanting bob, her opponent" $ do
          (_, _, returned, after) <- archnemesisBoard False
          Spec.assertEqWith s "Archnemesis enchants bob" (fmap (\oid -> Game.lookupObject oid after >>= Object.attachedTo) returned) [Just (Recipient.ToPlayer S.bob)]
          Spec.assertEqWith s "and alice controls it" (fmap (`Projection.controllerOf` after) returned) [Just S.alice]
        -- The ObjectId is the discriminator, for replenishSpec's CR 303.4g reason:
        -- "remains in its current zone" and "entered and was buried" are the same
        -- zone, and only a move mints a new id (CR 400.7).
        Spec.it s "CR 303.4g / 702.16k with bob protected from alice, Archnemesis never leaves his graveyard" $ do
          (auraId, spell, returned, after) <- archnemesisBoard True
          Spec.assertEqWith s "the Aura is the same object it always was, still in bob's graveyard" (fmap Object.zone (Game.lookupObject auraId after)) (Just Zone.Graveyard)
          Spec.assertEqWith s "and no Archnemesis reached the battlefield" returned []
          Spec.assertBool s (Maybe.isNothing (Game.lookupObject spell after)) "while Crime did resolve and leave the stack"
        Spec.it s "CR 107.3 Punishment with X 2 destroys the 2-mana creature and spares the 4-mana one" $ do
          swamp <- S.printingOf s registry "Swamp"
          forest <- S.printingOf s registry "Forest"
          card <- S.printingOf s registry "Punishment"
          bears <- S.printingOf s registry "Grizzly Bears"
          mammoth <- S.printingOf s registry "War Mammoth"
          let base = S.landsFor forest S.alice 4 (S.landsFor swamp S.alice 4 (Setup.emptyGame S.bothPlayers))
              (bearsId, withBears) = S.addPermanent bears S.bob base
              (mammothId, withMammoth) = S.addPermanent mammoth S.bob withBears
              (gs, spell) = S.handOne card withMammoth
              answer :: Prompt.Prompt r -> r
              answer p = case p of
                Prompt.ChooseX {} -> 2
                _ -> S.castAnswer p
              after = run answer punishment spell gs
          Spec.assertBool s (not (Set.member bearsId (GameState.battlefield after))) "Grizzly Bears is destroyed"
          Spec.assertBool s (Set.member mammothId (GameState.battlefield after)) "War Mammoth is not"

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Parun.Engine.Aura" $ do
  auraSpec s registry
  equipmentSpec s registry
  fortificationSpec s registry
  unattachableSpec s registry
  reattachSpec s registry
  auraGraftSpec s registry
  miracleWorkerSpec s registry
  enchantPlayerSpec s registry
  replenishSpec s registry
  crimeSpec s registry
  attachRestrictionSpec s registry
  bestowSpec s registry
  licidSpec s registry
  auraTextChangeSpec s registry
  equipmentTokenSpec s registry
  auraTokenSpec s registry
  animateDeadSpec s registry
  groupAttachSpec s registry
  groupAttachCardsSpec s registry
  auraSwapSpec s registry

-- Answers every target slot with one fixed recipient, deferring everything else
-- to S.identityAnswer. aimAt above does the same for a Pool.Permanents slot
-- only, because it hard-codes Recipient.ToObject; these cases mix a
-- Pool.Creatures slot (Unholy Strength's enchant) with a Pool.Permanents one
-- (Crown of the Ages' "target Aura"), and a recipient tagged for the wrong pool
-- is not in the legal set at all.
aimRecipient :: Recipient.Recipient -> Prompt.Prompt r -> r
aimRecipient recipient p = case p of
  Prompt.ChooseTargets _ _ _ sets -> fmap (const (Set.singleton recipient)) sets
  _ -> S.identityAnswer p

-- Answers Prompt.ChooseAttachment with one fixed object -- the destination an
-- attach-moving effect picks on resolution (CR 701.3a). Discriminating where
-- S.identityAnswer's head-of-candidates would not be: these boards deliberately
-- offer several.
destination :: ObjectId.ObjectId -> Prompt.Prompt r -> r
destination oid p = case p of
  Prompt.ChooseAttachment {} -> oid
  _ -> S.identityAnswer p

-- What every attached battlefield permanent is attached to. The whole-board read
-- an Aura test wants when the id it would look up is not the one it holds: CR
-- 400.7 mints a fresh id for the battlefield incarnation of a resolved Aura
-- spell.
attachments :: GameState.GameState -> [Maybe Recipient.Recipient]
attachments gs =
  fmap
    Object.attachedTo
    (filter (\o -> Object.zone o == Zone.Battlefield && Maybe.isJust (Object.attachedTo o)) (Map.elems (GameState.objects gs)))

-- The battlefield permanents attached to `host`. How a test finds the Aura a
-- resolved Aura SPELL entered as: CR 400.7 mints a fresh id for the battlefield
-- incarnation, so the spell's own id names nothing afterwards.
--
-- Compared through Recipient.objectOf rather than against a fixed tag, because
-- the tag is the enchant slot's, not the host's: a Pool.Creatures slot stores
-- ToCreature and Convincing Mirage's Pool.Permanents slot stores ToObject. This
-- read only wants to know WHICH object is named, which is exactly the question
-- Affected.Attached asks (Parun.Engine.Projection.affects).
attachedTo :: ObjectId.ObjectId -> GameState.GameState -> [ObjectId.ObjectId]
attachedTo host gs =
  filter
    (\oid -> (Game.lookupObject oid gs >>= Object.attachedTo >>= Recipient.objectOf) == Just host)
    (Set.toList (GameState.battlefield gs))

-- The slot named "target" on a card's FIRST printed activated ability -- the
-- committed declaration, not a restatement of it, so a test asserting what it admits
-- is asserting what the card really says. Crown of the Ages and Miracle Worker are
-- the two callers, each printing exactly one such ability.
activatedTargetSlot :: Printing.Printing -> Maybe TargetSlot.TargetSlot
activatedTargetSlot printing = case Face.activatedAbilities (S.combinedFace printing) of
  ability : _ -> Map.lookup (SlotName.MkSlotName (Text.pack "target")) (Modal.allTargetSlots (ActivatedAbility.modal ability))
  [] -> Nothing

-- Answers Prompt.ChooseTargets by FILTERING the offered set down to the recipients
-- that name one object, rather than constructing a recipient of its own: a
-- hand-built Recipient.ToObject the pool never offered is dropped by CR 608.2b's
-- re-read at resolution with no error, which is how a targeting test goes green
-- and empty.
aimAtOffered :: ObjectId.ObjectId -> Prompt.Prompt r -> r
aimAtOffered oid p = case p of
  Prompt.ChooseTargets _ _ _ sets -> fmap (Set.filter ((==) (Just oid) . Recipient.objectOf) . snd) sets
  _ -> S.identityAnswer p

-- CR 701.3 Attach, aimed at the effect's TARGET rather than at its source: an
-- opcode that moves an Aura already on the battlefield, which the Auras unit left
-- unbuilt. Crown of the Ages is the proving card -- "{4}, {T}: Attach target Aura
-- attached to a creature to another creature".
reattachSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
reattachSpec s registry = Spec.describe s "Reattach" $ do
  -- CR 303.4b through the target slot: "target Aura ATTACHED TO A CREATURE"
  -- is Pool.Permanents narrowed by `And [HasSubtype Aura, AttachedTo (HasCardType
  -- Creature)]`, so the narrowing has to do real work. The same Aura is offered when it
  -- sits on the Piker and withheld when it sits on a Mountain -- nothing
  -- about the Aura itself differs between the two boards, which is what makes
  -- the pair discriminating.
  --
  -- An Aura on a noncreature permanent is hand-built here, as the CR 704.5p
  -- land case above hand-builds its attachment: CR 704.5m would bury such an
  -- Aura on the next state-based-action pass, so no sequence of card plays
  -- leaves one standing for a player to look at.
  Spec.it s "CR 303.4b Crown of the Ages offers an Aura on a creature and not one on a land" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    crown <- S.printingOf s registry "Crown of the Ages"
    let base = Setup.emptyGame S.bothPlayers
        (creature, g1) = S.addPermanent piker S.alice base
        (land, g2) = S.addPermanent mountain S.alice g1
        (aura, g3) = S.addPermanent unholyStrength S.alice g2
        (crownObj, g4) = S.addPermanent crown S.alice g3
        onCreature = S.attach aura creature g4
        onLand = S.attach aura land g4
        offered gs = fmap (\theSlot -> Target.legalRecipients StackObjectKind.Spell (Just S.alice) crownObj theSlot gs) (activatedTargetSlot crown)
        admits oid gs = fmap (Set.member (Recipient.ToObject oid)) (offered gs)
    Spec.assertEqWith s "on the Piker the Aura is a legal target" (admits aura onCreature) (Just True)
    Spec.assertEqWith s "on the Mountain it is not" (admits aura onLand) (Just False)
    -- Not vacuous for a second reason: the slot rejects the Crown itself on
    -- the very board where it accepts the Aura.
    Spec.assertEqWith s "and the Crown is never a candidate" (admits crownObj onCreature) (Just False)
  -- CR 303.4j: "If an effect attempts to attach an Aura on the battlefield to
  -- an object or player it can't legally enchant, the Aura doesn't move." A
  -- FAILURE MODE, not a fizzle: the ability resolved, and the only thing that
  -- did not happen is the move.
  --
  -- The case where the destination is not a CREATURE at all, which no card in
  -- the pool reaches. Crown of the Ages' destination filter is HasCardType
  -- Creature, so every destination it can offer is at least a creature; Aura
  -- Graft's is Filter.CanHostSubject, so every destination IT can offer is one
  -- the Aura may legally enchant, and this rule's refusal never fires for it.
  -- The opcode is driven directly with a wider, hand-made filter instead -- the
  -- same way the Effect.Attach cases in the Equipment group above drive that
  -- opcode -- and that synthetic filter is the labeled crutch (#431). The
  -- rule's other case, a destination the Aura's own enchant restriction
  -- rejects, is data/scenarios/aura's Setessan Training pair.
  Spec.it s "CR 303.4j attaching an Aura to something it cannot enchant leaves it where it was" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    crown <- S.printingOf s registry "Crown of the Ages"
    let base = Setup.emptyGame S.bothPlayers
        (first, g1) = S.addPermanent piker S.alice base
        (land, g2) = S.addPermanent mountain S.alice g1
        (aura, g3) = S.addPermanent unholyStrength S.alice g2
        (crownObj, g4) = S.addPermanent crown S.alice g3
        gs = S.attach aura first g4
        slot = SlotName.MkSlotName (Text.pack "target")
        after =
          S.runPure (destination land) gs $
            Resolve.applyEffect
              crownObj
              crownObj
              S.alice
              (Map.singleton slot (Set.singleton (Recipient.ToObject aura)))
              (Map.singleton slot (Set.singleton (Recipient.ToObject aura)))
              -- `And []` matches everything, so the land is offered as a
              -- destination and CR 303.4j is what rejects it.
              (Effect.AttachTarget (AttachTarget.MkAttachTarget slot (Filter.Type.And [])))
        stampOf g = fmap Object.timestamp (Game.lookupObject aura g)
        settled = S.settleSba (S.settleSba after)
    Spec.assertEqWith s "the Aura did not move onto the land" (fmap Object.attachedTo (Game.lookupObject aura after)) (Just (Just (Recipient.ToCreature first)))
    Spec.assertEqWith s "and was not restamped" (stampOf after) (stampOf gs)
    Spec.assertEqWith s "the Piker still has the bonus" (S.powerToughnessOf first after) (Just (4, 2))
    -- CR 704.5m: a failed move must not leave the Aura in a state the
    -- state-based actions then punish -- it is still on a legal host.
    Spec.assertBool s (Set.member aura (GameState.battlefield settled)) "and the Aura is not buried afterwards"

-- CR 303.4e's half of the CR 701.3 Attach work: an effect that changes the AURA's
-- own controller and moves it in one resolution. Aura Graft is the proving card --
-- "Gain control of target Aura that's attached to a permanent. Attach it to
-- another permanent it can enchant" -- and each of its three clauses is a
-- different thing from Crown of the Ages' above.
--
-- "target Aura THAT'S ATTACHED TO A PERMANENT" is wider than the Crown's "attached
-- to a creature" and narrower than "attached to anything": CR 303.4 attaches an
-- Aura to "an object or player", so an enchant-player Aura is out.
--
-- "another permanent IT CAN ENCHANT" is a destination restriction the card states
-- in its own text, and it asks about the SUBJECT's enchant ability rather than
-- about the candidate -- Filter.CanHostSubject. Not the same thing as CR 303.4j,
-- which is the backstop for a card that does NOT say it: the Crown offers a
-- creature its Aura may not enchant and the move then fails, where Aura Graft may
-- not offer one at all. The pair of cards is what keeps the two apart.
auraGraftSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
auraGraftSpec s registry = Spec.describe s "AuraGraft" $ do
  -- "target Aura THAT'S ATTACHED TO A PERMANENT" (CR 601.2c), spelled
  -- `And [HasSubtype Aura, AttachedTo (And [])]` -- the TRIVIAL nest, which is
  -- what makes "attached to a permanent" fall out of the general atom: the host
  -- view is filled only for an object on the battlefield (CR 110.1), so the nest
  -- has nothing left to say. Three boundaries at once,
  -- all four Auras on one board: an Aura on a noncreature permanent is in --
  -- which is what makes the trivial nest wider than the Crown's
  -- `AttachedTo (HasCardType Creature)` --
  -- an Aura on a PLAYER is out (CR 303.4: an Aura is attached to "an object or
  -- player", and only one of those is a permanent), and an unattached one is
  -- out.
  --
  -- The Aura on a land is hand-built, as the Crown's own filter test above
  -- hand-builds one: CR 704.5m would bury it on the next state-based-action
  -- pass, so no sequence of card plays leaves one standing to be targeted.
  Spec.it s "CR 601.2c Aura Graft targets an Aura on any permanent, where Crown of the Ages needs one on a creature" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    curse <- S.printingOf s registry "Curse of Death's Hold"
    crown <- S.printingOf s registry "Crown of the Ages"
    auraGraft <- S.printingOf s registry "Aura Graft"
    let base = Setup.emptyGame S.bothPlayers
        (creature, g1) = S.addPermanent piker S.alice base
        (land, g2) = S.addPermanent mountain S.alice g1
        (onCreature, g3) = S.addPermanent unholyStrength S.alice g2
        (onLand, g4) = S.addPermanent unholyStrength S.alice g3
        (loose, g5) = S.addPermanent unholyStrength S.alice g4
        (onPlayer, g6) = S.addPermanent curse S.alice g5
        (crownId, g7) = S.addPermanent crown S.alice g6
        (gs, graft) = S.handOne auraGraft g7
        attached =
          S.attachTo onPlayer (Recipient.ToPlayer S.bob) $
            S.attach onLand land (S.attach onCreature creature gs)
        graftOffers oid = fmap (Set.member (Recipient.ToObject oid) . (\theSlot -> Target.legalRecipients StackObjectKind.Spell (Just S.alice) graft theSlot attached)) (S.spellTargetSlot auraGraft)
        crownOffers oid = fmap (Set.member (Recipient.ToObject oid) . (\theSlot -> Target.legalRecipients StackObjectKind.Spell (Just S.alice) crownId theSlot attached)) (activatedTargetSlot crown)
    Spec.assertEqWith s "an Aura on a creature is a legal target" (graftOffers onCreature) (Just True)
    Spec.assertEqWith s "and so is one on a land" (graftOffers onLand) (Just True)
    -- The pair that makes the trivial nest do work the Crown's creature nest
    -- cannot: one board, one Aura, two cards, two answers.
    Spec.assertEqWith s "which Crown of the Ages will not have" (crownOffers onLand) (Just False)
    Spec.assertEqWith s "an Aura on a PLAYER is not attached to a permanent" (graftOffers onPlayer) (Just False)
    Spec.assertEqWith s "nor is an unattached one" (graftOffers loose) (Just False)
    -- Not vacuous: the Graft's own slot rejects a permanent that is not an Aura
    -- at all on the very board where it accepts three that are.
    Spec.assertEqWith s "and a plain creature is not an Aura" (graftOffers creature) (Just False)
  -- The window CR 704.3 leaves open between a host leaving and the pass that
  -- buries the Aura (CR 704.5m): the attachment is still recorded, and it
  -- still names an object, but that object is no longer on the battlefield --
  -- and CR 110.1 makes only a battlefield object a permanent. So "attached to
  -- a permanent" is False, and the atom has to read the battlefield rather
  -- than stopping at the stored recipient.
  --
  -- Not reachable while a player holds priority, because CR 704.3 runs the
  -- pass first -- which is exactly why the state has to be built by hand here.
  Spec.it s "CR 110.1 an Aura whose host has left the battlefield is not attached to a permanent" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    auraGraft <- S.printingOf s registry "Aura Graft"
    let base = Setup.emptyGame S.bothPlayers
        (creature, g1) = S.addPermanent piker S.alice base
        (aura, g2) = S.addPermanent unholyStrength S.alice g1
        (gs, graft) = S.handOne auraGraft (S.attach aura creature g2)
        bounced = S.runPure S.identityAnswer gs (Event.changeZone (pure ()) creature Zone.Hand)
        offers g = fmap (Set.member (Recipient.ToObject aura) . (\theSlot -> Target.legalRecipients StackObjectKind.Spell (Just S.alice) graft theSlot g)) (S.spellTargetSlot auraGraft)
    Spec.assertEqWith s "while the Piker is there the Aura is a legal target" (offers gs) (Just True)
    -- CR 400.7 minted a new object in the hand, so the recipient the Aura
    -- still holds names an id nothing on the battlefield answers to.
    Spec.assertBool s (Maybe.isJust (Game.lookupObject aura bounced >>= Object.attachedTo)) "the Aura is still attached to the old id"
    Spec.assertEqWith s "but it is no longer attached to a PERMANENT" (offers bounced) (Just False)

-- Miracle Worker, "{T}: Destroy target Aura attached to a creature you control",
-- which is the first card in the pool whose attachment narrowing COMPOSES with a
-- quality: `And [HasSubtype Aura, AttachedTo (And [HasCardType Creature,
-- HeldBy Controller You])]`. No nullary atom expresses it, which is what the general
-- Filter.AttachedTo is for.
--
-- CR 109.5 is the rule the composition rests on: "you" inside the nest is the
-- player who ACTIVATED the ability, not the host's own controller and not the
-- Aura's, so the nest is evaluated against the host's view and the OUTER context.
miracleWorkerSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
miracleWorkerSpec s registry = Spec.describe s "MiracleWorker" $ do
  -- The target slot, read off the printed ability. BOTH Auras are alice's and both
  -- hosts are creatures, so the only axis that varies is the HOST's controller --
  -- which is what rules out the misreading "an Aura YOU control", under which the
  -- two answers would agree. Crown of the Ages asks the same question without the
  -- control conjunct and offers what the Worker refuses, on the same board, which
  -- is what rules out a negative passing for an unrelated legality.
  --
  -- The Aura on a land is hand-built, as the Crown's and the Graft's own filter
  -- tests hand-build theirs: CR 704.5m would bury it on the next
  -- state-based-action pass.
  Spec.it s "CR 109.5 Miracle Worker offers an Aura on your creature and not one on theirs" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    mountain <- S.printingOf s registry "Mountain"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    crown <- S.printingOf s registry "Crown of the Ages"
    worker <- S.printingOf s registry "Miracle Worker"
    let base = Setup.emptyGame S.bothPlayers
        (mine, g1) = S.addPermanent piker S.alice base
        (theirs, g2) = S.addPermanent piker S.bob g1
        (myLand, g3) = S.addPermanent mountain S.alice g2
        (onMine, g4) = S.addPermanent unholyStrength S.alice g3
        (onTheirs, g5) = S.addPermanent unholyStrength S.alice g4
        (onLand, g6) = S.addPermanent unholyStrength S.alice g5
        (loose, g7) = S.addPermanent unholyStrength S.alice g6
        (workerId, g8) = S.addPermanent worker S.alice g7
        (crownId, g9) = S.addPermanent crown S.alice g8
        board =
          S.attach onLand myLand $
            S.attach onTheirs theirs (S.attach onMine mine g9)
        offers source slotOf oid =
          fmap
            (Set.member (Recipient.ToObject oid) . (\theSlot -> Target.legalRecipients StackObjectKind.Spell (Just S.alice) source theSlot board))
            slotOf
        workerOffers = offers workerId (activatedTargetSlot worker)
        crownOffers = offers crownId (activatedTargetSlot crown)
    Spec.assertEqWith s "an Aura on alice's creature is a legal target" (workerOffers onMine) (Just True)
    Spec.assertEqWith s "one on bob's creature is not" (workerOffers onTheirs) (Just False)
    -- The pair that makes the composition do work no nullary atom can: one board,
    -- one Aura, two cards, two answers.
    Spec.assertEqWith s "which Crown of the Ages, asking only about creature-ness, will offer" (crownOffers onTheirs) (Just True)
    -- The CARD TYPE conjunct, on a host alice does control -- so this negative
    -- cannot be the control conjunct answering again.
    Spec.assertEqWith s "an Aura on alice's LAND is not on a creature" (workerOffers onLand) (Just False)
    Spec.assertEqWith s "nor is an unattached Aura attached to anything" (workerOffers loose) (Just False)
    -- Not vacuous: the slot rejects a permanent that is not an Aura at all on the
    -- very board where it accepts one that is.
    Spec.assertEqWith s "and the Worker is not an Aura" (workerOffers workerId) (Just False)
  -- design.md section 4's whole-card proof: activate the printed ability through
  -- the real activation path (CR 602.2a), let it resolve, and see the Aura go to
  -- its owner's graveyard (CR 701.8a). The Aura on bob's creature is the control:
  -- it sits on the same board and is untouched.
  Spec.it s "CR 701.8a whole card: Miracle Worker destroys the Aura on her own creature" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    worker <- S.printingOf s registry "Miracle Worker"
    let base = Setup.emptyGame S.bothPlayers
        (mine, g1) = S.addPermanent piker S.alice base
        (theirs, g2) = S.addPermanent piker S.bob g1
        (onMine, g3) = S.addPermanent unholyStrength S.alice g2
        (onTheirs, g4) = S.addPermanent unholyStrength S.alice g3
        (workerId, g5) = S.addPermanent worker S.alice g4
        board = (S.attach onTheirs theirs (S.attach onMine mine g5)) {GameState.priority = Just S.alice}
    case Face.activatedAbilities (S.combinedFace worker) of
      [] -> Spec.assertFailure s "Miracle Worker should print one activated ability"
      ability : _ -> do
        let activated = snd (Engine.runGamePure (aimAtOffered onMine) board (Activate.activateAbility S.alice workerId ability))
            after = snd (Engine.runGamePure (aimAtOffered onMine) activated Stack.resolveTop)
            settled = S.settleSba (S.settleSba after)
        Spec.assertBool s (not (Set.member onMine (GameState.battlefield settled))) "the Aura on her creature is destroyed"
        Spec.assertBool s (Set.member onTheirs (GameState.battlefield settled)) "the one on bob's creature is untouched"
        -- The cost was really paid rather than the activation silently failing.
        Spec.assertEqWith s "and the Worker is tapped" (fmap Object.tapped (Game.lookupObject workerId settled)) (Just TapState.Tapped)

auraSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
auraSpec s registry = Spec.describe s "Aura" $ do
  -- CR 608.2b: an Aura spell is the first PERMANENT spell in this pool that
  -- can be countered on resolution. Before this task, Stack sent every
  -- permanent spell to the battlefield with no target check at all.
  Spec.it s "CR 608.2b: an Aura spell whose target left is countered on resolution" $ do
    swamp <- S.printingOf s registry "Swamp"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    let base = S.landsInPlay swamp 1
        (creature, withCreature) = S.addPermanent piker S.bob base
        (gs, spellId) = S.handOne unholyStrength withCreature
        cast = snd (Engine.runGamePure S.identityAnswer gs (S.cast S.alice spellId))
        -- The target leaves in response, so no legal target remains at resolution.
        bounced = S.runPure S.identityAnswer cast (Event.changeZone (pure ()) creature Zone.Hand)
        after = snd (Engine.runGamePure S.identityAnswer bounced Stack.resolveTop)
    Spec.assertEqWith s "nothing attached on the battlefield" (filter (\o -> Object.zone o == Zone.Battlefield && Maybe.isJust (Object.attachedTo o)) (Map.elems (GameState.objects after))) []
    Spec.assertEqWith s "the Aura is in its owner's graveyard" (length (Game.zoneMembers Zone.Graveyard S.alice after)) 1
  -- CR 704.5m, and CR 704.3's repeat. SBAs are simultaneous, so the pass that
  -- buries the creature judged the Aura against a state in which that creature was
  -- still there; the Aura falls off on the NEXT pass. Asserting both passes is the
  -- point -- an implementation that dropped the Aura in pass one would be reading
  -- post-pass state, which is what CR 704.3's "simultaneously" forbids.
  Spec.it s "CR 704.5m: an Aura whose creature died falls off on the next SBA pass" $ do
    swamp <- S.printingOf s registry "Swamp"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    let base = S.landsInPlay swamp 1
        (creature, withCreature) = S.addPermanent piker S.bob base
        (aura, withAura) = S.addPermanent unholyStrength S.alice withCreature
        attached = S.attach aura creature withAura
        -- Goblin Piker is 2/1; Unholy Strength makes it 4/2, so 2 damage is not
        -- lethal and 3 is (CR 704.5g reads TOTAL marked damage against projected
        -- toughness).
        damaged = S.markDamage creature 3 attached
        pass1 = S.settleSba damaged
        pass2 = S.settleSba pass1
    Spec.assertEqWith s "the creature is gone after pass one" (Game.lookupObject creature pass1) Nothing
    Spec.assertBool s (Set.member aura (GameState.battlefield pass1)) "the Aura is still on the battlefield after pass one"
    Spec.assertBool s (not (Set.member aura (GameState.battlefield pass2))) "the Aura is gone from the battlefield after pass two"
    Spec.assertEqWith s "and is in its OWNER's graveyard" (length (Game.zoneMembers Zone.Graveyard S.alice pass2)) 1
  -- CR 704.5m's remaining clause: unattached. Its third clause -- attached to an
  -- object the enchant slot no longer admits (CR 303.4c) -- is reached two ways:
  -- by a CONTROL change (the Control Magic and Setessan Training case below), and
  -- by the host ceasing to be a creature at all, which is the pair of cases
  -- immediately after this one.
  Spec.it s "CR 704.5m: an unattached Aura on the battlefield goes to the graveyard" $ do
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    let base = Setup.emptyGame S.bothPlayers
        (aura, gs) = S.addPermanent unholyStrength S.alice base
        after = S.settleSba gs
    Spec.assertBool s (not (Set.member aura (GameState.battlefield after))) "never attached, so it falls off immediately"
  -- CR 303.4c through CR 704.5m, with the illegality coming from a layer-4 card
  -- type SET rather than from a control change or a death: Song of the Dryads
  -- makes its host a colorless Forest land (CR 205.1a), and Unholy Strength's
  -- "Enchant creature" no longer admits it.
  --
  -- A gameplay-level reader for the set, which is the point of running it through
  -- a state-based action rather than reading the projection: the enchant filter
  -- asks CR 205's question about the host, and the answer moves a card between
  -- zones. An implementation that ADDED the land type would leave the host a
  -- creature and Unholy Strength where it is.
  --
  -- The pair differs in exactly one thing: which permanent Song of the Dryads is
  -- attached to. Both boards carry the same two Auras, the same Piker and the same
  -- Forest, and in both the Song itself stays -- its own "enchant permanent"
  -- admits a land as readily as a creature, so neither leg can pass by the Song
  -- falling off instead.
  Spec.it s "CR 704.5m / 205.1a: a host that stops being a creature buries the Aura enchanting it" $ do
    forest <- S.printingOf s registry "Forest"
    piker <- S.printingOf s registry "Goblin Piker"
    unholyStrength <- S.printingOf s registry "Unholy Strength"
    song <- S.printingOf s registry "Song of the Dryads"
    let base = S.landsInPlay forest 1
        landId = case Game.zoneMembers Zone.Battlefield S.alice base of
          i : _ -> i
          [] -> ObjectId.MkObjectId 999
        (creature, withCreature) = S.addPermanent piker S.alice base
        (aura, withAura) = S.addPermanent unholyStrength S.alice withCreature
        (songId, withSong) = S.addPermanent song S.alice (S.attach aura creature withAura)
        -- ToObject rather than S.attach's ToCreature: "enchant permanent" is a
        -- Pool.Permanents slot, so those are the recipients casting would have
        -- left, and CR 704.5m's re-check compares against exactly those.
        songOn host = S.settleSba (S.attachTo songId (Recipient.ToObject host) withSong)
        onCreature = songOn creature
        onLand = songOn landId
    Spec.assertBool s (not (Projection.isCreatureOf creature onCreature)) "the Song made the Piker a land, so it is no longer a creature"
    Spec.assertBool s (not (Set.member aura (GameState.battlefield onCreature))) "and Unholy Strength, illegally attached, was buried"
    Spec.assertEqWith s "in its owner's graveyard" (length (Game.zoneMembers Zone.Graveyard S.alice onCreature)) 1
    Spec.assertBool s (Set.member songId (GameState.battlefield onCreature)) "the Song itself stays: enchant permanent admits a land"
    Spec.assertBool s (Set.member creature (GameState.battlefield onCreature)) "and the host is still on the battlefield -- it stopped being a creature, it did not die"
    Spec.assertBool s (Projection.isCreatureOf creature onLand) "the control: with the Song elsewhere the Piker is still a creature"
    Spec.assertBool s (Set.member aura (GameState.battlefield onLand)) "so Unholy Strength stays attached"
  -- CR 613.1b / 303.4e: Control Magic's static ability moves control of the
  -- enchanted creature to the AURA's controller, and leaves the Aura itself alone.
  Spec.it s "CR 613.1b: Control Magic gives the Aura's controller the creature" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    controlMagic <- S.printingOf s registry "Control Magic"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.bob base
        (aura, withAura) = S.addPermanent controlMagic S.alice withCreature
        attached = S.attach aura creature withAura
    Spec.assertEqWith s "unattached, bob still controls it" (Projection.controllerOf creature withAura) (Just S.bob)
    Spec.assertEqWith s "attached, alice controls it" (Projection.controllerOf creature attached) (Just S.alice)
    Spec.assertEqWith s "the Aura's own controller is unchanged" (Projection.controllerOf aura attached) (Just S.alice)
    Spec.assertBool s (elem creature (Projection.controls S.alice attached)) "and it is in alice's controls"
    Spec.assertBool s (notElem creature (Projection.controls S.bob attached)) "no longer in bob's"
  -- CR 704.5m plus layer 2: destroying the Aura reverts control on the next
  -- projection, because a static ability's effect exists only while its source is
  -- on the battlefield (CR 604.2).
  Spec.it s "CR 604.2: removing Control Magic reverts control" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    controlMagic <- S.printingOf s registry "Control Magic"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.bob base
        (aura, withAura) = S.addPermanent controlMagic S.alice withCreature
        attached = S.attach aura creature withAura
        gone = S.runPure S.identityAnswer attached (Event.changeZone (pure ()) aura Zone.Graveyard)
    Spec.assertEqWith s "alice controlled it" (Projection.controllerOf creature attached) (Just S.alice)
    Spec.assertEqWith s "bob controls it again" (Projection.controllerOf creature gone) (Just S.bob)
  -- CR 604.2 / 613.1b: a control grant under an "as long as" clause takes the
  -- Piker only while the clause holds. The two boards without Confiscate differ
  -- in alice's Forest alone. With it, Confiscate is the NEWER effect, so in
  -- timestamp order alone the Usurpation would apply first and still see
  -- alice's Forest; CR 613.8a makes the Usurpation wait on the steal that
  -- changes whether it exists, and it then finds no Forest of alice's.
  Spec.it s "CR 604.2/613.8a a control grant applies only while its as-long-as clause holds" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    forest <- S.printingOf s registry "Forest"
    usurpation <- S.printingOf s registry "Synthetic Sylvan Usurpation"
    confiscate <- S.printingOf s registry "Confiscate"
    let (creature, withCreature) = S.addPermanent piker S.bob S.threePlayerGame
        usurped gs = let (a, g) = S.addPermanent usurpation S.alice gs in S.attach a creature g
        (land, withLand) = S.addPermanent forest S.alice withCreature
        withForest = usurped withLand
        withoutForest = usurped withCreature
        confiscated = let (c, g) = S.addPermanent confiscate S.bob withForest in S.attach c land g
        onTurnOf pid gs = S.runPure S.identityAnswer gs {GameState.activePlayer = pid} (Engine.settleAll pid)
    Spec.assertBool s (Combat.canAttack S.alice creature (onTurnOf S.alice withForest)) "alice, who controls a Forest, may attack with bob's Piker"
    Spec.assertBool s (Combat.canAttack S.bob creature (onTurnOf S.bob withoutForest)) "with no Forest of alice's, bob keeps his Piker"
    Spec.assertBool s (Combat.canAttack S.bob creature (onTurnOf S.bob confiscated)) "once bob confiscates alice's Forest, bob has his Piker back"
  -- CR 302.6 across turns (#62): control from an Aura is INDEFINITE, so alice
  -- still holds the creature when her own untap step arrives. Engine.settleAll
  -- iterates Projection.controls, so it settles for the controller, and the
  -- creature can attack. Act of Treason could never test this -- its control ends
  -- at cleanup (CR 514.2), long before the thief's untap step.
  --
  -- The whole span, with nothing forced: the Piker settles under bob, the
  -- steal makes it sick again for alice, and only HER untap step settles it
  -- for her. The middle assertion is what #198 got wrong.
  Spec.it s "CR 302.6 (#62): a creature held under indefinite control settles at the thief's untap step" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    controlMagic <- S.printingOf s registry "Control Magic"
    let base = Setup.emptyGame S.bothPlayers
        (creature, withCreature) = S.addPermanent piker S.bob base
        settledForBob = S.runPure S.identityAnswer withCreature (Engine.settleAll S.bob)
        (aura, withAura) = S.addPermanent controlMagic S.alice settledForBob
        stolen = S.attach aura creature withAura
        settled = S.runPure S.identityAnswer stolen (Engine.settleAll S.alice)
    Spec.assertEqWith s "alice controls it" (Projection.controllerOf creature stolen) (Just S.alice)
    Spec.assertBool s (not (Combat.canAttack S.alice creature stolen)) "the turn she steals it, it cannot attack"
    Spec.assertBool s (Combat.canAttack S.alice creature settled) "and it has settled under her control, so it can attack"

-- CR 303.4's last sentence -- "other effects can limit what a permanent can be
-- enchanted by" -- and CR 301.5's equivalent for an Equipment, which
-- Parun.Types.AttachRestriction carries and Parun.Engine.AttachRestriction reads.
-- Consecrate Land ("enchanted land ... can't be enchanted by other Auras") and
-- Goblin Brawler ("this creature can't be equipped") are the pool's two printings
-- of it, and between them they reach both places the answer is asked: CR 701.3a's
-- move and destination offer (Parun.Engine.Attach.attachmentFor) and CR
-- 704.5m/303.4c's re-check (Parun.Engine.Sba.fallsOff).
--
-- TARGETING is deliberately absent, and both cards' Gatherer rulings say so --
-- Goblin Brawler's outright ("you can activate an equip ability that targets
-- Goblin Brawler, but the Equipment will fail to move onto it"). CR 702.5a gives
-- the enchant ability the targeting job and this restriction is not it; only
-- protection also forbids the targeting, in a clause of its own (CR 702.16b),
-- which Parun.Engine.Target.targetable answers.
--
-- Protection is also the pool's one MINTED producer of this restriction (CR
-- 702.16c, CR 702.16d), so the last two cases below come from a keyword rather
-- than from a face, and they are where Parun.Engine.Sba.becomesUnattached's
-- Equipment clause is proved as well as fallsOff's; its Fortification clause is
-- fortificationSpec's.
--
-- Rule 702.16d's ATTACH GATE is not proved here: on the equip and fortify road
-- the ability's source is the attaching permanent itself, so a black Equipment
-- aimed at a creature with protection from black -- or Darksteel Garrison aimed
-- at a land with protection from artifacts, which fortificationSpec above shows
-- -- is refused by CR 702.16b before rule 702.16d is reached and the two
-- readings agree. Separating them needs an attach whose SOURCE is neither the
-- mover nor the destination, which is Effect.AttachBound: data/scenarios/aura/'s
-- "CR 702.16b/702.16d whole cards" board targets a protected creature with an
-- enchantment's ability and then watches rule 702.16d refuse the artifact. The
-- state-based half below covers the same sentence from the other side, and
-- fortificationSpec's is its Fortification half.
attachRestrictionSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
attachRestrictionSpec s registry = Spec.describe s "AttachRestriction" $ do
  -- CR 301.5b's last sentence, at the MOVE: "if an effect attempts to attach an
  -- Equipment to an object that can't be equipped by it, the Equipment doesn't
  -- move." The equip ability targets legally either way, so the two runs differ
  -- in exactly one thing -- which creature the target slot names -- and the
  -- Piker run is the positive control that says the board, the mana and the
  -- ability all work.
  Spec.it s "CR 301.5b whole cards: Bonesplitter equips the Piker and fails to move onto Goblin Brawler" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    brawler <- S.printingOf s registry "Goblin Brawler"
    bonesplitter <- S.printingOf s registry "Bonesplitter"
    let base0 = S.landsInPlay island 1
        (pikerId, base1) = S.addPermanent piker S.alice base0
        (brawlerId, base2) = S.addPermanent brawler S.alice base1
        (splitterId, base3) = S.addPermanent bonesplitter S.alice base2
        ready = base3 {GameState.priority = Just S.alice}
        -- From the PROJECTION, not the face: Bonesplitter declares CR 702.6a's
        -- keyword and prints no activated ability of its own.
        equip = case Projection.abilitiesOf splitterId ready of
          ability : _ -> Just ability
          [] -> Nothing
    case equip of
      Nothing -> Spec.assertFailure s "Bonesplitter should offer rule 702.6a's minted equip ability"
      Just ability -> do
        let run victim =
              snd
                ( Engine.runGamePure
                    (aimRecipient (Recipient.ToCreature victim))
                    (snd (Engine.runGamePure (aimRecipient (Recipient.ToCreature victim)) ready (Activate.activateAbility S.alice splitterId ability)))
                    Stack.resolveTop
                )
            ontoPiker = run pikerId
            ontoBrawler = run brawlerId
        Spec.assertEqWith s "before: a plain 2/1 Piker" (S.powerToughnessOf pikerId ready) (Just (2, 1))
        Spec.assertEqWith s "before: a plain 2/2 Brawler" (S.powerToughnessOf brawlerId ready) (Just (2, 2))
        -- CR 303.4/301.5's destination limit, at gameplay level: the +2/+0 never
        -- arrives, because the Equipment never moved.
        Spec.assertEqWith s "CR 301.5b: the Brawler is still a 2/2" (S.powerToughnessOf brawlerId ontoBrawler) (Just (2, 2))
        Spec.assertEqWith s "and the Bonesplitter is still unattached" (fmap Object.attachedTo (Game.lookupObject splitterId ontoBrawler)) (Just Nothing)
        -- The positive control on the same board: nothing about the equip
        -- ability, the mana or the target slot is broken.
        Spec.assertEqWith s "the Piker it CAN equip is a 4/1" (S.powerToughnessOf pikerId ontoPiker) (Just (4, 1))
        Spec.assertEqWith s "with the Bonesplitter on it (CR 701.3a)" (fmap Object.attachedTo (Game.lookupObject splitterId ontoPiker)) (Just (Just (Recipient.ToCreature pikerId)))
  -- CR 702.16n's "this Aura" form and its last sentence, on a pair of boards
  -- differing only in a second White Ward. Placed by hand, since CR 702.16b
  -- and CR 702.16c keep a second Ward from being cast or attached onto a
  -- creature the first protects; data/scenarios/white-ward-spares-itself.json
  -- is the cast road.
  Spec.it s "CR 702.16n whole cards: one White Ward stays on its creature, and two bury each other" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    ward <- S.printingOf s registry "White Ward"
    let (host, base1) = S.addPermanent piker S.alice S.threePlayerGame
        (firstWard, base2) = S.addPermanent ward S.alice base1
        alone = S.attach firstWard host base2
        (secondWard, base3) = S.addPermanent ward S.alice alone
        paired = S.attach secondWard host base3
        afterAlone = S.settleSba alone
        afterPaired = S.settleSba paired
    Spec.assertBool s (not (S.onBattlefield firstWard afterPaired) && not (S.onBattlefield secondWard afterPaired)) "CR 702.16n: each Ward's protection from white buries the other"
    Spec.assertBool s (S.onBattlefield firstWard afterAlone) "and a lone Ward stays on the creature it protects"
  -- CR 607.2d's "the chosen color" read in the GRANTER's frame: Cho-Manno's
  -- Blessing's choice, not the Piker's, which has none. A pair of boards
  -- differing only in that choice, with a white and a black Aura beside the
  -- white Blessing, so each choice buries exactly one of them and the white one
  -- also needs CR 702.16n's "this Aura". The stamp stands in for the entry
  -- choice, whose road Parun.ColorSpec's Gauntlet of Power case proves.
  Spec.it s "CR 702.16n whole cards: Cho-Manno's Blessing buries the Aura of the colour it chose, and spares itself" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    blessing <- S.printingOf s registry "Cho-Manno's Blessing"
    pacifism <- S.printingOf s registry "Pacifism"
    strength <- S.printingOf s registry "Unholy Strength"
    let (host, base1) = S.addPermanent piker S.alice S.threePlayerGame
        (blessingId, base2) = S.addPermanent blessing S.alice base1
        (pacifismId, base3) = S.addPermanent pacifism S.alice (S.attach blessingId host base2)
        (strengthId, base4) = S.addPermanent strength S.alice (S.attach pacifismId host base3)
        wearing = S.attach strengthId host base4
        chose color = S.settleSba (wearing {GameState.objects = Map.adjust (\o -> o {Object.chosenColors = Map.singleton Acquisition.Own (Set.singleton color)}) blessingId (GameState.objects wearing)})
        standing gs = (S.onBattlefield blessingId gs, S.onBattlefield pacifismId gs, S.onBattlefield strengthId gs)
    Spec.assertEqWith s "CR 607.2d / 704.5m: the Blessing that chose black buries Unholy Strength alone" (standing (chose Color.Black)) (True, True, False)
    Spec.assertEqWith s "CR 702.16n: the one that chose white buries Pacifism and spares itself" (standing (chose Color.White)) (True, False, True)
  -- CR 702.16p's "already attached" as CR 613.7e's timestamp: four white Auras
  -- on alice's Piker, placed in stamp order -- alice's Pacifism, bob's, bob's
  -- Blessing, bob's second Pacifism. Placed by hand, since CR 702.16p keeps the
  -- last from becoming attached at all. bob's Blessing on alice's creature
  -- separates "you control" from the host's controller.
  Spec.it s "CR 702.16p whole cards: Benevolent Blessing spares only its controller's Auras attached before it" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    blessing <- S.printingOf s registry "Benevolent Blessing"
    pacifism <- S.printingOf s registry "Pacifism"
    let (host, base1) = S.addPermanent piker S.alice S.threePlayerGame
        (alices, base2) = S.addPermanent pacifism S.alice base1
        (earlier, base3) = S.addPermanent pacifism S.bob (S.attach alices host base2)
        (blessingId, base4) = S.addPermanent blessing S.bob (S.attach earlier host base3)
        (later, base5) = S.addPermanent pacifism S.bob (S.attach blessingId host base4)
        wearing = S.attach later host base5
        after = S.settleSba (wearing {GameState.objects = Map.adjust (\o -> o {Object.chosenColors = Map.singleton Acquisition.Own (Set.singleton Color.White)}) blessingId (GameState.objects wearing)})
    Spec.assertEqWith s "CR 702.16p: the Blessing and bob's Pacifism attached before it stay, and the one attached after is buried" (S.onBattlefield blessingId after, S.onBattlefield earlier after, S.onBattlefield later after) (True, True, False)
    Spec.assertBool s (not (S.onBattlefield alices after)) "and alice's Pacifism is buried, the spare being Auras the Blessing's controller controls"
  -- CR 702.16k's Aura sentence: "Such a permanent or player ... can't be
  -- enchanted by Auras that player controls." True-Name Nemesis, whose quality is
  -- Filter.OfChosenPlayer -- read by Parun.Engine.AttachRestriction.barredBy
  -- off Filter.Context.carrierChosenPlayer, which it fills off the minted row's
  -- source (the protected host itself).
  --
  -- THREE SEATS and a pair of boards differing only in WHOM the Nemesis chose.
  -- alice's Pacifism is an ordinary white Aura with no quality of its own, so
  -- nothing but who CONTROLS it can decide the case, and two seats would collapse
  -- "the chosen player" onto alice.
  --
  -- The choice ARRIVES AFTER the attachment, the road the case below already
  -- takes: the attach gate would otherwise refuse the pairing and there would be
  -- no standing Aura for CR 704.5m to bury. The stamp stands in for the entry
  -- choice, whose own road is proved by Parun.DamageSpec's True-Name Nemesis group.
  Spec.it s "CR 702.16k whole cards: a Nemesis that chose alice buries her Aura, and one that chose carol keeps it" $ do
    nemesis <- S.printingOf s registry "True-Name Nemesis"
    pacifism <- S.printingOf s registry "Pacifism"
    let (nemesisId, base1) = S.addPermanent nemesis S.bob S.threePlayerGame
        (auraId, base2) = S.addPermanent pacifism S.alice base1
        wearing = S.attach auraId nemesisId base2
        chose who = S.settleSba (wearing {GameState.objects = Map.adjust (\o -> o {Object.chosenPlayers = Map.singleton Acquisition.Own (Map.singleton PlayerChoice.AsEnters who)}) nemesisId (GameState.objects wearing)})
        choseAlice = chose S.alice
        choseCarol = chose S.carol
    Spec.assertBool s (Set.member auraId (GameState.battlefield (S.settleSba wearing))) "before any choice the Aura is legally attached"
    Spec.assertBool s (not (Set.member auraId (GameState.battlefield choseAlice))) "CR 702.16k / 704.5m alice was chosen, so her Aura is off the battlefield after one pass"
    Spec.assertBool s (Set.member auraId (GameState.battlefield choseCarol)) "and with carol chosen instead the same Aura stays where it is"
    Spec.assertEqWith s "CR 704.5m in its owner's graveyard, and alice owns it" (length (Game.zoneMembers Zone.Graveyard S.alice choseAlice)) 1

  -- CR 702.16c's and CR 702.16d's SECOND sentences, on one board and in one
  -- state-based pass, because they differ in exactly the way the two rules say:
  -- the Aura is put into its owner's graveyard and the Equipment stays on the
  -- battlefield, unattached.
  --
  -- The protection ARRIVES AFTER the attachment, which is the only board that
  -- reaches these sentences at all -- the attach gate proved above refuses every
  -- other road. Unstable Shapeshifter is how: both permanents attach to a plain
  -- 0/1 Shapeshifter, and its CR 603.6a trigger then makes it a copy of the
  -- Apostle (CR 707.2a copies the keyword, protection being derived from rules
  -- text), so protection from black turns up on a permanent that is already
  -- carrying two black attachments.
  Spec.it s "CR 702.16c/702.16d whole cards: a creature that becomes protected from black buries the black Aura on it and sheds the black Equipment" $ do
    island <- S.printingOf s registry "Island"
    shapeshifter <- S.printingOf s registry "Unstable Shapeshifter"
    apostle <- S.printingOf s registry "Apostle of Purifying Light"
    strength <- S.printingOf s registry "Unholy Strength"
    finery <- S.printingOf s registry "Groom's Finery"
    let base0 = S.landsInPlay island 1
        (shifter, base1) = S.addPermanent shapeshifter S.alice base0
        (auraId, base2) = S.addPermanent strength S.alice base1
        wearing0 = S.attach auraId shifter base2
        (equipId, base3) = S.addPermanent finery S.alice wearing0
        wearing = S.attach equipId shifter base3
        (_, entered) = S.entersWithTrigger apostle S.alice wearing
        onStack = snd (Engine.runGamePure S.identityAnswer entered Engine.settleForPriority)
        after = snd (Engine.runGamePure S.identityAnswer onStack (Stack.resolveTop >> Engine.settleForPriority))
    Spec.assertBool s (Set.member Color.Black (Projection.colorsOf auraId wearing)) "before: Unholy Strength is a black Aura"
    Spec.assertBool s (Set.member Color.Black (Projection.colorsOf equipId wearing)) "and Groom's Finery is a black Equipment"
    Spec.assertEqWith s "before: the Shapeshifter wears both, so a 0/1 is a 4/2" (S.powerToughnessOf shifter wearing) (Just (4, 2))
    Spec.assertBool s (not (null (GameState.stack onStack))) "the Shapeshifter's copy trigger really was on the stack"
    -- The two gameplay-level assertions, ahead of every proxy: rule 702.16c's
    -- outcome and rule 702.16d's, which is the whole reason the two rules are
    -- separate sentences.
    Spec.assertEqWith s "CR 702.16c / 704.5m: the black Aura is in its owner's graveyard" (length (filter (\oid -> Game.cardOf oid after == Just (Printing.card strength)) (Foldable.toList (Map.findWithDefault Seq.empty S.alice (GameState.graveyard after))))) 1
    Spec.assertBool s (Set.member equipId (GameState.battlefield after)) "CR 702.16d / 704.5n: the black Equipment stays on the battlefield"
    Spec.assertEqWith s "and it is unattached" (fmap Object.attachedTo (Game.lookupObject equipId after)) (Just Nothing)
    Spec.assertBool s (not (Set.member auraId (GameState.battlefield after))) "the Aura left the battlefield, where the Equipment did not"
    Spec.assertBool s (Projection.hasKeyword (Keyword.Protection Protection.MkProtection {Protection.quality = Filter.Type.HasColor Color.Black, Protection.spares = Nothing}) shifter after) "the copy is what gave the Shapeshifter protection from black"
    Spec.assertEqWith s "so it is the Apostle's printed 2/1, with neither bonus left" (S.powerToughnessOf shifter after) (Just (2, 1))

-- The names of the cards in a player's HAND. Where a destination assertion has to
-- go, because S.countByName sums the hand with the library and a search that
-- moves a card from one to the other leaves that sum unchanged.
handNames :: PlayerId.PlayerId -> GameState.GameState -> [CardName.CardName]
handNames pid gs = Maybe.mapMaybe (fmap S.nameOf . flip Game.cardOf gs) (Game.zoneMembers Zone.Hand pid gs)

-- CR 613.1f's NAMED ability removal and CR 116.2c's pay-to-end, which are one
-- printed sentence: "This creature loses this ability and becomes an Aura
-- enchantment with enchant creature. Attach it to target creature. You may pay
-- {U} to end this effect."
--
-- Gliding Licid is the producer and the whole card. It is Cloudform's chain --
-- CR 205.1b's Aura subtype, CR 702.5a's granted enchant, CR 701.3a's attach --
-- plus three things that card has not got: CR 205.1a's card-type set, the
-- layer-6 removal of the ability the effect came from
-- (Modification.LoseNamedAbility), and a duration that is not a window of the
-- turn (Duration.UntilPaid).
--
-- Its eleven siblings differ only in the static half: Calming's "can't attack"
-- needs a combat restriction, Dominating's needs SetControllerToSource, and so
-- on. Gliding's is GainKeyword Flying, already in the vocabulary and readable off
-- the enchanted creature, which is what makes the removal's SCOPE observable --
-- see the first case.
--
-- CR 704.3 never runs between the effects of one resolution, so the moment the
-- Licid is an unattached Aura is not a moment CR 704.5m sees, exactly as for
-- Cloudform.
-- CR 702.103: bestow. The one thing a choice made while casting could not do
-- before this group -- change what the spell IS. Nyxborn Rollicker is the
-- producer: {R} 1/1 Enchantment Creature -- Satyr, "Bestow {1}{R}", "Enchanted
-- creature gets +1/+1", the cheapest bestow printing whose non-bestow clauses are
-- a bare P/T buff (Scryfall keyword:bestow ordered by mana value, 2026-08-26; the
-- other five at that tier each print a second keyword, a "can't block", a
-- control change or prowess).
--
-- ONE board and two answerers, graveRecitalSpec's shape in Parun.CastSpec: mana,
-- seats, timing and stock cannot be the difference, only which candidate CR
-- 601.2b's announcement settles on. Both costs are payable off the same four
-- Mountains.
--
-- TWO creatures to enchant, so CR 601.2c's target choice is a real one -- a board
-- with one collapses it, and then nothing separates "the granted enchant slot was
-- consulted" from "the host was hardcoded".
--
-- CR 702.103d brings two more cards, and each is judged on the Aura the bestow
-- ability makes of the spell rather than on the creature it prints: Thalia,
-- Guardian of Thraben ("noncreature spells cost {1} more to cast", CR 601.2f and
-- CR 118.9d) and Aether Storm ({3}{U} Enchantment, "Creature spells can't be
-- cast", CR 601.3a). Aether Storm's second ability carries its printed "Any
-- player may activate this ability" (ActivatedAbility.activator); nothing in
-- these cases activates it, and Parun.ActivateSpec's "Any player may activate"
-- group is where an opponent does.
--
-- CR 702.103c's copy of a bestowed Aura spell is Parun.CopySpec's (Lithoform
-- Engine copying a bestowed Rollicker).
--
-- The LAST case is the one board shape the paragraph above does not describe: no
-- creature at all, and then one, because what it measures is whether CR 601.2c
-- leaves the bestow candidate on offer. Which host the choice falls on is not its
-- question -- the cases above own that -- so one creature is enough there.
bestowSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
bestowSpec s registry = Spec.describe s "Bestow" $ do
  -- THE discriminating pair the issue asks for: the spell's own card types and
  -- subtypes WHILE IT IS ON THE STACK. A shortcut that folded the Aura-ness in at
  -- resolution reaches the same host power and the same attachment, and differs
  -- here and only here.
  Spec.it s "CR 702.103a/b: the bestow cost makes the spell an Aura enchantment on the stack; the printed cost leaves it a creature spell" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    mammoth <- S.printingOf s registry "War Mammoth"
    rollicker <- S.printingOf s registry "Nyxborn Rollicker"
    let base = S.landsInPlay mountain 4
        (bystander, gs1) = S.addPermanent piker S.alice base
        (host, gs2) = S.addPermanent mammoth S.alice gs1
        (board, spellId) = S.handOne rollicker gs2
        bestowed = S.runPure (bestowing host) board (S.cast S.alice spellId)
        printed = S.runPure (payingPrinted host) board (S.cast S.alice spellId)
    -- Both candidates really are on offer from the hand, so neither leg passes
    -- for want of the other.
    Spec.assertEqWith
      s
      "CR 702.103a: the printed cost and the bestow cost are both offered from the hand"
      (fmap Cost.Type.mana (Cost.costsFor S.alice (S.printingName rollicker) spellId board))
      [Just (ManaCost.MkManaCost [theRed]), Just (ManaCost.MkManaCost [ManaSymbol.Generic 1, theRed])]
    -- CR 702.103b, the gameplay-level pair, FIRST so nothing ahead of it absorbs
    -- a mutation: a set of card types and a set of subtypes, both read off the
    -- spell on the stack.
    Spec.assertEqWith
      s
      "CR 702.103b: cast bestowed, the spell on the stack is an Enchantment and no longer a Creature"
      (fmap (\oid -> Projection.cardTypesOf oid bestowed) (topOfStack bestowed))
      (Just (Set.singleton CardType.Enchantment))
    Spec.assertEqWith
      s
      "and CR 205.1a took Satyr with the Creature card type, leaving Aura"
      (fmap (\oid -> Projection.subtypesOf oid bestowed) (topOfStack bestowed))
      (Just (Set.singleton Subtype.Aura))
    Spec.assertEqWith
      s
      "CR 702.103b: and it gained enchant creature, which is the slot CR 601.2c judged"
      (fmap (\oid -> Card.foldEnchant (Projection.enchantOf oid bestowed)) (topOfStack bestowed))
      (Just (Just (TargetSlot.required Pool.Creatures Nothing)))
    -- The same spell cast the other way, which is what makes the three above a
    -- fact about the CHOICE rather than about the card.
    Spec.assertEqWith
      s
      "cast for its printed cost it is still a creature spell"
      (fmap (\oid -> Projection.cardTypesOf oid printed) (topOfStack printed))
      (Just (Set.fromList [CardType.Creature, CardType.Enchantment]))
    Spec.assertEqWith
      s
      "keeping its Satyr subtype and gaining no Aura one"
      (fmap (\oid -> Projection.subtypesOf oid printed) (topOfStack printed))
      (Just (Set.singleton Subtype.Satyr))
    Spec.assertEqWith
      s
      "and no enchant ability, so CR 601.2c asked it for no target"
      (fmap (\oid -> Card.foldEnchant (Projection.enchantOf oid printed)) (topOfStack printed))
      (Just Nothing)
    Spec.assertBool s (bystander /= host) "the two creatures on the board are distinct"
  -- CR 608.3c: the bestowed spell resolves as an Aura, entering attached to the
  -- creature CR 601.2c chose; the same card cast for its printed cost enters as an
  -- ordinary creature attached to nothing.
  Spec.it s "CR 608.3c / 303.4: the bestowed spell enters attached and pumps its host; the printed cast enters as a creature" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    mammoth <- S.printingOf s registry "War Mammoth"
    rollicker <- S.printingOf s registry "Nyxborn Rollicker"
    let base = S.landsInPlay mountain 4
        (bystander, gs1) = S.addPermanent piker S.alice base
        (host, gs2) = S.addPermanent mammoth S.alice gs1
        (board, spellId) = S.handOne rollicker gs2
        resolveWith :: (forall r. Prompt.Prompt r -> r) -> GameState.GameState
        resolveWith answer = S.settleSba (S.runPure answer (S.runPure answer board (S.cast S.alice spellId)) Stack.resolveTop)
        bestowed = resolveWith (bestowing host)
        printed = resolveWith (payingPrinted host)
    -- War Mammoth is a 3/3 and Goblin Piker a 2/1, so the pumped host, the
    -- bystander and the unbestowed Rollicker are three distinct readings. The
    -- host is the creature added SECOND, deliberately: an implementation that
    -- never asked CR 601.2c and let CR 303.4f pick a host instead would take the
    -- first, and this assertion is what tells the two apart.
    Spec.assertEqWith s "CR 702.103b: the enchanted War Mammoth is a 4/4" (S.powerToughnessOf host bestowed) (Just (4, 4))
    Spec.assertEqWith s "and the creature the player did NOT choose is untouched" (S.powerToughnessOf bystander bestowed) (Just (2, 1))
    Spec.assertEqWith
      s
      "CR 303.4: the Rollicker entered attached to the host it targeted"
      (fmap (\oid -> Object.attachedTo =<< Game.lookupObject oid bestowed) (rollickerOn rollicker bestowed))
      (Just (Just (Recipient.ToCreature host)))
    Spec.assertEqWith
      s
      "and is not itself a creature while bestowed"
      (fmap (\oid -> Projection.cardTypesOf oid bestowed) (rollickerOn rollicker bestowed))
      (Just (Set.singleton CardType.Enchantment))
    Spec.assertEqWith s "cast for its printed cost it pumps nobody" (S.powerToughnessOf host printed) (Just (3, 3))
    Spec.assertEqWith
      s
      "and enters attached to nothing"
      (fmap (\oid -> Object.attachedTo =<< Game.lookupObject oid printed) (rollickerOn rollicker printed))
      (Just Nothing)
    Spec.assertEqWith s "as a 1/1 Satyr creature of its own" (rollickerOn rollicker printed >>= \oid -> S.powerToughnessOf oid printed) (Just (1, 1))
  -- CR 702.103d's COST half, through CR 601.2f and CR 118.9d: Thalia taxes
  -- noncreature spells, and a bestowed Rollicker is an enchantment spell. Three
  -- boards off one fixture, differing in one thing each -- Thalia present or
  -- absent, and which candidate the answerer names -- so neither the tax nor the
  -- candidate can be the other's explanation.
  --
  -- Counted in TAPPED LANDS rather than in the announced cost: the cost is what
  -- the fix writes, and the mana actually spent is what a player observes. Four
  -- Mountains make three, two and one distinct readings, and a rejected cast
  -- rewinds to zero, so no two outcomes here collide.
  Spec.it s "CR 601.2f / 118.9d: Thalia taxes the bestowed cast and not the printed one" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    mammoth <- S.printingOf s registry "War Mammoth"
    rollicker <- S.printingOf s registry "Nyxborn Rollicker"
    thalia <- S.printingOf s registry "Thalia, Guardian of Thraben"
    let base = S.landsInPlay mountain 4
        (_, gs1) = S.addPermanent piker S.alice base
        (host, gs2) = S.addPermanent mammoth S.alice gs1
        (board, spellId) = S.handOne rollicker gs2
        taxing = snd (S.addPermanent thalia S.alice board)
        castWith :: (forall r. Prompt.Prompt r -> r) -> GameState.GameState -> GameState.GameState
        castWith answer gs = S.runPure answer gs (S.cast S.alice spellId)
        bestowedTaxed = castWith (bestowing host) taxing
        bestowedFree = castWith (bestowing host) board
        printedTaxed = castWith (payingPrinted host) taxing
    -- THE gameplay-level trio, first. Bestow {1}{R} taxed is three mana; untaxed
    -- it is two; the printed {R} is one, because a creature spell is not what
    -- Thalia's Filter names.
    Spec.assertEqWith s "CR 118.9d: the bestowed cast pays {2}{R} beside Thalia" (S.tappedCount S.alice bestowedTaxed) 3
    Spec.assertEqWith s "and {1}{R} with Thalia off the board" (S.tappedCount S.alice bestowedFree) 2
    Spec.assertEqWith s "CR 601.2f: the printed cast is a creature spell and pays {R} untaxed" (S.tappedCount S.alice printedTaxed) 1
    -- Each really cast, and each really settled on the candidate the answerer
    -- named: a rewind and a mis-taxed cast would otherwise share a reading.
    Spec.assertEqWith
      s
      "control: the taxed cast is the bestowed one, an Aura spell on the stack"
      (fmap (\oid -> Projection.cardTypesOf oid bestowedTaxed) (topOfStack bestowedTaxed))
      (Just (Set.singleton CardType.Enchantment))
    Spec.assertEqWith
      s
      "control: and the untaxed one is the creature spell"
      (fmap (\oid -> Projection.cardTypesOf oid printedTaxed) (topOfStack printedTaxed))
      (Just (Set.fromList [CardType.Creature, CardType.Enchantment]))
  -- CR 702.103d's PROHIBITION half, through CR 601.3a: Aether Storm stops
  -- creature spells, and the bestow candidate is not one. Two boards differing in
  -- exactly one permanent, and ONE answerer across both -- the one that names the
  -- printed cost -- so what changes is which candidate CR 601.2b had left to
  -- offer.
  Spec.it s "CR 702.103d / 601.3a: Aether Storm leaves the bestow candidate and takes the printed one away" $ do
    mountain <- S.printingOf s registry "Mountain"
    piker <- S.printingOf s registry "Goblin Piker"
    mammoth <- S.printingOf s registry "War Mammoth"
    rollicker <- S.printingOf s registry "Nyxborn Rollicker"
    storm <- S.printingOf s registry "Aether Storm"
    let base = S.landsInPlay mountain 4
        (_, gs1) = S.addPermanent piker S.alice base
        (host, gs2) = S.addPermanent mammoth S.alice gs1
        (open, spellId) = S.handOne rollicker gs2
        (plainCreature, board) = S.addHandCard piker S.alice open
        stormed = snd (S.addPermanent storm S.alice board)
        castThere gs = S.runPure (payingPrinted host) gs (S.cast S.alice spellId)
    -- THE gameplay-level pair, first: one answerer, two boards. Under Aether
    -- Storm the printed candidate is gone, so the announcement settles on the
    -- only one left and the spell on the stack is an Aura.
    Spec.assertEqWith
      s
      "CR 702.103d: under Aether Storm the Rollicker reaches the stack as an Aura spell"
      (fmap (\oid -> Projection.cardTypesOf oid (castThere stormed)) (topOfStack (castThere stormed)))
      (Just (Set.singleton CardType.Enchantment))
    Spec.assertEqWith
      s
      "and without it the same answerer takes the printed cost and leaves a creature spell"
      (fmap (\oid -> Projection.cardTypesOf oid (castThere board)) (topOfStack (castThere board)))
      (Just (Set.fromList [CardType.Creature, CardType.Enchantment]))
    -- Aether Storm really does prohibit creature spells, which is what makes the
    -- pair above a fact about bestow: an ordinary creature card in the same hand
    -- cannot be cast at all.
    Spec.assertBool s (not (S.castable S.alice plainCreature stormed)) "CR 601.3a: the Goblin Piker in hand is prohibited"
    Spec.assertBool s (S.castable S.alice plainCreature board) "and is castable off the same mana with Aether Storm gone"
    -- CR 702.103d at the gate itself: the offer survives, because one candidate
    -- escapes -- which is what keeps the cast above from being offered and then
    -- rejected.
    Spec.assertBool s (S.castable S.alice spellId stormed) "CR 702.103d: the bestow card is still offered under Aether Storm"
  -- CR 702.103d through CR 601.3's search exception: the bestow candidate is
  -- judged as an Aura where the card lies, in the LIBRARY. Synthetic Glacial
  -- Blessing grants the Rollicker the permission; the pair differs only in
  -- Aether Storm, under one answerer naming the printed cost. Were the library's
  -- stamp invisible, the Storm would take both candidates and nothing would cast.
  Spec.it s "CR 702.103d a bestow card cast while searching is judged as an Aura" $ do
    mountain <- S.printingOf s registry "Mountain"
    mammoth <- S.printingOf s registry "War Mammoth"
    rollicker <- S.printingOf s registry "Nyxborn Rollicker"
    blessing <- S.printingOf s registry "Synthetic Glacial Blessing"
    storm <- S.printingOf s registry "Aether Storm"
    let (host, gs1) = S.addPermanent mammoth S.alice (S.landsInPlay mountain 4)
        (_, gs2) = S.addPermanent blessing S.alice gs1
        (_, board) = S.addLibraryCard rollicker S.alice gs2
        stormed = snd (S.addPermanent storm S.alice board)
        searchCasting :: Prompt.Prompt r -> r
        searchCasting p = case p of
          Prompt.CastWhileSearching _ _ options -> Maybe.listToMaybe options
          _ -> payingPrinted host p
        castThere gs = S.runPure searchCasting gs (Cast.castWhileSearching S.manaPerformer S.alice)
        typesOnStack gs = fmap (`Projection.cardTypesOf` gs) (topOfStack gs)
    Spec.assertEqWith
      s
      "CR 702.103d: under Aether Storm the Rollicker is cast from the library as an Aura spell"
      (typesOnStack (castThere stormed))
      (Just (Set.singleton CardType.Enchantment))
    Spec.assertEqWith
      s
      "and without it the same answerer casts the creature spell"
      (typesOnStack (castThere board))
      (Just (Set.fromList [CardType.Creature, CardType.Enchantment]))
  -- CR 702.103d's TARGET half, through CR 601.2c: the bestow candidate is the
  -- one that has to find a creature to enchant, and the printed one is not. Two
  -- boards differing in exactly one permanent, and ONE answerer across both --
  -- the one that names the BESTOW cost -- so what changes is which candidate CR
  -- 601.2b had left for it to name.
  Spec.it s "CR 702.103d / 601.2c: with no creature to enchant only the printed candidate is offered" $ do
    mountain <- S.printingOf s registry "Mountain"
    mammoth <- S.printingOf s registry "War Mammoth"
    rollicker <- S.printingOf s registry "Nyxborn Rollicker"
    let (bare, spellId) = S.handOne rollicker (S.landsInPlay mountain 4)
        (host, hosted) = S.addPermanent mammoth S.alice bare
        castThere gs = S.runPure (bestowing host) gs (S.cast S.alice spellId)
    -- THE gameplay-level pair, first. With nothing to enchant there is no
    -- {1}{R} candidate to name, so CR 601.2b settles on the printed {R} and a
    -- creature spell reaches the stack -- where the whole cast used to unwind at
    -- CR 601.2e and leave the stack empty; see #2911.
    Spec.assertEqWith
      s
      "CR 601.2c: with no creature in play the Rollicker reaches the stack as a creature spell"
      (fmap (\oid -> Projection.cardTypesOf oid (castThere bare)) (topOfStack (castThere bare)))
      (Just (Set.fromList [CardType.Creature, CardType.Enchantment]))
    Spec.assertEqWith
      s
      "and with one to enchant the same answerer takes the bestow cost and leaves an Aura spell"
      (fmap (\oid -> Projection.cardTypesOf oid (castThere hosted)) (topOfStack (castThere hosted)))
      (Just (Set.singleton CardType.Enchantment))
    -- Paid in tapped Mountains, which is what tells an announcement that settled
    -- on the printed cost from one that rewound: {R} is one land, {1}{R} is two,
    -- and a rejected cast taps none.
    Spec.assertEqWith s "and the printed {R} is what was paid for it" (S.tappedCount S.alice (castThere bare)) 1
    Spec.assertEqWith s "against {1}{R} for the bestowed cast" (S.tappedCount S.alice (castThere hosted)) 2
    -- The cast itself is still OFFERED on the creature-less board, which is what
    -- makes the pair a fact about the candidate rather than about the action: CR
    -- 601.2c closed the bestow half alone.
    Spec.assertBool s (S.castable S.alice spellId bare) "CR 601.3: the Rollicker is castable with no creature in play"
    Spec.assertBool s (S.castable S.alice spellId hosted) "control: and with one, off the same four Mountains"

-- The spell CR 601.2a put on the stack -- the incarnation every assertion above
-- reads, since CR 400.7 makes it a different object from the card in the hand.
topOfStack :: GameState.GameState -> Maybe ObjectId.ObjectId
topOfStack gs = case GameState.stack gs of
  oid : _ -> Just oid
  [] -> Nothing

-- The permanent that printing became, found by NAME rather than by the
-- attachment under test: a reading that never attached and one that attached
-- wrongly must both be found, or the assertion would compare two Nothings.
rollickerOn :: Printing.Printing -> GameState.GameState -> Maybe ObjectId.ObjectId
rollickerOn printing gs =
  List.find
    (\oid -> fmap S.nameOf (Game.cardOf oid gs) == Just (S.printingName printing))
    (Game.zoneMembers Zone.Battlefield S.alice gs)

-- CR 601.2b's announcement answered by NAMING a cost rather than an index, and CR
-- 601.2c's target by FILTERING the offered set rather than building a recipient:
-- an answerer that hands back a Recipient.ToObject of the same permanent is a
-- different recipient, and CR 608.2b's re-read drops it silently.
castingFor :: [ManaSymbol.ManaSymbol] -> ObjectId.ObjectId -> Prompt.Prompt r -> r
castingFor wanted host p = case p of
  Prompt.ChooseCost _ _ _ candidates _ ->
    Maybe.fromMaybe (Cost.firstOffered candidates) (List.find ((== Just (ManaCost.MkManaCost wanted)) . Cost.Type.mana . CandidateCost.cost) candidates)
  Prompt.ChooseTargets _ _ _ sets -> fmap (Set.filter ((== Just host) . Recipient.objectOf) . snd) sets
  _ -> S.identityAnswer p

-- The two answerers bestowSpec's boards differ by, and the only thing they differ
-- by: Nyxborn Rollicker's bestow {1}{R} against its printed {R}.
bestowing, payingPrinted :: ObjectId.ObjectId -> Prompt.Prompt r -> r
bestowing = castingFor [ManaSymbol.Generic 1, theRed]
payingPrinted = castingFor [theRed]

-- The one coloured symbol both of Nyxborn Rollicker's costs are written in.
theRed :: ManaSymbol.ManaSymbol
theRed = ManaSymbol.OfType (ManaType.Colored Color.Red)

licidSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
licidSpec s registry = Spec.describe s "Licid" $ do
  -- The discrimination against Modification.LoseAllAbilities, which is the arm
  -- that already existed: the two agree about the ability that was REMOVED and
  -- disagree about the one that was KEPT. So the assertion that separates them is
  -- the FLYING one, read off the enchanted creature, and it comes first.
  Spec.it s "CR 613.1f: the Licid loses the ability it activated and keeps the other one" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    licid <- S.printingOf s registry "Gliding Licid"
    case licidBoard island piker licid of
      Nothing -> Spec.assertFailure s "Gliding Licid should print one activated ability"
      Just (lic, host, after) -> do
        -- FIRST, and the gameplay-level pair: the enchanted creature has the
        -- keyword the Licid's OTHER printed ability grants, which it can only
        -- have through the attachment. A wipe of every ability makes this false.
        Spec.assertBool s (Projection.hasKeyword Keyword.Flying host after) "CR 303.4m: the enchanted creature has flying"
        Spec.assertEqWith
          s
          "and the Licid is the Aura on it"
          (fmap Object.attachedTo (Game.lookupObject lic after))
          (Just (Just (Recipient.ToCreature host)))
        -- Then the removal itself. A no-op removal makes THIS false while leaving
        -- the pair above true, so the two halves of CR 613.1f's scope are
        -- separately observable.
        Spec.assertEqWith s "CR 613.1f: and the ability it activated is gone" (length (Projection.abilitiesOf lic after)) 0
        -- The rest of the sentence, after the behaviour rather than before.
        Spec.assertBool s (Set.member CardType.Enchantment (Projection.cardTypesOf lic after)) "CR 205.1a: the Licid is an Enchantment"
        Spec.assertBool s (not (Set.member CardType.Creature (Projection.cardTypesOf lic after))) "and no longer a Creature"
        Spec.assertBool s (Set.member Subtype.Aura (Projection.subtypesOf lic after)) "CR 205.1b: with the Aura subtype"
        Spec.assertEqWith
          s
          "CR 702.5a: and the granted enchant ability is 'enchant creature'"
          (Card.foldEnchant (Projection.enchantOf lic after))
          (Just (TargetSlot.required Pool.Creatures Nothing))
        Spec.assertBool s (Set.member lic (GameState.battlefield after)) "and CR 704.5m leaves it alone: its host is one its enchant ability admits"
  -- The SCOPE of the removal, as a pair of boards differing in exactly one thing:
  -- the NAME the removal carries. Gliding Licid's own resolution cannot show this
  -- -- Modification.LoseAllAbilities in place of the named arm is observably
  -- identical on that board, since the Licid's other printed ability is a static
  -- one that CR 613.6 spares from a layer-6 strip (Projection.permanentParts'
  -- `removed`) and the enchant the same sentence grants carries a later timestamp
  -- than the removal, so CR 613.9's first Example lands it on top. So the arm's
  -- narrowness is proved HERE instead, by a name that matches nothing.
  --
  -- Gameplay level on both boards: whether alice may activate the ability at all,
  -- with the mana to pay for it either way, so a negative cannot pass for being
  -- broke (CR 602.2).
  Spec.it s "CR 613.1f the removal reads the NAME: one that matches nothing removes nothing" $ do
    island <- S.printingOf s registry "Island"
    licid <- S.printingOf s registry "Gliding Licid"
    let base = S.landsInPlay island 3
        (lic, placed) = S.addPermanent licid S.alice base
        ready = placed {GameState.priority = Just S.alice}
        withRemoval name = S.withEffectAt lic (Timestamp.MkTimestamp 500) (Modification.LoseNamedAbility (AbilityName.MkAbilityName (Text.pack name))) ready
        matching = withRemoval "animate"
        mismatched = withRemoval "no ability has this name"
        activatableOn gs = any (\ability -> Activatable.activatable S.alice lic ability gs) (Projection.abilitiesOf lic gs)
    -- The CONTROL first: with no removal at all the ability is there and usable,
    -- so neither board below can be reading a Licid that never had it.
    Spec.assertBool s (activatableOn ready) "CR 602.2: with no removal alice may activate it"
    -- THE discriminating pair.
    Spec.assertBool s (activatableOn mismatched) "and a removal naming no ability of this card leaves it activatable"
    Spec.assertBool s (not (activatableOn matching)) "while the removal naming it takes it away"
    Spec.assertEqWith s "which is one ability gone rather than every ability" (length (Projection.abilitiesOf lic matching)) 0
    Spec.assertEqWith s "and none gone on the mismatched board" (length (Projection.abilitiesOf lic mismatched)) 1
  -- CR 116.2c, both halves: the offer exists while the effect does, and paying
  -- ends the WHOLE printed sentence rather than one of the four effects it
  -- stored. An implementation that ended only the first would leave an unattached
  -- Aura, which CR 704.5m bins -- a different, visible end state.
  Spec.it s "CR 116.2c: paying the stated cost ends every effect that one sentence stored" $ do
    island <- S.printingOf s registry "Island"
    piker <- S.printingOf s registry "Goblin Piker"
    licid <- S.printingOf s registry "Gliding Licid"
    case licidBoard island piker licid of
      Nothing -> Spec.assertFailure s "Gliding Licid should print one activated ability"
      Just (lic, host, after) -> do
        let ready = after {GameState.priority = Just S.alice}
            paid = S.settleSba (S.runPure S.identityAnswer ready (mapM_ (EndEffect.endEffect S.manaPerformer S.alice . snd) (EndEffect.endable S.alice ready)))
        -- The OFFER, which no printed permission grants: it rides the stored
        -- effect, so it exists only because the ability resolved.
        Spec.assertBool s (offersEnding lic (Action.legalActions S.alice ready)) "CR 116.2c: alice is offered the pay-to-end while the effect is live"
        Spec.assertEqWith s "one sentence is one offer, however many effects it stored" (length (EndEffect.endable S.alice ready)) 1
        -- CR 109.5: "you may pay" is the player who ACTIVATED the ability, and
        -- bob is not them. Asked on the SAME board, and bob holds the same three
        -- Islands alice does (licidBoard stocks both seats), so the only
        -- difference between the two reads is the seat rather than the mana.
        -- data/scenarios/aura's Confiscate case is what parts "activator" from
        -- "current controller".
        Spec.assertBool s (not (offersEnding lic (Action.legalActions S.bob (ready {GameState.priority = Just S.bob})))) "and bob, who did not activate the ability, is not"
        -- FIRST after the payment, and the gameplay-level read: the creature the
        -- Licid was enchanting has lost the keyword, which is the whole of what
        -- the effect was doing to the board.
        Spec.assertBool s (not (Projection.hasKeyword Keyword.Flying host paid)) "and once it is paid the creature loses flying"
        -- Then the Licid's own end state, which is what separates "ended all
        -- four" from "ended the first": a Creature is not an Aura, so CR 704.5m
        -- has nothing to bin and CR 704.5p only unattaches it.
        Spec.assertBool s (Set.member CardType.Creature (Projection.cardTypesOf lic paid)) "CR 611.2a: the Licid is a Creature again"
        Spec.assertEqWith s "CR 704.5p: unattached" (fmap Object.attachedTo (Game.lookupObject lic paid)) (Just Nothing)
        Spec.assertBool s (Set.member lic (GameState.battlefield paid)) "and still on the battlefield rather than in the graveyard"
        Spec.assertEqWith s "with the ability the removal took back again" (length (Projection.abilitiesOf lic paid)) 1
        -- And the offer is gone with the effect: paying twice is not on the menu.
        Spec.assertBool s (not (offersEnding lic (Action.legalActions S.alice (paid {GameState.priority = Just S.alice})))) "and the offer is gone with the effect it ended"

-- The board licidSpec's cases share: alice's Gliding Licid animates itself onto
-- her own Goblin Piker off three Islands -- one for the activation, one for the
-- pay-to-end, one spare so a mana shortfall cannot be what a negative assertion
-- is reading. BOB holds three Islands too, and needs them: the negative half of
-- CR 109.5's "you" is read on this same board, and a seat with no mana would fail
-- Cost.canPay whatever the controller conjunct answered.
--
-- aimAtOffered rather than a hand-built recipient: the slot's pool is
-- Pool.Creatures, which offers Recipient.ToCreature, and a ToObject of the same
-- permanent is dropped by CR 608.2b's re-read with no error.
-- CR 116.2c: is ending an effect of this source among these actions?
offersEnding :: ObjectId.ObjectId -> [Action.Type.Action] -> Bool
offersEnding source = any $ \action -> case action of
  Action.Type.EndEffect offered _ -> offered == source
  _ -> False

licidBoard ::
  Printing.Printing ->
  Printing.Printing ->
  Printing.Printing ->
  Maybe (ObjectId.ObjectId, ObjectId.ObjectId, GameState.GameState)
licidBoard island piker licid =
  let base0 = S.landsFor island S.bob 3 (S.landsInPlay island 3)
      (host, base1) = S.addPermanent piker S.alice base0
      (lic, base2) = S.addPermanent licid S.alice base1
      ready = base2 {GameState.priority = Just S.alice}
   in case Face.activatedAbilities (S.combinedFace licid) of
        [] -> Nothing
        ability : _ ->
          let activated = S.runPure (aimAtOffered host) ready (Activate.activateAbility S.alice lic ability)
              after = S.runPure (aimAtOffered host) activated Stack.resolveTop
           in Just (lic, host, after)

-- CR 400.7a through Parun.Engine.Stack's AURA branch, the other of the two
-- permanent-spell resolutions that carry a text change onto the permanent (the
-- creature-spell one is Parun.ReplacementSpec's Tidewalker case, and
-- Parun.ActivateSpec's Tidal Warrior is the same rule through an activated
-- ability).
--
-- Aspect of Wolf {1}{G} Enchantment -- Aura, whole text: "Enchant creature /
-- Enchanted creature gets +X/+Y, where X is half the number of Forests you
-- control, rounded down, and Y is half the number of Forests you control,
-- rounded up." (oracle checked on Scryfall 2026-08-26)
--
-- Magical Hack ({U}) swaps Forest -> Island on the Aura SPELL, so the static
-- ability the Aura PERMANENT ends up with counts Islands (CR 612.1, CR 613.1c).
-- The swap has to survive CR 400.7's new object, which is what CarryOver.Carried
-- on that branch is for.
--
-- THE TWO COUNTS ARE UNEQUAL AND ODD -- three Forests and seven Islands -- so
-- each leg exercises both roundings and no pair of numbers coincides: +1/+2 on a
-- 2/1 Piker is 3/3, and +3/+4 is 5/5.
auraTextChangeSpec :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> n ()
auraTextChangeSpec s registry = Spec.describe s "AuraTextChange" $ do
  -- The control for data/scenarios/aura/cr-400-7a-hacking-the-aura-spell-leaves-the-permanent.json:
  -- the same board and the same Aura, no Magical Hack.
  Spec.it s "unhacked, the Aura counts the Forests its printed text names" $ do
    (creature, after) <- aspectChain s registry False
    Spec.assertEqWith s "three Forests, so +1/+2 on the 2/1 Piker" (S.powerToughnessOf creature after) (Just (3, 3))

-- alice controls three Forests, seven Islands and a Goblin Piker (2/1), and holds
-- Aspect of Wolf and Magical Hack. The Aura is cast at the Piker and left ON THE
-- STACK; the Hack is then cast at the Aura SPELL and resolved; only then does the
-- Aura resolve and enter attached (CR 303.4). Returns the Piker's id and the
-- final state.
aspectChain :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> Bool -> m (ObjectId.ObjectId, GameState.GameState)
aspectChain s registry hack = do
  forest <- S.printingOf s registry "Forest"
  island <- S.printingOf s registry "Island"
  piker <- S.printingOf s registry "Goblin Piker"
  aspect <- S.printingOf s registry "Aspect of Wolf"
  magicalHack <- S.printingOf s registry "Magical Hack"
  let base = S.landsFor island S.alice 7 (S.landsInPlay forest 3)
      (creature, g1) = S.addPermanent piker S.alice base
      (auraId, g2) = S.addHandCard aspect S.alice g1
      (hackId, g3) = S.addHandCard magicalHack S.alice g2
      onStack = S.runPure (targetingOnly creature) g3 (S.cast S.alice auraId)
      hacked = case (hack, GameState.stack onStack) of
        (True, spellId : _) -> S.runPure (hackAt spellId Subtype.Forest Subtype.Island) onStack (S.cast S.alice hackId >> Stack.resolveTop)
        _ -> onStack
      after = S.runPure S.identityAnswer hacked Stack.resolveTop
  pure (creature, after)

-- Magical Hack aimed at one object, the Parun.ReplacementSpec helper of the same
-- name: the target is FILTERED out of the offered set rather than rebuilt, since
-- a hand-built recipient of the wrong shape would be dropped at CR 608.2b's
-- re-read with no error.
hackAt :: ObjectId.ObjectId -> Subtype.Subtype -> Subtype.Subtype -> Prompt.Prompt r -> r
hackAt oid from to p = case p of
  Prompt.ChooseWordSwap {} -> (TextWord.SubtypeWord from, TextWord.SubtypeWord to)
  _ -> targetingOnly oid p

-- hackAt's target half, which the Aura's own CR 303.4a enchant slot takes too:
-- the offered set is NARROWED rather than rebuilt, because the recipient's TAG is
-- the offer's (aimAt above hands back a ToObject, which a Pool.Creatures slot
-- never offered and CR 608.2b silently drops).
targetingOnly :: ObjectId.ObjectId -> Prompt.Prompt r -> r
targetingOnly oid p = case p of
  Prompt.ChooseTargets _ _ _ sets -> fmap (Set.filter ((==) (Just oid) . Recipient.objectOf) . snd) sets
  _ -> S.identityAnswer p

-- CR 702.92a / 702.163a / 702.182a: living weapon, for Mirrodin! and job select
-- are one sentence three times over -- "When this Equipment enters, create a
-- [token], then attach this Equipment to it" -- so Parun.Engine.Keyword mints all
-- three from one builder and these cases differ only in the token the rule
-- names. They belong here rather than with the other keyword triggers because
-- what is new is the ATTACH: the create binds a slot and the attach in the same
-- clause reads it, which works only because Parun.Engine.Resolve re-reads the live
-- bindings per effect (CR 608.2c).
--
-- Each token's P/T is read AFTER state-based actions, which is what makes the
-- assertion non-vacuous in both directions: an attach that did not happen leaves
-- the Germ a 0/0 that CR 704.5f buries, and leaves the Rebel and the Hero at
-- their printed sizes rather than their equipped ones. The three rules print
-- three different sizes, so no case can pass on another's numbers.
equipmentTokenSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
equipmentTokenSpec s registry = Spec.describe s "EquipmentToken" $ do
  Spec.it s "CR 702.92a whole card: Flayer Husk mints a 0/0 black Phyrexian Germ and equips it in the same resolution, so a 1/1 lives" $ do
    husk <- S.printingOf s registry "Flayer Husk"
    let (equipmentId, minted, settled) = enterAndTrigger (Setup.emptyGame S.bothPlayers) husk
    Spec.assertEqWith s "CR 702.92a: the 0/0 Germ is wearing the Husk, so it is a 1/1 and lives through CR 704.5f" (fmap (\oid -> S.powerToughnessOf oid settled) minted) [Just (1, 1)]
    Spec.assertEqWith s "CR 702.92a: black" (fmap (\oid -> Projection.colorsOf oid settled) minted) [Set.singleton Color.Black]
    Spec.assertEqWith s "CR 702.92a: a Phyrexian Germ" (fmap (\oid -> Projection.subtypesOf oid settled) minted) [Set.fromList [Subtype.Phyrexian, Subtype.Germ]]
    Spec.assertEqWith s "CR 701.3a: the Husk really is attached to the token it made" (fmap Object.attachedTo (Game.lookupObject equipmentId settled)) (Just (fmap Recipient.ToCreature (Maybe.listToMaybe minted)))
  Spec.it s "CR 702.163a whole card: Barbed Batterfist mints a 2/2 red Rebel and equips it, making it a 3/1" $ do
    batterfist <- S.printingOf s registry "Barbed Batterfist"
    let (equipmentId, minted, settled) = enterAndTrigger (Setup.emptyGame S.bothPlayers) batterfist
    Spec.assertEqWith s "CR 702.163a: the 2/2 Rebel wearing the Batterfist's +1/-1 is a 3/1" (fmap (\oid -> S.powerToughnessOf oid settled) minted) [Just (3, 1)]
    Spec.assertEqWith s "CR 702.163a: red" (fmap (\oid -> Projection.colorsOf oid settled) minted) [Set.singleton Color.Red]
    Spec.assertEqWith s "CR 702.163a: a Rebel" (fmap (\oid -> Projection.subtypesOf oid settled) minted) [Set.singleton Subtype.Rebel]
    Spec.assertEqWith s "CR 701.3a: the Batterfist really is attached to the token it made" (fmap Object.attachedTo (Game.lookupObject equipmentId settled)) (Just (fmap Recipient.ToCreature (Maybe.listToMaybe minted)))
  Spec.it s "CR 702.182a whole card: Monk's Fist mints a 1/1 colorless Hero and equips it, making it a 2/1 Hero Monk" $ do
    fist <- S.printingOf s registry "Monk's Fist"
    let (equipmentId, minted, settled) = enterAndTrigger (Setup.emptyGame S.bothPlayers) fist
    Spec.assertEqWith s "CR 702.182a: the 1/1 Hero wearing the Fist's +1/+0 is a 2/1" (fmap (\oid -> S.powerToughnessOf oid settled) minted) [Just (2, 1)]
    -- The Monk is the FIST's own AddSubtype, so it is visible only while the
    -- attach held; the Hero is the rule's.
    Spec.assertEqWith s "CR 702.182a: a Hero, and a Monk because it is the equipped creature" (fmap (\oid -> Projection.subtypesOf oid settled) minted) [Set.fromList [Subtype.Hero, Subtype.Monk]]
    Spec.assertEqWith s "CR 702.182a: colorless, which is the ABSENCE of a colour rather than a colour" (fmap (\oid -> Projection.colorsOf oid settled) minted) [Set.empty]
    Spec.assertEqWith s "CR 701.3a: the Fist really is attached to the token it made" (fmap Object.attachedTo (Game.lookupObject equipmentId settled)) (Just (fmap Recipient.ToCreature (Maybe.listToMaybe minted)))
  -- The trap the rule states and the shape the opcode is built around: CR 113.7a
  -- keeps the ability resolving after its source has left, so the token is
  -- created either way (CR 111.1) and only the ATTACH is refused -- CR 701.3b,
  -- there being no Equipment on the battlefield to move. A pair of boards
  -- differing in exactly one thing: whether the Husk was destroyed while its own
  -- trigger was on the stack.
  Spec.it s "CR 701.3b/113.7a whole card: destroying the Husk in response still makes the Germ, and the 0/0 then dies to CR 704.5f" $ do
    husk <- S.printingOf s registry "Flayer Husk"
    let (equipmentId, staged) = S.entersWithTrigger husk S.alice (Setup.emptyGame S.bothPlayers)
        placed = S.runPure S.identityAnswer staged Engine.settleForPriority
        -- One thing different: the Husk is gone before its own trigger resolves.
        killed = S.runPure S.identityAnswer placed (Event.destroy (pure ()) Regenerability.Regenerable [equipmentId])
        run gs =
          let resolved = S.runPure S.identityAnswer gs Stack.resolveTop
           in (S.tokensOf resolved, S.runPure S.identityAnswer resolved Engine.settleForPriority)
        (goneMinted, goneSettled) = run killed
        (liveMinted, liveSettled) = run placed
    -- The gameplay-level pair first: the token exists on both boards, and only
    -- its survival differs.
    Spec.assertEqWith s "CR 111.1: the Germ is created even though the Husk has left" (length goneMinted) 1
    Spec.assertEqWith s "CR 701.3b/704.5f: nothing attached to it, so the 0/0 Germ is buried" (fmap (\oid -> S.powerToughnessOf oid goneSettled) goneMinted) [Nothing]
    Spec.assertEqWith s "the same board with the Husk alive keeps a 1/1" (fmap (\oid -> S.powerToughnessOf oid liveSettled) liveMinted) [Just (1, 1)]
    Spec.assertEqWith s "and the Husk was really gone before the trigger resolved" (Game.lookupObject equipmentId goneSettled) Nothing
  -- CR 707.2: living weapon is printed rules text and so a copiable value, and
  -- CR 707.5 gives the copy's own entry trigger its chance -- a permanent entering as a
  -- COPY of the Husk mints its own Germ and equips that one. Phyrexian
  -- Metamorph is the tripwire board: the keyword is read off the PROJECTION
  -- (Projection.mintedTriggeredAbilitiesOf over PC.keywords), never off the
  -- printed card, which here says "Phyrexian Metamorph".
  Spec.it s "CR 707.2/707.5 whole cards: a Phyrexian Metamorph copying Flayer Husk mints a second Germ and equips that one" $ do
    husk <- S.printingOf s registry "Flayer Husk"
    metamorph <- S.printingOf s registry "Phyrexian Metamorph"
    let (huskId, firstGerm, afterHusk) = enterAndTrigger (Setup.emptyGame S.bothPlayers) husk
        (_, staged) = S.spellOnStack metamorph S.alice afterHusk
        entered = S.runPure (copyOf huskId) staged Stack.resolveTop
        placed = S.runPure (copyOf huskId) entered Engine.settleForPriority
        triggered = S.runPure (copyOf huskId) placed Stack.resolveTop
        settled = S.runPure (copyOf huskId) triggered Engine.settleForPriority
        secondGerm = filter (\oid -> notElem oid firstGerm) (S.tokensOf triggered)
        metamorphIds = printedOnBattlefield "Phyrexian Metamorph" settled
    Spec.assertEqWith s "CR 707.5: the copy's own Germ is a 1/1, so the copied living weapon both minted and attached" (fmap (\oid -> S.powerToughnessOf oid settled) secondGerm) [Just (1, 1)]
    Spec.assertEqWith s "CR 701.3a: the Metamorph equips its OWN Germ, not the Husk's" (fmap (\oid -> fmap Object.attachedTo (Game.lookupObject oid settled)) metamorphIds) [Just (fmap Recipient.ToCreature (Maybe.listToMaybe secondGerm))]
    Spec.assertEqWith s "and the Husk's own Germ is still a 1/1 wearing the Husk" (fmap (\oid -> S.powerToughnessOf oid settled) firstGerm) [Just (1, 1)]
    Spec.assertEqWith s "the copy really happened: it is a Flayer Husk by name (CR 707.2)" (fmap (\oid -> Projection.namesOf oid settled) metamorphIds) [Set.singleton (CardName.MkCardName (Text.pack "Flayer Husk"))]
  -- CR 614.16 doubles the create, so living weapon's "it" stands for two Germs
  -- -- Parun.Engine.Resolve.bindObjects binds BOTH, which is what the rulings on
  -- Anointed Procession and Flamerush Rider require of every rider a creating
  -- effect attaches. The attach is the one reader that cannot take them all:
  -- CR 301.5c, "an Equipment can't equip more than one creature. If a spell or
  -- ability would cause an Equipment to equip more than one creature, the
  -- Equipment's controller chooses which creature it equips". Batterskull's own
  -- ruling states the outcome -- the Equipment attaches to one of them and the
  -- other dies.
  --
  -- Pinned to the LAST Germ offered rather than searched: the engine's own
  -- fallback is the first, so answering last is what discriminates.
  Spec.it s "CR 301.5c whole cards: under Doubling Season the Husk mints two Germs and its controller picks which one it equips" $ do
    husk <- S.printingOf s registry "Flayer Husk"
    doublingSeason <- S.printingOf s registry "Doubling Season"
    let (_, doubled) = S.addPermanent doublingSeason S.alice (Setup.emptyGame S.bothPlayers)
        (equipmentId, staged) = S.entersWithTrigger husk S.alice doubled
        placed = S.runPure equipLastOffered staged Engine.settleForPriority
        resolved = S.runPure equipLastOffered placed Stack.resolveTop
        settled = S.runPure equipLastOffered resolved Engine.settleForPriority
        minted = List.sort (S.tokensOf resolved)
    Spec.assertEqWith s "CR 614.16: the replacement really doubled living weapon's create" (length minted) 2
    -- The gameplay-level assertion: the Germ the controller named is the one
    -- wearing the Husk, so it is a 1/1, and the other 0/0 is buried (CR 704.5f).
    Spec.assertEqWith s "CR 301.5c: the SECOND Germ was named, so only it survives as a 1/1" (fmap (\oid -> S.powerToughnessOf oid settled) minted) [Nothing, Just (1, 1)]
    Spec.assertEqWith s "CR 701.3a: the Husk is attached to that same Germ" (fmap Object.attachedTo (Game.lookupObject equipmentId settled)) (Just (fmap Recipient.ToCreature (Maybe.listToMaybe (drop 1 minted))))

-- Put the Equipment onto the battlefield with its CR 603.6a entry event, let CR
-- 603.3 place the keyword trigger on the stack, resolve it, then settle
-- state-based actions. S.identityAnswer throughout: none of these three keywords
-- asks anything on an ordinary board, which is the point -- CR 111.2 names the
-- creator and the rule names the token, so there is no choice to make. A board
-- carrying a token doubler does pose one (CR 301.5c), which is why the doubled
-- case below builds its own run rather than going through here.
enterAndTrigger :: GameState.GameState -> Printing.Printing -> (ObjectId.ObjectId, [ObjectId.ObjectId], GameState.GameState)
enterAndTrigger gs printing =
  let (equipmentId, staged) = S.entersWithTrigger printing S.alice gs
      placed = S.runPure S.identityAnswer staged Engine.settleForPriority
      resolved = S.runPure S.identityAnswer placed Stack.resolveTop
   in (equipmentId, S.tokensOf resolved, S.runPure S.identityAnswer resolved Engine.settleForPriority)

-- CR 301.5c's choice of which of several minted Germs the Equipment equips,
-- pinned to the LAST candidate offered: the engine's own fallback is the first,
-- so a mutation cannot be repaired into the same answer.
equipLastOffered :: Prompt.Prompt r -> r
equipLastOffered p = case p of
  Prompt.ChooseAttachment _ _ _ offered -> NonEmpty.last offered
  _ -> S.identityAnswer p

-- CR 707.5's as-enters copy choice, pinned to ONE object rather than searched,
-- so a mutation cannot be repaired by the answerer finding another legal source
-- (Parun.CopySpec's copyNamed, the same posture).
copyOf :: ObjectId.ObjectId -> Prompt.Prompt r -> r
copyOf wanted p = case p of
  Prompt.ChooseCopyTarget {} -> Just wanted
  _ -> S.identityAnswer p

-- The battlefield objects whose PRINTED face carries this name -- which is how a
-- copy is found, its projected name being the copied card's.
printedOnBattlefield :: String -> GameState.GameState -> [ObjectId.ObjectId]
printedOnBattlefield name gs =
  let isIt oid = fmap Face.name (Game.faceOf oid gs) == Just (CardName.MkCardName (Text.pack name))
   in filter isIt (Set.toList (GameState.battlefield gs))

-- CR 601.2c then CR 115.6: announces ONE target for every slot and aims it at
-- `oid`. Top level for aimedAtObject's reason -- the answerer must stay rank-1
-- polymorphic in the prompt's result type.
announcingOneAt :: ObjectId.ObjectId -> Prompt.Prompt r -> r
announcingOneAt oid p = case p of
  Prompt.AnnounceTargets _ _ _ offers -> fmap (const 1) offers
  Prompt.ChooseTargets _ _ _ sets -> S.preferring ((==) (Just oid) . Recipient.objectOf) sets
  _ -> S.identityAnswer p

-- CR 115.6: declines every optional slot, announcing zero targets. The ONE thing
-- that differs from announcingOneAt above, so the pair of boards below differ in
-- exactly one decision.
announcingNone :: Prompt.Prompt r -> r
announcingNone p = case p of
  Prompt.AnnounceTargets _ _ _ offers -> fmap (const 0) offers
  _ -> S.identityAnswer p

-- Preston Garvey, Minuteman {2}{R}{G}{W} Legendary Creature -- Human Soldier 4/4:
-- "At the beginning of combat on your turn, create a green Aura enchantment token
-- named Settlement attached to up to one target land you control. It has enchant
-- land and 'Enchanted land has \"{T}: Add one mana of any color.\"' / Whenever
-- Preston Garvey attacks, untap each enchanted permanent you control." (Oracle
-- text checked 2026-09-16.)
--
-- The pool's producer of CR 303.4i: an effect that NAMES what the Aura it puts
-- onto the battlefield arrives attached to (EntryRiders.attachedTo), which is
-- what makes the rule's "an object ... that is undefined" reachable -- the slot
-- is "up to one target", so a seat may announce none. CR 303.4i's last sentence
-- and CR 303.4g's are the same sentence, and this is the board that reaches it:
-- "If the Aura is a token, it isn't created."
--
-- TWO LANDS, so the attachment is a real choice: with one land, a token attached
-- by CR 303.4f's entry choice and one attached by the effect's own target would
-- land in the same place and no assertion could part them.
--
-- READ BEFORE THE STATE-BASED ACTIONS, which is the whole of what makes the
-- negative case discriminate: an Aura token created unattached would be buried by
-- CR 704.5m and cease to exist by CR 111.7 on the very next check, so a board read
-- after that pass cannot tell "never created" from "created and buried". So the
-- trigger is resolved with Stack.resolveTop alone and the tokens counted there;
-- the settled board is read afterwards, where the attached token must still stand.
auraTokenSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
auraTokenSpec s registry =
  let combatStep = Phase.Combat CombatStep.BeginningOfCombat
      -- CR 603.2b's record this trigger matches, written by hand rather than by
      -- walking a whole turn, historySpec's shape one phase over.
      beginCombat gs = Event.recordEvent (GameEvent.StepBegan (StepBegan.MkStepBegan combatStep S.alice)) (gs {GameState.phase = combatStep, GameState.activePlayer = S.alice})
      -- CR 603.3b / 601.2c: the trigger goes on the stack here, which is where the
      -- announcement is made -- so the answerer that differs between the two cases
      -- is this one's.
      settle :: (forall r. Prompt.Prompt r -> r) -> GameState.GameState -> GameState.GameState
      settle answer gs = snd (Engine.runGamePure answer gs Engine.settleForPriority)
      -- CR 608.2 alone: no state-based actions, for the reason above.
      resolveTop gs = S.runPure S.identityAnswer gs Stack.resolveTop
      settleSba gs = snd (Engine.runGamePure S.identityAnswer gs Engine.settleForPriority)
      auraTokens gs = filter (\oid -> Set.member Subtype.Aura (Projection.subtypesOf oid gs)) (S.tokensOf gs)
      board = do
        preston <- S.printingOf s registry "Preston Garvey, Minuteman"
        forest <- S.printingOf s registry "Forest"
        mountain <- S.printingOf s registry "Mountain"
        let (_, gs1) = S.addPermanent preston S.alice (Setup.emptyGame S.bothPlayers)
            (forestId, gs2) = S.addPermanent forest S.alice gs1
            (mountainId, gs3) = S.addPermanent mountain S.alice gs2
        pure (forestId, mountainId, beginCombat gs3)
   in Spec.describe s "AuraToken" $ do
        -- CR 303.4i's other half, and the one that makes the rider worth having:
        -- the effect names the host, so CR 303.4f's entry choice never runs.
        Spec.it s "CR 303.4i whole card: the Aura token enters attached to the land the effect named" $ do
          (forestId, mountainId, staged) <- board
          let resolved = resolveTop (settle (announcingOneAt mountainId) staged)
              settled = settleSba resolved
          case auraTokens resolved of
            [token] -> do
              Spec.assertEqWith s "CR 303.4i: attached to the land the effect targeted, and not to the other one" (fmap Object.attachedTo (Game.lookupObject token settled)) (Just (Just (Recipient.ToObject mountainId)))
              -- CR 613.1f: the token's own static ability reaches the land only
              -- through the attachment, so this is the attachment read off the
              -- board a player sees rather than off Object.attachedTo.
              Spec.assertBool s (length (Projection.abilitiesOf mountainId settled) > length (Projection.abilitiesOf forestId settled)) "the enchanted land has an activated ability the other land has not"
              Spec.assertBool s (Set.member token (GameState.battlefield settled)) "CR 704.5m: legally attached, so the token survives the state-based actions"
            other -> Spec.assertFailure s ("expected exactly one Aura token, got " <> show (length other))
        -- THE PROVING CASE. One decision different from the case above: the seat
        -- announces zero targets for "up to one target land you control", which is
        -- rule 303.4i's undefined object. CR 115.6 makes the trigger untargeted
        -- rather than illegally targeted, so it resolves (Resolve.targetsAllIllegal
        -- measures the targets CHOSEN) -- and creates nothing.
        Spec.it s "CR 303.4i whole card: with no land named, the Aura token isn't created at all" $ do
          (forestId, mountainId, staged) <- board
          let resolved = resolveTop (settle announcingNone staged)
          Spec.assertEqWith s "CR 303.4i: the Aura token isn't created" (auraTokens resolved) []
          Spec.assertEqWith s "so nothing was minted at all, before any state-based action could bury it" (S.tokensOf resolved) []
          Spec.assertEqWith s "and neither land gained the token's ability" (length (Projection.abilitiesOf mountainId resolved), length (Projection.abilitiesOf forestId resolved)) (length (Projection.abilitiesOf mountainId staged), length (Projection.abilitiesOf forestId staged))

-- Animate Dead {1}{B} Enchantment -- Aura -- "Enchant creature card in a
-- graveyard / When this Aura enters, if it's on the battlefield, it loses
-- 'enchant creature card in a graveyard' and gains 'enchant creature put onto the
-- battlefield with this Aura.' Return enchanted creature card to the battlefield
-- under your control and attach this Aura to it. When this Aura leaves the
-- battlefield, that creature's controller sacrifices it. / Enchanted creature
-- gets -1/-0." (Oracle text checked against api.scryfall.com, 2026-09-25.)
--
-- Bob's Goblin Piker (2/1) is the target, so "under your control" and the
-- owner's graveyard it is sacrificed into are two different players. Between
-- the Aura entering and its trigger resolving it enchants a graveyard card,
-- which CR 303.4c / 704.5m must not bury: settleSba runs in that window.
animateDeadSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
animateDeadSpec s registry = Spec.describe s "Animate Dead" $ do
  let setUp = do
        swamp <- S.printingOf s registry "Swamp"
        piker <- S.printingOf s registry "Goblin Piker"
        animate <- S.printingOf s registry "Animate Dead"
        let (pikerCard, base0) = S.addGraveyardCard piker S.bob (S.landsInPlay swamp 2)
            (gs, spellId) = S.handOne animate base0
            cast = snd (Engine.runGamePure (aimedAtObject pikerCard) gs (S.cast S.alice spellId))
        pure (pikerCard, cast)
      step game gs = snd (Engine.runGamePure S.identityAnswer gs game)
      pikerName = CardName.MkCardName (Text.pack "Goblin Piker")
      animateName = CardName.MkCardName (Text.pack "Animate Dead")
      named name zone pid gs = filter (\oid -> fmap Face.name (Game.faceOf oid gs) == Just name) (Game.zoneMembers zone pid gs)
  Spec.it s "CR 303.4c / 400.7: the returned creature is alice's, enchanted, at -1/-0; leaving sacrifices it" $ do
    (_, cast) <- setUp
    let entered = S.settleSba (step Stack.resolveTop cast)
        returned = S.settleSba (step Stack.resolveTop (step (Engine.placePendingTriggers []) entered))
        creatures = named pikerName Zone.Battlefield S.bob returned
        -- FIRST, and read off every returned Piker rather than a matched one, so
        -- an Aura that fell off or a creature left in the graveyard reddens THIS.
        enchantedBy creature = fmap (\aura -> fmap Face.name (Game.faceOf aura returned)) (attachedTo creature returned)
    Spec.assertEqWith
      s
      "the Piker is back under alice's control, Animate Dead on it, at 1 power"
      (fmap (\creature -> (Projection.controllerOf creature returned, enchantedBy creature, Projection.powerOf creature returned)) creatures)
      [(Just S.alice, [Just animateName], Just 1)]
    let gone = S.settleSba (step (Foldable.traverse_ (\oid -> Event.changeZone (pure ()) oid Zone.Graveyard) (concatMap (`attachedTo` returned) creatures)) returned)
        sacrificed = S.settleSba (step Stack.resolveTop (step (Engine.placePendingTriggers []) gone))
    Spec.assertEqWith
      s
      "the leaves trigger sacrifices it into bob's graveyard"
      (named pikerName Zone.Battlefield S.bob sacrificed, length (named pikerName Zone.Graveyard S.bob sacrificed))
      ([], 1)
  Spec.it s "CR 608.3b: the Aura spell whose graveyard target left does not resolve" $ do
    (pikerCard, cast) <- setUp
    let exiled = step (Event.changeZone (pure ()) pikerCard Zone.Exile) cast
        resolved = S.settleSba (step Stack.resolveTop exiled)
    Spec.assertEqWith
      s
      "Animate Dead is in alice's graveyard, not on the battlefield"
      (named animateName Zone.Battlefield S.alice resolved, length (named animateName Zone.Graveyard S.alice resolved))
      ([], 1)

-- Effect.AttachAll: every permanent an ObjectRef names moves to ONE destination
-- chosen as the effect resolves (CR 701.3a). Oracle text re-fetched from
-- Scryfall 2026-09-27 for all five cards.
--
-- Glamer Spinners {4}{W/U} 2/4: "When this creature enters, attach all Auras
-- enchanting target permanent to another permanent with the same controller."
-- Its 2008-05-01 rulings: the receiver "can't be the targeted permanent, it must
-- have the same controller as the targeted permanent, and it must be able to be
-- enchanted by all the Auras ... If you can't choose a permanent that meets all
-- those criteria, the Auras won't move."
--
-- THE BOARD, in ObjectId order, since the offer is ascending and the answerer
-- takes it by index. Alice's Goblin Piker first: an unfilled
-- Filter.Context.slotControllers makes Filter.ControllerRelatesToBound vacuously
-- TRUE and would offer it. Bob's Island next, which no Aura here can enchant.
-- Then bob's Apostle of Purifying Light, protection from black (CR 702.16c): it
-- could host Pacifism but not Unholy Strength, so a per-Aura reading of the
-- ruling offers it and the "all" reading does not. Then the target, bob's
-- Foriysian Brigade ("another"). Only then bob's Hill Giant and Berserkers of
-- Blood Ridge, the two receivers the ruling admits -- two, so the choice is
-- really asked.
groupAttachSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
groupAttachSpec s registry =
  let -- Targets FILTERED out of the offer, never built; the destination by INDEX.
      spinnersAnswer :: ObjectId.ObjectId -> (NonEmpty.NonEmpty ObjectId.ObjectId -> ObjectId.ObjectId) -> Prompt.Prompt r -> r
      spinnersAnswer victim choose p = case p of
        Prompt.ChooseTargets _ _ _ sets -> fmap (Set.filter ((== Just victim) . Recipient.objectOf) . snd) sets
        Prompt.ChoosePermanent _ _ _ offered _ -> choose offered
        _ -> S.identityAnswer p
      settle :: (forall r. Prompt.Prompt r -> r) -> GameState.GameState -> GameState.GameState
      settle answer gs = S.runPure answer gs Engine.settleForPriority
      hostOf oid gs = Game.lookupObject oid gs >>= Object.attachedTo >>= Recipient.objectOf
      spinnersBoard withReceivers = do
        island <- S.printingOf s registry "Island"
        spinners <- S.printingOf s registry "Glamer Spinners"
        piker <- S.printingOf s registry "Goblin Piker"
        apostle <- S.printingOf s registry "Apostle of Purifying Light"
        brigade <- S.printingOf s registry "Foriysian Brigade"
        giant <- S.printingOf s registry "Hill Giant"
        berserkers <- S.printingOf s registry "Berserkers of Blood Ridge"
        unholy <- S.printingOf s registry "Unholy Strength"
        pacifism <- S.printingOf s registry "Pacifism"
        let (decoy, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
            g2 = S.landsFor island S.bob 1 g1
            (warded, g3) = S.addPermanent apostle S.bob g2
            (victim, g4) = S.addPermanent brigade S.bob g3
            (receivers, g5) =
              if withReceivers
                then
                  let (a, h1) = S.addPermanent giant S.bob g4
                      (b, h2) = S.addPermanent berserkers S.bob h1
                   in ([a, b], h2)
                else ([], g4)
            (strength, g6) = S.addPermanent unholy S.alice g5
            (pacified, g7) = S.addPermanent pacifism S.alice g6
            (_, entered) = S.entersWithTrigger spinners S.alice (S.attach pacified victim (S.attach strength victim g7))
        pure (decoy, warded, victim, receivers, strength, pacified, entered)
   in Spec.describe s "AttachAll" $ do
        Spec.it s "CR 701.3a Glamer Spinners moves every Aura to one receiver that can host them all" $ do
          (decoy, warded, victim, receivers, strength, pacified, entered) <- spinnersBoard True
          case receivers of
            [giant, berserkers] -> do
              let run choose =
                    let answer :: Prompt.Prompt r -> r
                        answer = spinnersAnswer victim choose
                     in S.runPure answer (settle answer entered) Stack.resolveTop
                  taking = run NonEmpty.head
                  takingLast = run NonEmpty.last
              -- THE gameplay-level assertion, ahead of every proxy: both Auras
              -- are on the FIRST receiver offered. A vacuous same-controller
              -- atom would offer alice's Piker first, a per-Aura host test the
              -- warded Apostle, a missing "another" the Brigade itself.
              Spec.assertEqWith s "both Auras went to bob's Hill Giant" (hostOf strength taking, hostOf pacified taking) (Just giant, Just giant)
              Spec.assertEqWith s "and in the other leg both to his Berserkers" (hostOf strength takingLast, hostOf pacified takingLast) (Just berserkers, Just berserkers)
              Spec.assertEqWith s "the Giant is 3/3 + 2/+1" (S.powerToughnessOf giant taking) (Just (5, 4))
              Spec.assertEqWith s "the Brigade is a plain 2/4 again" (S.powerToughnessOf victim taking) (Just (2, 4))
              Spec.assertEqWith s "alice's Piker and bob's Apostle carry nothing" (S.powerToughnessOf decoy taking, S.powerToughnessOf warded taking) (Just (2, 1), Just (2, 1))
            _ -> Spec.assertFailure s "the fixture wanted two receivers"
        -- The same board less the two receivers, the one difference: the warded
        -- Apostle could take Pacifism alone, and the ruling says neither moves.
        Spec.it s "CR 701.3a with no receiver able to host every Aura, none moves" $ do
          (_, warded, victim, _, strength, pacified, entered) <- spinnersBoard False
          let answer :: Prompt.Prompt r -> r
              answer = spinnersAnswer victim NonEmpty.head
              after = S.runPure answer (settle answer entered) Stack.resolveTop
          Spec.assertEqWith s "both Auras stay on the Brigade" (hostOf strength after, hostOf pacified after) (Just victim, Just victim)
          Spec.assertEqWith s "the Apostle took nothing" (S.powerToughnessOf warded after) (Just (2, 1))
          Spec.assertEqWith s "and the trigger did resolve" (length (GameState.stack after)) 0
        -- Heavenly Blademaster {5}{W} 3/6: "When this creature enters, you may
        -- attach any number of Auras and Equipment you control to it. Other
        -- creatures you control get +1/+1 for each Aura and Equipment attached to
        -- this creature." Alice takes everything offered but Dunedain Blade, so
        -- bob's Batterfist would move were it ever offered.
        Spec.it s "CR 608.2d Heavenly Blademaster takes the Auras and Equipment alice chooses" $ do
          blademaster <- S.printingOf s registry "Heavenly Blademaster"
          piker <- S.printingOf s registry "Goblin Piker"
          unholy <- S.printingOf s registry "Unholy Strength"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          blade <- S.printingOf s registry "Dúnedain Blade"
          batterfist <- S.printingOf s registry "Barbed Batterfist"
          let (carrier, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
              (strength, g2) = S.addPermanent unholy S.alice g1
              (split, g3) = S.addPermanent bonesplitter S.alice g2
              (left, g4) = S.addPermanent blade S.alice g3
              (bobsGear, g5) = S.addPermanent batterfist S.bob g4
              (angel, entered) = S.entersWithTrigger blademaster S.alice (S.attach strength carrier g5)
              answer :: Prompt.Prompt r -> r
              answer p = case p of
                Prompt.ChooseAnyNumber _ _ _ AnyNumberOf.Permanents offered _ _ -> Set.fromList (filter (/= left) offered)
                _ -> S.identityAnswer p
              after = S.runPure answer (settle answer entered) Stack.resolveTop
          Spec.assertEqWith s "Unholy Strength and Bonesplitter are on the Blademaster" (hostOf strength after, hostOf split after) (Just angel, Just angel)
          Spec.assertEqWith s "the Blade alice left stays unattached" (hostOf left after) Nothing
          Spec.assertEqWith s "bob's Batterfist was never offered" (hostOf bobsGear after) Nothing
          Spec.assertEqWith s "the Blademaster is 3/6 + 2/+1 + 2/+0" (S.powerToughnessOf angel after) (Just (7, 7))
          Spec.assertEqWith s "and the Piker gets +2/+2 for the two" (S.powerToughnessOf carrier after) (Just (4, 3))
        -- Beatrix, Loyal General {4}{W}{W} 4/4 vigilance: "At the beginning of
        -- combat on your turn, you may attach any number of Equipment you
        -- control to target creature you control." The destination is the
        -- TARGET, read through Filter.IsBound; Dunedain Blade starts on Beatrix.
        Spec.it s "CR 701.3a Beatrix attaches the chosen Equipment to her target" $ do
          beatrix <- S.printingOf s registry "Beatrix, Loyal General"
          piker <- S.printingOf s registry "Goblin Piker"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          blade <- S.printingOf s registry "Dúnedain Blade"
          let (general, g1) = S.addPermanent beatrix S.alice (Setup.emptyGame S.bothPlayers)
              (carrier, g2) = S.addPermanent piker S.alice g1
              (split, g3) = S.addPermanent bonesplitter S.alice g2
              (worn, g4) = S.addPermanent blade S.alice g3
              staged = S.withEvents [GameEvent.StepBegan (StepBegan.MkStepBegan (Phase.Combat CombatStep.BeginningOfCombat) S.alice)] (S.attach worn general g4)
              answer :: Prompt.Prompt r -> r
              answer p = case p of
                Prompt.ChooseTargets _ _ _ sets -> fmap (Set.filter ((== Just carrier) . Recipient.objectOf) . snd) sets
                Prompt.ChooseAnyNumber _ _ _ AnyNumberOf.Permanents offered _ _ -> Set.fromList offered
                _ -> S.identityAnswer p
              after = S.runPure answer (settle answer staged) Stack.resolveTop
          Spec.assertEqWith s "both Equipment are on the Piker" (hostOf split after, hostOf worn after) (Just carrier, Just carrier)
          Spec.assertEqWith s "which is 2/1 + 2/+0 + 2/+1" (S.powerToughnessOf carrier after) (Just (6, 2))
          Spec.assertEqWith s "and Beatrix is a plain 4/4" (S.powerToughnessOf general after) (Just (4, 4))

-- Effect.AttachAll's printed producers past the five above: a TARGET group
-- (Armory Automaton, Thorin), a destination read off the trigger's event
-- (Super-Soldier Serum), and a gated clause (Battlefield Improvisation). Oracle
-- text re-fetched from Scryfall 2026-09-27 for all four.
groupAttachCardsSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
groupAttachCardsSpec s registry =
  let settle :: (forall r. Prompt.Prompt r -> r) -> GameState.GameState -> GameState.GameState
      settle answer gs = S.runPure answer gs Engine.settleForPriority
      hostOf oid gs = Game.lookupObject oid gs >>= Object.attachedTo >>= Recipient.objectOf
      slot = SlotName.MkSlotName . Text.pack
   in Spec.describe s "AttachAll producers" $ do
        -- Armory Automaton {3} 2/2: "Whenever this creature enters or attacks,
        -- you may attach any number of target Equipment to it. (Control of the
        -- Equipment doesn't change.)" Alice targets her Bonesplitter (on her
        -- Piker) and bob's Barbed Batterfist (on his Giant), and not her Dunedain
        -- Blade. The declining leg differs in the one answer.
        Spec.it s "CR 701.3a Armory Automaton takes the Equipment it targeted, bob's among them" $ do
          automaton <- S.printingOf s registry "Armory Automaton"
          piker <- S.printingOf s registry "Goblin Piker"
          giant <- S.printingOf s registry "Hill Giant"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          blade <- S.printingOf s registry "Dúnedain Blade"
          batterfist <- S.printingOf s registry "Barbed Batterfist"
          let (carrier, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
              (bobs, g2) = S.addPermanent giant S.bob g1
              (split, g3) = S.addPermanent bonesplitter S.alice g2
              (left, g4) = S.addPermanent blade S.alice g3
              (bobsGear, g5) = S.addPermanent batterfist S.bob g4
              (construct, entered) = S.entersWithTrigger automaton S.alice (S.attach bobsGear bobs (S.attach split carrier g5))
              run decision =
                let answer :: Prompt.Prompt r -> r
                    answer p = case p of
                      Prompt.AnnounceTargets {} -> fmap (const 2) (S.identityAnswer p)
                      Prompt.ChooseTargets _ _ _ sets -> fmap (Set.filter ((/= Just left) . Recipient.objectOf) . snd) sets
                      Prompt.ChooseOptional {} -> decision
                      _ -> S.identityAnswer p
                 in S.runPure answer (settle answer entered) Stack.resolveTop
              taken = run OptionalDecision.Exercises
              declined = run OptionalDecision.Declines
          Spec.assertEqWith s "Bonesplitter and bob's Batterfist are on the Automaton" (hostOf split taken, hostOf bobsGear taken) (Just construct, Just construct)
          Spec.assertEqWith s "declining moves neither" (hostOf split declined, hostOf bobsGear declined) (Just carrier, Just bobs)
          Spec.assertEqWith s "the untargeted Blade stays unattached" (hostOf left taken) Nothing
          Spec.assertEqWith s "the Automaton is 2/2 + 2/+0 + 1/-1" (S.powerToughnessOf construct taken) (Just (5, 1))
          Spec.assertEqWith s "bob still controls his Batterfist" (Projection.controllerOf bobsGear taken) (Just S.bob)
        -- Thorin, Mountain-king {3}{R} 3/4 trample: "When Thorin enters, attach
        -- any number of target Equipment you control to target creature you
        -- control. When one or more Equipment become attached to that creature
        -- this way, that creature deals damage equal to its power to up to one
        -- target creature." Alice's Hill Giant is the destination; bob's Hill
        -- Giant the victim, its damage read before CR 704.5g can destroy it. The
        -- empty leg differs only in how many Equipment are targeted.
        Spec.it s "CR 603.12 Thorin's Equipment go to its target, which then deals damage equal to its power" $ do
          thorin <- S.printingOf s registry "Thorin, Mountain-king"
          piker <- S.printingOf s registry "Goblin Piker"
          giant <- S.printingOf s registry "Hill Giant"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          blade <- S.printingOf s registry "Dúnedain Blade"
          let (carrier, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
              (hitter, g2) = S.addPermanent giant S.alice g1
              (victim, g3) = S.addPermanent giant S.bob g2
              (split, g4) = S.addPermanent bonesplitter S.alice g3
              (left, g5) = S.addPermanent blade S.alice g4
              (_, entered) = S.entersWithTrigger thorin S.alice (S.attach split carrier g5)
              run gear =
                let wanted name oid
                      | name == slot "equipment" = maybe False (`elem` gear) oid
                      | name == slot "creature" = oid == Just hitter
                      | otherwise = oid == Just victim
                    answer :: Prompt.Prompt r -> r
                    answer p = case p of
                      Prompt.AnnounceTargets {} -> Map.mapWithKey (\name n -> if name == slot "equipment" then List.genericLength gear else n) (S.identityAnswer p)
                      Prompt.ChooseTargets _ _ _ sets -> Map.mapWithKey (\name (_, offered) -> Set.filter (wanted name . Recipient.objectOf) offered) sets
                      _ -> S.identityAnswer p
                    moved = S.runPure answer (settle answer entered) Stack.resolveTop
                    reflexive = settle answer moved
                 in (moved, reflexive, S.runPure answer reflexive Stack.resolveTop)
              (attached, _, struck) = run [split, left]
              (_, unarmed, unstruck) = run []
          Spec.assertEqWith s "bob's Giant took 3 + 2 + 2 from alice's" (S.damageOf victim struck) (Just 7)
          Spec.assertEqWith s "with no Equipment targeted, nothing attaches and no reflexive is created" (length (GameState.stack unarmed), S.damageOf victim unstruck) (0, Just 0)
          Spec.assertEqWith s "both Equipment are on alice's Giant" (hostOf split attached, hostOf left attached) (Just hitter, Just hitter)
          Spec.assertEqWith s "and it is 3/3 + 2/+0 + 2/+1" (S.powerToughnessOf hitter attached) (Just (7, 4))
        -- Super-Soldier Serum {1}{W} Aura: "Enchanted creature gets +2/+2, has
        -- first strike and vigilance, and is a legendary Soldier in addition to
        -- its other types. Whenever enchanted creature attacks or blocks, attach
        -- any number of target Equipment you control to it." The blocking half is
        -- CR 509.3a's TriggerCondition.Blocks. The other leg differs in the one
        -- blocker: alice's unenchanted Piker, which carries the Bonesplitter.
        Spec.it s "CR 509.3a Super-Soldier Serum's creature blocks and takes alice's Equipment" $ do
          serum <- S.printingOf s registry "Super-Soldier Serum"
          piker <- S.printingOf s registry "Goblin Piker"
          giant <- S.printingOf s registry "Hill Giant"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          blade <- S.printingOf s registry "Dúnedain Blade"
          batterfist <- S.printingOf s registry "Barbed Batterfist"
          let (soldier, g1) = S.addPermanent giant S.alice (Setup.emptyGame S.bothPlayers)
              (other, g2) = S.addPermanent piker S.alice g1
              (split, g3) = S.addPermanent bonesplitter S.alice g2
              (left, g4) = S.addPermanent blade S.alice g3
              (bobsGear, g5) = S.addPermanent batterfist S.bob g4
              (aura, g6) = S.addPermanent serum S.alice g5
              board = S.attach aura soldier (S.attach split other g6)
              blocks blocker = settle S.identityAnswer (S.withEvents [GameEvent.BlocksDeclared (BlocksDeclared.MkBlocksDeclared blocker Set.empty)] board)
              after = S.runPure S.identityAnswer (blocks soldier) Stack.resolveTop
              bystander = blocks other
          Spec.assertEqWith s "both of alice's Equipment are on the enchanted Giant" (hostOf split after, hostOf left after) (Just soldier, Just soldier)
          Spec.assertEqWith s "the Piker blocking triggers nothing" (length (GameState.stack bystander), hostOf split bystander) (0, Just other)
          Spec.assertEqWith s "bob's Batterfist was never offered" (hostOf bobsGear after) Nothing
          Spec.assertEqWith s "the Giant is 3/3 + 2/+2 + 2/+0 + 2/+1" (S.powerToughnessOf soldier after) (Just (9, 6))
          Spec.assertBool s (Projection.hasKeyword Keyword.FirstStrike soldier board && Projection.hasKeyword Keyword.Vigilance soldier board) "the Serum grants first strike and vigilance"
          Spec.assertEqWith s "and makes it a legendary Giant Soldier" (PC.supertypes (Projection.project soldier board), Set.isSubsetOf (Set.fromList [Subtype.Giant, Subtype.Soldier]) (PC.subtypes (Projection.project soldier board))) (Set.singleton Supertype.Legendary, True)
        -- Rhuk, Hexgold Nabber {2}{R} 2/2 trample haste: "Whenever an equipped
        -- creature you control other than Rhuk attacks or dies, you may attach
        -- all Equipment attached to that creature to Rhuk." Alice's Piker wears
        -- Bonesplitter and Flayer Husk and takes lethal damage: CR 704.5g destroys
        -- it and CR 704.5n unattaches both Equipment before the trigger resolves,
        -- so only ObjectRef.AttachedToBound's CR 608.2h read still finds them.
        -- Bob's Batterfist on bob's Giant is never "attached to that creature".
        -- The declining leg differs in the one answer.
        Spec.it s "CR 608.2h Rhuk takes the Equipment that were attached to the creature that died" $ do
          rhuk <- S.printingOf s registry "Rhuk, Hexgold Nabber"
          piker <- S.printingOf s registry "Goblin Piker"
          giant <- S.printingOf s registry "Hill Giant"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          husk <- S.printingOf s registry "Flayer Husk"
          batterfist <- S.printingOf s registry "Barbed Batterfist"
          let (nabber, g1) = S.addPermanent rhuk S.alice (Setup.emptyGame S.bothPlayers)
              (carrier, g2) = S.addPermanent piker S.alice g1
              (bobs, g3) = S.addPermanent giant S.bob g2
              (split, g4) = S.addPermanent bonesplitter S.alice g3
              (worn, g5) = S.addPermanent husk S.alice g4
              (bobsGear, g6) = S.addPermanent batterfist S.bob g5
              equipped = S.attach bobsGear bobs (S.attach worn carrier (S.attach split carrier g6))
              -- 2/1 + 1/+1 from the Husk: two damage is lethal.
              wounded = equipped {GameState.objects = Map.adjust (\obj -> obj {Object.damage = 2}) carrier (GameState.objects equipped)}
              run decision =
                let answer :: Prompt.Prompt r -> r
                    answer p = case p of
                      Prompt.ChooseOptional {} -> decision
                      _ -> S.identityAnswer p
                    buried = settle answer wounded
                 in (buried, S.runPure answer buried Stack.resolveTop)
              (died, taken) = run OptionalDecision.Exercises
              (_, declined) = run OptionalDecision.Declines
          Spec.assertEqWith s "both of the Piker's Equipment are on Rhuk" (hostOf split taken, hostOf worn taken) (Just nabber, Just nabber)
          Spec.assertEqWith s "declining leaves both unattached" (hostOf split declined, hostOf worn declined) (Nothing, Nothing)
          Spec.assertEqWith s "the Piker died, and CR 704.5n had unattached both before the trigger resolved" (Set.member carrier (GameState.battlefield died), hostOf split died, hostOf worn died) (False, Nothing, Nothing)
          Spec.assertEqWith s "Rhuk is 2/2 + 2/+0 + 1/+1" (S.powerToughnessOf nabber taken) (Just (5, 3))
          Spec.assertEqWith s "bob's Batterfist stays on his Giant" (hostOf bobsGear taken) (Just bobs)
        -- The attacks half, the same trigger: the Equipment are still attached
        -- when it resolves, so AttachedToBound reads them live.
        Spec.it s "CR 508.3a Rhuk takes the Equipment attached to the creature that attacked" $ do
          rhuk <- S.printingOf s registry "Rhuk, Hexgold Nabber"
          piker <- S.printingOf s registry "Goblin Piker"
          bonesplitter <- S.printingOf s registry "Bonesplitter"
          husk <- S.printingOf s registry "Flayer Husk"
          let (nabber, g1) = S.addPermanent rhuk S.alice (Setup.emptyGame S.bothPlayers)
              (carrier, g2) = S.addPermanent piker S.alice g1
              (split, g3) = S.addPermanent bonesplitter S.alice g2
              (worn, g4) = S.addPermanent husk S.alice g3
              staged = S.withEvents [GameEvent.AttackerDeclared (AttackerDeclared.MkAttackerDeclared carrier S.bob (AttackTarget.OfPlayer S.bob) 1 S.alice)] (S.attach worn carrier (S.attach split carrier g4))
              answer :: Prompt.Prompt r -> r
              answer p = case p of
                Prompt.ChooseOptional {} -> OptionalDecision.Exercises
                _ -> S.identityAnswer p
              after = S.runPure answer (settle answer staged) Stack.resolveTop
          Spec.assertEqWith s "both Equipment moved from the Piker to Rhuk" (hostOf split after, hostOf worn after) (Just nabber, Just nabber)
          Spec.assertEqWith s "the Piker is a plain 2/1" (S.powerToughnessOf carrier after) (Just (2, 1))

-- CR 702.65 / 701.12d: aura swap. Arcanum Wings {1}{U} Enchantment -- Aura,
-- "Enchant creature" / "Enchanted creature has flying." / "Aura swap {2}{U}"
-- (Oracle checked against api.scryfall.com, 2026-09-30).
--
-- alice's Wings enchants the Goblin Piker, and Russet Wolves is a second
-- creature, so CR 303.4f's host question would be a real prompt were the
-- exchange to ask it; the answerer then names the Wolves. Her hand holds
-- Pacifism and Wild Growth (enchant land), so the hand choice is a real prompt
-- too. A test-local answerer, since no scenario move answers ChooseOptional or
-- ChooseCardInHand.
auraSwapSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
auraSwapSpec s registry =
  let answer :: ObjectId.ObjectId -> ObjectId.ObjectId -> Prompt.Prompt r -> r
      answer wanted wrongHost p = case p of
        Prompt.ChooseOptional {} -> OptionalDecision.Exercises
        Prompt.ChooseCardInHand {} -> wanted
        Prompt.ChooseAttachment _ _ _ offered | List.elem wrongHost (NonEmpty.toList offered) -> wrongHost
        _ -> S.identityAnswer p
      run :: (forall r. Prompt.Prompt r -> r) -> ObjectId.ObjectId -> GameState.GameState -> Maybe (GameState.GameState, [Response.Response])
      run answerer wingsId gs = case Projection.abilitiesOf wingsId gs of
        [ability] ->
          let ((_, after), responses) = Replay.record answerer gs (Activate.activateAbility S.alice wingsId ability >> Stack.resolveTop)
           in Just (after, responses)
        _ -> Nothing
      hostPrompts = length . filter (\r -> case r of Response.ChoseAttachment _ -> True; _ -> False)
      hostOf oid gs = Game.lookupObject oid gs >>= Object.attachedTo >>= Recipient.objectOf
      namedOnBattlefield name gs = filter (\oid -> fmap S.nameOf (Game.cardOf oid gs) == Just (CardName.MkCardName (Text.pack name))) (Set.toList (GameState.battlefield gs))
      sorted = List.sort . fmap (CardName.MkCardName . Text.pack)
   in Spec.describe s "AuraSwap" $ do
        Spec.it s "CR 701.12e the chosen Aura enters attached to the Wings' host, and the Wings go to hand" $ do
          (pikerId, wolvesId, wingsId, pacifismId, _, gs) <- auraSwapBoard s registry S.alice
          case run (answer pacifismId wolvesId) wingsId gs of
            Just (after, responses) -> do
              Spec.assertEqWith s "Pacifism enchants the Piker, the creature the Wings enchanted" (fmap (`hostOf` after) (namedOnBattlefield "Pacifism" after)) [Just pikerId]
              Spec.assertEqWith s "the Wings are in alice's hand beside Wild Growth" (List.sort (handNames S.alice after)) (sorted ["Arcanum Wings", "Wild Growth"])
              Spec.assertEqWith s "CR 303.4f asked nobody for a host" (hostPrompts responses) 0
              Spec.assertBool s (not (Projection.hasKeyword Keyword.Flying pikerId after)) "and the Piker has lost flying"
            Nothing -> Spec.assertFailure s "Arcanum Wings has not exactly one ability"
        Spec.it s "CR 702.65b an Aura that cannot enchant the host leaves both where they were" $ do
          (pikerId, wolvesId, wingsId, _, growthId, gs) <- auraSwapBoard s registry S.alice
          case run (answer growthId wolvesId) wingsId gs of
            Just (after, _) -> do
              Spec.assertEqWith s "Wild Growth and Pacifism are both still in alice's hand" (List.sort (handNames S.alice after)) (sorted ["Pacifism", "Wild Growth"])
              Spec.assertEqWith s "and the Wings still enchant the Piker" (hostOf wingsId after) (Just pikerId)
            Nothing -> Spec.assertFailure s "Arcanum Wings has not exactly one ability"
        Spec.it s "CR 701.12d a Wings bob owns is not exchanged with a card alice owns" $ do
          (pikerId, wolvesId, wingsId, pacifismId, _, gs) <- auraSwapBoard s registry S.bob
          case run (answer pacifismId wolvesId) wingsId gs of
            Just (after, _) -> do
              Spec.assertEqWith s "Pacifism and Wild Growth are both still in alice's hand" (List.sort (handNames S.alice after)) (sorted ["Pacifism", "Wild Growth"])
              Spec.assertEqWith s "and the Wings still enchant the Piker" (hostOf wingsId after) (Just pikerId)
            Nothing -> Spec.assertFailure s "Arcanum Wings has not exactly one ability"
        -- CR 400.7: the Wings leave in response, so "this permanent" names an
        -- object no longer in the game. CR 608.2d offers no "may" over an
        -- exchange that cannot happen, and nobody is asked for a hand card.
        Spec.it s "CR 400.7 an aura swap whose Wings have left asks nothing and exchanges nothing" $ do
          (_, wolvesId, wingsId, pacifismId, _, gs) <- auraSwapBoard s registry S.alice
          case Projection.abilitiesOf wingsId gs of
            [ability] -> do
              let activated = S.runPure (answer pacifismId wolvesId) gs (Activate.activateAbility S.alice wingsId ability)
                  gone = S.runPure S.identityAnswer activated (Event.changeZone (pure ()) wingsId Zone.Graveyard)
                  ((_, after), responses) = Replay.record (answer pacifismId wolvesId) gone Stack.resolveTop
              Spec.assertEqWith s "nobody was asked anything as the ability resolved" responses []
              Spec.assertEqWith s "Pacifism and Wild Growth are both still in alice's hand" (List.sort (handNames S.alice after)) (sorted ["Pacifism", "Wild Growth"])
            _ -> Spec.assertFailure s "Arcanum Wings has not exactly one ability"
        -- CR 702.26b: Clever Concealment ({2}{W}{W} instant, convoke, "Any
        -- number of target nonland permanents you control phase out.") in
        -- response, on the Wings alone. A phased-out permanent is treated as
        -- though it doesn't exist, so there is no permanent to exchange, though
        -- its host is still there to take Pacifism.
        Spec.it s "CR 702.26b an aura swap whose Wings have phased out asks nothing and exchanges nothing" $ do
          (pikerId, wolvesId, wingsId, pacifismId, _, board) <- auraSwapBoard s registry S.alice
          plains <- S.printingOf s registry "Plains"
          concealment <- S.printingOf s registry "Clever Concealment"
          let (concealmentId, gs) = S.addHandCard concealment S.alice (S.landsFor plains S.alice 4 board)
              concealing :: Prompt.Prompt r -> r
              concealing p = case p of
                Prompt.ChooseTargets _ _ _ offers -> fmap (Set.filter ((== Just wingsId) . Recipient.objectOf) . snd) offers
                _ -> answer pacifismId wolvesId p
          case Projection.abilitiesOf wingsId gs of
            [ability] -> do
              let activated = S.runPure concealing gs (Activate.activateAbility S.alice wingsId ability)
                  phased = S.runPure concealing activated {GameState.priority = Just S.alice} (S.cast S.alice concealmentId >> Stack.resolveTop)
                  ((_, after), responses) = Replay.record (answer pacifismId wolvesId) phased Stack.resolveTop
              Spec.assertEqWith s "Pacifism and Wild Growth are both still in alice's hand" (List.sort (handNames S.alice after)) (sorted ["Pacifism", "Wild Growth"])
              Spec.assertEqWith s "the Wings, phased out, still enchant the Piker" (hostOf wingsId after) (Just pikerId)
              Spec.assertEqWith s "nobody was asked anything as the ability resolved" responses []
              Spec.assertBool s (Map.member wingsId (GameState.phasedOut phased) && Set.member pikerId (GameState.battlefield phased)) "the Wings alone had phased out before the swap resolved"
            _ -> Spec.assertFailure s "Arcanum Wings has not exactly one ability"
        -- CR 207.2a / 612.2: rule 702.65a's "an Aura card" is the rule's word,
        -- not the Wings', so Synthetic Enchanted Evolution's Aura -> Background
        -- reaches only the Wings' own type line (CR 704.5p detaches them) and the
        -- swap still offers the two Auras and neither Background
        -- (CR 702.1).
        Spec.it s "CR 612.2 an Aura swap on Wings changed to Background still offers the Auras" $ do
          (wingsId, evolved, textChanged) <- textChangedSwap s registry ("Raised by Giants", "Master Chef") (Subtype.Aura, Subtype.Background)
          Spec.assertEqWith s "CR 704.5p the changed Wings stay on the battlefield, attached to nothing" (Set.member wingsId (GameState.battlefield evolved), hostOf wingsId evolved) (True, Nothing)
          case textChanged of
            Just (_, (pacifismId, growthId), _, offers, _) ->
              Spec.assertEqWith s "the swap offered the two Auras" (fmap List.sort offers) [List.sort [pacifismId, growthId]]
            Nothing -> Spec.assertFailure s "the changed Wings have not exactly one ability"
        -- THE PAIR: the same board and the same Evolution, naming a swap the
        -- Wings' text holds no word of, so rule 702.65a's Aura stands.
        Spec.it s "CR 612.1 an Aura swap the change does not touch offers the Auras" $ do
          (_, _, textChanged) <- textChangedSwap s registry ("Raised by Giants", "Master Chef") (Subtype.Curse, Subtype.Background)
          case textChanged of
            Just (pikerId, (pacifismId, growthId), _, offers, after) -> do
              Spec.assertEqWith s "the swap offered the two Auras" (fmap List.sort offers) [[pacifismId, growthId]]
              Spec.assertEqWith s "Pacifism enchants the Piker" (fmap (`hostOf` after) (namedOnBattlefield "Pacifism" after)) [Just pikerId]
            Nothing -> Spec.assertFailure s "the Wings have not exactly one ability"

-- auraSwapSpec's text-change board. Synthetic Enchanted Evolution ({U}
-- Instant, "Change the text of target spell or permanent by replacing all
-- instances of one enchantment type with another. (This effect lasts
-- indefinitely.)") is Artificial Evolution's shape over CR 205.3h's enchantment
-- types: no printing changes one (Scryfall `o:"change the text"
-- include:extras`, 2026-10-06), and CR 612.2's word classes are examples. Four
-- Islands, the Piker wearing alice's Arcanum Wings, the Wolves, and Pacifism,
-- Wild Growth, the two named cards and the Evolution in her hand -- two of each
-- kind, so the hand choice is a real prompt either way. The Evolution resolves
-- onto the Wings with `swap`, state-based actions run, and the Wings' ability is
-- activated and resolved. Returns the Wings, the board the Evolution left, and,
-- when the Wings still have their one ability there, the Piker, the two Auras,
-- the two named cards, every ChooseCardInHand offer in order, and the board.
textChangedSwap :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> (String, String) -> (Subtype.Subtype, Subtype.Subtype) -> m (ObjectId.ObjectId, GameState.GameState, Maybe (ObjectId.ObjectId, (ObjectId.ObjectId, ObjectId.ObjectId), (ObjectId.ObjectId, ObjectId.ObjectId), [[ObjectId.ObjectId]], GameState.GameState))
textChangedSwap s registry (firstName, secondName) (from, to) = do
  wings <- S.printingOf s registry "Arcanum Wings"
  island <- S.printingOf s registry "Island"
  piker <- S.printingOf s registry "Goblin Piker"
  wolves <- S.printingOf s registry "Russet Wolves"
  pacifism <- S.printingOf s registry "Pacifism"
  growth <- S.printingOf s registry "Wild Growth"
  first <- S.printingOf s registry firstName
  second <- S.printingOf s registry secondName
  evolution <- S.printingOf s registry "Synthetic Enchanted Evolution"
  let mana = S.landsFor island S.alice 4 S.threePlayerGame
      (pikerId, g1) = S.addPermanent piker S.alice mana
      (_, g2) = S.addPermanent wolves S.alice g1
      (wingsId, g3) = S.addPermanent wings S.alice g2
      (pacifismId, g4) = S.addHandCard pacifism S.alice (S.attach wingsId pikerId g3)
      (growthId, g5) = S.addHandCard growth S.alice g4
      (firstId, g6) = S.addHandCard first S.alice g5
      (secondId, g7) = S.addHandCard second S.alice g6
      (evolutionId, g8) = S.addHandCard evolution S.alice g7
      evolving :: Prompt.Prompt r -> r
      evolving p = case p of
        Prompt.ChooseTargets _ _ _ offers -> S.preferring ((== Just wingsId) . Recipient.objectOf) offers
        Prompt.ChooseWordSwap {} -> (TextWord.SubtypeWord from, TextWord.SubtypeWord to)
        _ -> S.identityAnswer p
      evolved = S.runPure evolving g8 {GameState.priority = Just S.alice} (S.cast S.alice evolutionId >> Stack.resolveTop >> Engine.settleForPriority)
      -- Records each hand offer and takes its least id, the first named card
      -- whenever the offer assertions hold; bob is the CR 303.4f answer, never
      -- the first offered.
      recording :: Prompt.Prompt r -> State.State [[ObjectId.ObjectId]] r
      recording p = case p of
        Prompt.ChooseOptional {} -> pure OptionalDecision.Exercises
        Prompt.ChooseCardInHand _ _ _ offered -> do
          State.modify' (<> [NonEmpty.toList offered])
          pure (minimum offered)
        Prompt.ChoosePlayer _ _ _ offered -> pure (if List.elem S.bob (NonEmpty.toList offered) then S.bob else NonEmpty.head offered)
        _ -> pure (S.identityAnswer p)
  pure . (,,) wingsId evolved $ case Projection.abilitiesOf wingsId evolved of
    [ability] ->
      let ((_, after), offers) = State.runState (Engine.runGame recording evolved (Activate.activateAbility S.alice wingsId ability >> Stack.resolveTop >> Engine.settleForPriority)) []
       in Just (pikerId, (pacifismId, growthId), (firstId, secondId), offers, after)
    _ -> Nothing

-- auraSwapSpec's board: three Islands, the Piker wearing Arcanum Wings (owned by
-- `owner`, controlled by alice), the Wolves, and Pacifism and Wild Growth in
-- alice's hand. Returns the Piker, the Wolves, the Wings, Pacifism, Wild Growth
-- and the board.
auraSwapBoard :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> PlayerId.PlayerId -> m (ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, GameState.GameState)
auraSwapBoard s registry owner = do
  wings <- S.printingOf s registry "Arcanum Wings"
  island <- S.printingOf s registry "Island"
  piker <- S.printingOf s registry "Goblin Piker"
  wolves <- S.printingOf s registry "Russet Wolves"
  pacifism <- S.printingOf s registry "Pacifism"
  growth <- S.printingOf s registry "Wild Growth"
  let mana = S.landsFor island S.alice 3 S.threePlayerGame
      (pikerId, g1) = S.addPermanent piker S.alice mana
      (wolvesId, g2) = S.addPermanent wolves S.alice g1
      (wingsId, g3) = S.addPermanent wings owner g2
      controlled = if owner == S.alice then g3 else S.giveControl wingsId S.alice g3
      (pacifismId, g4) = S.addHandCard pacifism S.alice (S.attach wingsId pikerId controlled)
      (growthId, g5) = S.addHandCard growth S.alice g4
  pure (pikerId, wolvesId, wingsId, pacifismId, growthId, g5 {GameState.priority = Just S.alice})
