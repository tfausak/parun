module Parun.Types.TriggerCondition where

import qualified Parun.Types.AbilityAddsMana as AbilityAddsMana
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.AttackTrigger as AttackTrigger
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.BlockTrigger as BlockTrigger
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CausedBy as CausedBy
import qualified Parun.Types.ClassLevel as ClassLevel
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.Types.CounterTrigger as CounterTrigger
import qualified Parun.Types.DamageTrigger as DamageTrigger
import qualified Parun.Types.DieResult as DieResult
import qualified Parun.Types.DiscardTrigger as DiscardTrigger
import qualified Parun.Types.EntersTrigger as EntersTrigger
import qualified Parun.Types.ExploitTrigger as ExploitTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LeavesTrigger as LeavesTrigger
import qualified Parun.Types.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Types.PermanentIsDealtDamage as PermanentIsDealtDamage
import qualified Parun.Types.PermanentTappedForMana as PermanentTappedForMana
import qualified Parun.Types.PermanentsBecomeTargeted as PermanentsBecomeTargeted
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.PlacesSticker as PlacesSticker
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerDrawsNthCard as PlayerDrawsNthCard
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlaysLand as PlaysLand
import qualified Parun.Types.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.Types.RevealedThisWay as RevealedThisWay
import qualified Parun.Types.RoomIndex as RoomIndex
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

-- | CR 603.2: the pattern that fires a triggered ability. Only
-- Parun.Engine.Event may case on it for RULES purposes; Parun.Codec also cases on
-- every constructor, but only as the JSON data boundary.
--
-- Two shapes recur. A Self- condition compares ids, so it reads none of the
-- subject's characteristics and never needs CR 608.2h last known information. A
-- filtered condition reads them, and so does. That is why several rules have a
-- constructor of each shape rather than one written as `Filter.IsSource`.
data TriggerCondition
  = -- | CR 603.6a: a permanent enters the battlefield.
    Enters EntersTrigger.EntersTrigger
  | -- | CR 603.2b: "at the beginning of [each|your] <step>"; the TurnScope
    -- decides whose turn qualifies.
    StepBegins StepBegins.StepBegins
  | -- | CR 603.8: a state trigger, armed again only once the ability has left
    -- the stack.
    StateIs Condition.Condition
  | -- | CR 603.2 / 120.1: a permanent or spell dealt damage (Spirit Link,
    -- Questing Beast, Phage the Untouchable, Teysa, Envoy of Ghosts).
    DealsDamage DamageTrigger.DamageTrigger
  | -- | CR 120.3 / 603.2c: a permanent was dealt damage of the kind, once per
    -- simultaneous batch or per source (Ripjaw Raptor, Belltower Sphinx).
    IsDealtDamage PermanentIsDealtDamage.PermanentIsDealtDamage
  | -- | CR 120.3 / 603.2c: a player the relation admits, or one of their
    -- planeswalkers, was dealt damage of the kind, once per simultaneous batch
    -- and damaged recipient (Lich, Chandra's Spitfire, Vengeful Pharaoh).
    PlayerIsDealtDamage PlayerIsDealtDamage.PlayerIsDealtDamage
  | -- | CR 603.2c's batch reading of DealsDamage's combat damage to a player, with the damaged player
    -- narrowed: "whenever one or more artifact creatures you control deal combat
    -- damage to a player" (Pia Nalaar, Chief Mechanic), once per CR 510.2 step,
    -- damagers' controller and damaged player.
    PermanentsDealCombatDamageToPlayer PermanentsDealCombatDamageToPlayer.PermanentsDealCombatDamageToPlayer
  | -- | CR 725.2: a creature dealt combat damage to the monarch. Borne by no
    -- card.
    CreatureDealtCombatDamageToMonarch
  | -- | CR 726.2: one or more creatures a player controls dealt combat damage to
    -- the player who has the initiative. Borne by no card.
    CreaturesDealtCombatDamageToInitiative
  | -- | CR 726.2: "you" took the initiative. Borne by no card.
    PlayerTookInitiative
  | -- | CR 702.94a: "when you reveal this card this way" -- miracle's triggered
    -- half, linked (CR 603.11) to the static half. Self-scoped.
    SelfRevealedForMiracle
  | -- | CR 603.11 / 607.2h: "whenever you reveal a [quality] card this way" --
    -- the triggered half linked to the bearer's draw-time reveal (Rowen).
    RevealedThisWay RevealedThisWay.RevealedThisWay
  | -- | CR 701.9a / 702.29c / 702.35a: a card was discarded (Bartered Cow,
    -- Megrim, Prickly Marmoset, madness's linked half).
    Discards DiscardTrigger.DiscardTrigger
  | -- | CR 121.1: "whenever [a player] draws their Nth card each turn" (Erudite
    -- Wizard), by equality on the ordinal the event carries; without an ordinal,
    -- "whenever [a player] draws a card" (Teferi, Hero of Dominaria's emblem).
    PlayerDrawsNthCard PlayerDrawsNthCard.PlayerDrawsNthCard
  | -- | CR 508.3: a trigger on attackers being declared, as a function of
    -- Parun.Types.AttackTrigger's arity and fields.
    Attacks AttackTrigger.AttackTrigger
  | -- | CR 509.3: "whenever [a creature] blocks" or "becomes blocked", in each of
    -- CR 509.3a-e's counts.
    --
    -- Each producer of those rules reaches it: CR 509.1's declaration, an effect
    -- that causes a creature to block (Parun.Engine.Combat.switchBlockers,
    -- General Jarkeld; Combat.exchangeBlocks, Sorrow's Path), Effect.BecomesBlocked
    -- (Curtain of Light) and a creature put onto the battlefield blocking (CR
    -- 509.4; Flash Foliage, Aetherplasm). Parun.CombatCostSpec's SwitchBlockers,
    -- ExchangeBlocks and PutOntoBattlefieldBlocking groups and
    -- Parun.KeywordTriggerSpec's SelfBlocksOneOrMore and
    -- CreatureBecomesBlockedByAtLeast groups are the proof.
    Blocks BlockTrigger.BlockTrigger
  | -- | CR 603.6c: a permanent leaves the battlefield, a CR 603.10a look-back.
    Leaves LeavesTrigger.LeavesTrigger
  | -- | CR 400.7: a card leaves a zone other than the battlefield.
    LeavesZone LeavesZoneTrigger.LeavesZoneTrigger
  | -- | CR 603.6: a card is put into a zone other than the battlefield.
    PutIntoZone PutIntoZoneTrigger.PutIntoZoneTrigger
  | -- | CR 701.26a / 701.26b: a permanent became tapped or untapped, once per
    -- permanent (City of Brass, Oreskos Sun Guide, Mesmeric Orb).
    BecomesTapState BecomesTapState.BecomesTapState
  | -- | CR 701.26a's batch reading, by a bystander: "whenever one or more
    -- nontoken Merfolk you control become tapped" (Deeproot Pilgrimage), once
    -- per tapping event (CR 603.2c).
    PermanentsBecomeTapped (Filter.Filter Keyword.Keyword)
  | -- | CR 106.12a's "is tapped for mana" read off the permanent the bearer is
    -- attached to (Wild Growth), live rather than through last known
    -- information.
    AttachedPermanentTappedForMana
  | -- | CR 106.12a read by a bystander: "whenever you tap a land creature for
    -- mana" (Autumn Willow, Harmony), the arm above's event under a relation and
    -- a filter instead of an attachment link.
    PermanentTappedForMana PermanentTappedForMana.PermanentTappedForMana
  | -- | CR 605.1b's "mana being added to a player's mana pool": "whenever a
    -- land's ability causes you to add one or more mana of the chosen color"
    -- (Caged Sun).
    AbilityAddsMana AbilityAddsMana.AbilityAddsMana
  | -- | CR 605.1b's first alternative, self-scoped: "whenever a mana ability of
    -- this creature resolves" (Tyvar the Bellicose), against
    -- GameEvent.ManaAbilityResolved, with the mana the activation produced bound
    -- under Parun.Engine.Binding.eventAmount.
    --
    -- RESOLUTION and not that rule's other half, a mana ability being ACTIVATED:
    -- every printing of the activation form states the negative instead
    -- (Rings of Brighthearth's "if it isn't a mana ability"), so nothing reads
    -- the moment between CR 605.3b's activation and the resolution it says
    -- follows immediately -- Scryfall o:/[Ww]henever.*mana abilit/, 2026-09-13,
    -- no hit of the positive shape. A card printing one would want a second arm
    -- here and a second event, not a widening of this one.
    SelfManaAbilityResolves
  | -- | CR 701.6a: "whenever a spell or ability you control counters a spell"
    -- (Baral, Chief of Compliance); the relation is on the countering side.
    SpellOrAbilityCounters PlayerRelation.PlayerRelation
  | -- | CR 701.6a read from the VICTIM's side, and only for that rule's ability
    -- half: "whenever an ability is countered" (Synthetic Echo Silencer). Matches
    -- GameEvent.AbilityCountered and nothing else, so the arm above stays silent
    -- here and this one stays silent for a countered spell.
    AbilityIsCountered
  | -- | CR 615.13: "whenever damage that would be dealt to you is prevented"
    -- (Selfless Squire), blind to which prevention effect applied.
    DamageToPlayerPrevented PlayerRelation.PlayerRelation
  | -- | CR 615.13 the other way round: "when damage is prevented this way"
    -- (Phyrexian Vindicator), matching where CR 614.5's applying instance names
    -- the bearer as its source; the Filter is over CR 120.1's damage source.
    SelfPreventsDamage (Filter.Filter Keyword.Keyword)
  | -- | CR 119.3 / 119.9: "whenever [a player] gains life" (Ajani's Pridemate) or
    -- "loses life" (Exquisite Blood); CR 702.179d's "one or more opponents lose
    -- life during your turn" too.
    LifeChanges LifeTrigger.LifeTrigger
  | -- | CR 603.2 / 122.6: counters of a kind were put on or removed from a
    -- permanent (CR 714.2b's chapters, CR 310.12b's Siege, Chandra, Fire
    -- Artisan, Protean Hydra, Wickersmith's Tools, Cloaked Cadet).
    CountersChange CounterTrigger.CounterTrigger
  | -- | CR 716.2a: "when this Class becomes level N" (Stormchaser's Talent), a
    -- crossing rather than an equality.
    SelfBecomesClassLevel ClassLevel.ClassLevel
  | -- | CR 601.2i: "whenever you cast a [type] spell" (Young Pyromancer), the
    -- Filter read against the spell as it is on the stack.
    SpellCast SpellCast.SpellCast
  | -- | CR 601.2i read off the spell being cast -- "when you cast this spell"
    -- (Desolation Twin). Self-scoped, which is what lets
    -- Parun.Engine.Event.Trigger.zonesTriggeredFrom answer CR 113.6k totally.
    SelfCast
  | -- | CR 602.2b / 601.2i: "whenever you activate an ability [of a ...]"
    -- (Kurkesh, Onakke Ancient), the Filter read against the ability on the
    -- stack, as SpellCast's is against the spell.
    AbilityActivated (Filter.Filter Keyword.Keyword)
  | -- | CR 601.2c: "whenever this permanent becomes the target of a spell or
    -- ability [a player] controls" -- CR 702.21a's ward, once per spell or
    -- ability however many of its "target" words name this permanent.
    SelfBecomesTargeted PlayerRelation.PlayerRelation
  | -- | CR 601.2c from the player's side: "whenever you become the target of a
    -- spell or ability" (Dormant Gomazoa).
    ControllerBecomesTarget ControllerBecomesTarget.ControllerBecomesTarget
  | -- | CR 603.2c's batch reading of the same rule read by a BYSTANDER:
    -- "whenever one or more creatures you control become the target of an
    -- activated ability" (Professor Hojo), once for the whole announcement.
    PermanentsBecomeTargeted PermanentsBecomeTargeted.PermanentsBecomeTargeted
  | -- | CR 601.2c per permanent: "whenever a creature you control becomes the
    -- target of a spell" (Venerated Rotpriest), once per creature targeted.
    PermanentBecomesTargeted PermanentsBecomeTargeted.PermanentsBecomeTargeted
  | -- | CR 709.5h: "when you unlock this door", however the named half was
    -- unlocked. Self-scoped plus the half, which is what separates a Room's two
    -- doors.
    SelfHalfUnlocked CardName.CardName
  | -- | CR 709.5i: the permanent gained the unlocked designation it lacked, or
    -- gained both. Not self-scoped (Balemurk Leech).
    --
    -- The PlayerRelation reads the player who unlocked, proved by Parun.RoomSpec's
    -- "CR 709.5i 'you' is the player who unlocked, not the Room's controller".
    RoomFullyUnlocked PlayerRelation.PlayerRelation
  | -- | CR 603.1b: several conditions, any of which fires the one ability that
    -- bears them (Balemurk Leech); Parun.CardSpec's lint forbids a StateIs or a
    -- nested AnyOf inside one.
    AnyOf [TriggerCondition]
  | -- | CR 609.1: the condition, narrowed to an event a spell or ability's
    -- effect caused (Sacred Ground, Spiritual Focus). Read off Moved and
    -- Discarded, the events that record a cause.
    CausedBy (CausedBy.CausedBy TriggerCondition)
  | -- | CR 708.7 through CR 603.2: a face-down permanent is turned face up, the
    -- bearer itself (Skirk Marauder) or one the Filter admits (Aven Farseer).
    TurnedFaceUp ActingPermanent.ActingPermanent
  | -- | CR 701.27e: "when this creature transforms into [face]", matched against
    -- the names the event carries. Self-scoped plus the name, which is what
    -- tells the turn to a face from the turn away from it.
    --
    -- PermanentTransforms below is the same event read by a bystander, as
    -- TurnedFaceUp's Matching subject is.
    SelfTransformedInto CardName.CardName
  | -- | CR 701.27e read by a bystander: a permanent the Filter admits turned over
    -- (Cult of the Waxing Moon), matched against what the event SAMPLED rather
    -- than against the board the CR 117.5 scan reads.
    PermanentTransforms (Filter.Filter Keyword.Keyword)
  | -- | CR 708.9: "whenever a face-down permanent is revealed as it leaves the
    -- battlefield" (Synthetic Unmasking Witness).
    FaceDownPermanentLeavesRevealed
  | -- | A permanent the Filter admits gained this designation -- CR 702.112b's
    -- renown (Valeron Wardens) and CR 701.37b's monstrous (Arbor Colossus).
    PermanentBecomesDesignated PermanentBecomesDesignated.PermanentBecomesDesignated
  | -- | CR 702.134c: the creature the bearer is attached to mentored another
    -- (Aegis of the Legion). Attachment-scoped, so vacuously False while
    -- attached to nothing or to a player (CR 303.4).
    AttachedCreatureMentors
  | -- | CR 702.110b: a creature exploited a creature (Qarsi Sadist, Skull Skaab).
    --
    -- Parun.CardTriggerSpec's "CR 702.110b Profaner of the Dead bounces the
    -- creatures under the exploited creature's toughness" is what proves the
    -- exploited creature's slot is readable.
    Exploits ExploitTrigger.ExploitTrigger
  | -- | CR 702.122e: "whenever this Vehicle becomes crewed" (Mobilizer Mech),
    -- which that rule defines as a crew ability of the bearer RESOLVING.
    -- Self-scoped; the TriggerFrequency is Mighty Servant of Leuk-o's "for the
    -- first time each turn", as AttackerTrigger's is one rule over.
    --
    -- Rule 702.122e's last sentence is read off Parun.Engine.Binding.crewers,
    -- which Parun.Engine.Event.Binding stamps for every match: an intervening
    -- "if" counts that slot rather than the board, so it means only the
    -- creatures that paid the cost of the activation that caused the trigger.
    -- Parun.CrewSpec's "CR 702.122e a second crewing this turn does not trigger
    -- it again" and "crewed by exactly two" are what prove it.
    SelfBecomesCrewed TriggerFrequency.TriggerFrequency
  | -- | CR 702.122b: "whenever this creature crews a Vehicle" (Gearshift Ace),
    -- which that rule makes true of a creature tapped to pay a Vehicle's crew
    -- cost. Self-scoped, SelfBecomesCrewed's other side: that one is asked of the
    -- Vehicle and this one of a crewer.
    SelfCrewsVehicle
  | -- | CR 603.10a: "whenever an opponent sacrifices an artifact" (Vengeful
    -- Tracker) -- the CR 701.21a game action, not the zone change Leaves
    -- reads. Mayhem Devil's unrestricted wording is AnyPlayer and the trivial
    -- Filter.
    PermanentSacrificed PlayerActsOn.PlayerActsOn
  | -- | CR 603.3b's second class: "whenever the final chapter ability of a Saga
    -- you control triggers" (Historian's Boon), against
    -- GameEvent.AbilityTriggered.
    SagaFinalChapterTriggers PlayerRelation.PlayerRelation
  | -- | CR 725.1: "whenever [a player] becomes the monarch" (Custodi Lich),
    -- however the crown was won.
    PlayerBecomesMonarch PlayerRelation.PlayerRelation
  | -- | CR 603.7: "when you lose control of the creature" (Ray of Command) --
    -- its subject an object CR 603.7c's captured environment chose earlier.
    LoseControlOfBound SlotName.SlotName
  | -- | CR 603.10d: "when you lose control of [this permanent]" (Khârn the
    -- Betrayer), against GameEvent.ControlChanged.
    LoseControlOfSelf
  | -- | CR 309.4c: "when you move your venture marker into this room".
    -- Self-scoped through the bearer and the room index; minted by
    -- Parun.Engine.Dungeon rather than written by card data.
    RoomEntered RoomIndex.RoomIndex
  | -- | CR 603.9: "whenever a player loses the game" (Withengar Unbound),
    -- against GameEvent.LostTheGame.
    PlayerLosesGame PlayerRelation.PlayerRelation
  | -- | CR 305.1: "whenever you play a land from exile" (Urianger Augurelt),
    -- against GameEvent.LandPlayed.
    PlayerPlaysLand PlaysLand.PlaysLand
  | -- | CR 701.62b: "whenever you manifest dread" (Paranormal Analyst), against
    -- GameEvent.ManifestedDread.
    PlayerManifestsDread PlayerRelation.PlayerRelation
  | -- | CR 311.7: "whenever chaos ensues", a plane's chaos ability, against a
    -- GameEvent.ChaosEnsued.
    ChaosEnsues
  | -- | CR 901.8: "whenever you roll the Planeswalker symbol on the planar die".
    PlayerRollsPlaneswalker PlayerRelation.PlayerRelation
  | -- | CR 904.9 / 312.5 / 701.31d: "When you set this scheme in motion", "When
    -- you encounter [this phenomenon]" and "When you planeswalk to [this
    -- plane]", against a GameEvent.TurnedUpOffDeck naming the ability's own card.
    SelfTurnedUpOffDeck
  | -- | CR 701.31d / 603.10g: "When you planeswalk away from [this plane]",
    -- against a GameEvent.TurnedUpOffDeck naming the ability's own card among
    -- those walked away from. A look-back.
    SelfPlaneswalkedAwayFrom
  | -- | CR 706.2: "whenever you roll a 6" (Night Shift of the Living Dead), once
    -- per die whose result, after every modifier, is the stated number.
    PlayerRollsResult (DieResult.DieResult PlayerRelation.PlayerRelation)
  | -- | CR 702.159a: Visit -- its controller rolled to visit their Attractions
    -- and the result is lit up on this one.
    Visit
  | -- | CR 705.2: "whenever you win a coin flip" (Tavern Scoundrel), reading the
    -- event's win where PlayerAction.RollDice ignores what the die showed.
    --
    -- No third, outcome-blind arm: Scryfall o:"whenever you flip a coin" with
    -- include_extras, 2026-09-16, returns nothing, so no printing watches the flip
    -- without reading rule 705.2's outcome.
    PlayerWinsCoinFlip PlayerRelation.PlayerRelation
  | -- | CR 705.2: "whenever you lose a coin flip" (Karplusan Minotaur), the
    -- mirror of PlayerWinsCoinFlip over the same event.
    --
    -- The two are not exhaustive. CR 705.2's first sentence describes a flip
    -- nobody wins or loses, which both answer False to -- proved by
    -- Parun.ReplacementSpec's "CR 705.2 nobody loses Molten Sentry's flip either".
    PlayerLosesCoinFlip PlayerRelation.PlayerRelation
  | -- | CR 702.170a / 702.170c: "when this card becomes plotted" (Aloe
    -- Alchemist). Self-scoped, and watched for from exile.
    SelfBecomesPlotted
  | -- | CR 701.3a read by the host: "whenever an Aura becomes attached to this
    -- creature" (Bramble Elemental), with the Filter over the attachment.
    SelfBecomesAttachedBy (Filter.Filter Keyword.Keyword)
  | -- | CR 701.3a read by the attachment: "whenever this Equipment becomes
    -- attached to a creature" (Enormous Energy Blade), with the Filter over the
    -- host and the host bound as "that creature".
    SelfBecomesAttachedTo (Filter.Filter Keyword.Keyword)
  | -- | CR 701.3d read by the attachment: "whenever this Equipment becomes
    -- unattached from a permanent" (Grafted Wargear), with the Filter over the
    -- former host and that host bound as "that permanent".
    SelfBecomesUnattachedFrom (Filter.Filter Keyword.Keyword)
  | -- | CR 603.12's reflexive triggered ability: "when you do" (The Fugitive
    -- Doctor). Nullary, and it matches no GameEvent -- the arm runs only when
    -- the action it hangs off actually happened, CR 701.28e's ignored convert
    -- being the one that does not (Parun.Engine.Resolve.Common.applyClauseEffects), so
    -- Parun.Engine.Event.Trigger.delayedPending fires it once at the next gather.
    --
    -- Not implemented: CR 603.12a's first sentence, "once for each of those
    -- times", which rule 603.12's other printed form ("when [something happens]
    -- this way") reaches -- that event is no payment and can occur several times
    -- in one resolution, where this fires once (#2121).
    Reflexive
  | -- | CR 603.2: "whenever [a permanent] <acts>" (Renegade Krasis, Wildgrowth
    -- Walker), the actor being the bearer itself or one the Filter admits.
    --
    -- Not implemented: a card bearing two exert paragraphs, whose two
    -- PermanentAction.Exert triggers would each see both exerts (#4946).
    PermanentActs (PermanentActed.PermanentActed ActingPermanent.ActingPermanent)
  | -- | CR 603.2: "whenever [a player] <acts>", the actor read against CR
    -- 109.5's "you" (Matoya, Archon Elder; Synthetic Blight Chronicler).
    PlayerActs (PlayerActed.PlayerActed PlayerRelation.PlayerRelation)
  | -- | CR 123.3: Wee Champion's "whenever you place a sticker".
    PlacesSticker PlacesSticker.PlacesSticker
  deriving (Eq, Ord, Show)
