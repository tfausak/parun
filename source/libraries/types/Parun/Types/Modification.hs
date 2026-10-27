module Parun.Types.Modification where

import qualified Data.Set as Set
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastingPermission as CastingPermission
import qualified Parun.Types.ChangeMode as ChangeMode
import qualified Parun.Types.ChangeWord as ChangeWord
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatDamageOption as CombatDamageOption
import qualified Parun.Types.CostKeyword as CostKeyword
import qualified Parun.Types.ExiledCardAbilities as ExiledCardAbilities
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.FullText as FullText
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.NameInsertion as NameInsertion
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.SubtypeFamily as SubtypeFamily
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TargetSlot as TargetSlot

-- | The open-half continuous-effect vocabulary: continuous-effect
-- specifications, classified by layer, distinct from Effect. Within the RULES
-- CORE, Parun.Engine.Projection is the sole module that may case on a
-- constructor -- the same standing Parun.Engine.Resolve has over Effect.
-- Parun.CardSpec's lints also case on it, legitimately: a test-suite lint that
-- walks the card pool is not rules core. GainKeyword and LoseKeyword carry a
-- Keyword, LoseKeywordFamily a KeywordFamily and GainKeywordAtManaCost a
-- CostKeyword, closed-half CITATIONS, so
-- casing on them is not an invariant violation; and GainAbility carries a whole open-half ability that nothing cases on beyond CR
-- 113.3's ability KIND -- the projection appends it to one of two lists, and
-- every reader downstream treats it as any other ability. The P/T arms carry
-- records of signed Quantity. The layer-4 arms below reach card types, subtypes
-- and supertypes, which CR 205.4b keeps independent of one another.
--
-- Parametric in `ability` for GainAbility's sake alone, and parametric rather
-- than concrete because this module cannot NAME an ability: an ActivatedAbility
-- carries Effects and Parun.Types.Effect carries a Parun.Types.ModifyTarget, which
-- carries one of these. Parun.Types.StaticAbility and Parun.Types.ContinuousEffect
-- instantiate the variable at `GrantedAbility card`, and so does the
-- Parun.Types.ModifyTarget an Effect carries, which is threaded the whole way
-- down: a modification a RESOLUTION creates reaches exactly the positions a
-- printed grant does. Parun.Types.GrantedAbility ties the knot.
data Modification ability
  = GainKeyword Keyword.Keyword -- layer 6 (Serpent's Gift)
  | -- | layer 6, CR 613.1f / CR 202.1a: this object gains the keyword, priced at
    -- its own mana cost (Varolz, the Scar-Striped's scavenge).
    GainKeywordAtManaCost CostKeyword.CostKeyword
  | -- | layer 6, CR 613.1f / CR 702.5a: this object gains an enchant ability --
    -- "becomes an Aura enchantment WITH ENCHANT CREATURE", the clause every
    -- printing that turns a permanent into an Aura carries.
    --
    -- Its own arm rather than GainAbility, and legitimately so: enchant is a rule
    -- 702 keyword, hence a closed-half CITATION exactly as the Keyword GainKeyword
    -- carries is.
    --
    -- Carries a whole TargetSlot rather than a Filter, for Parun.Types.Face.enchant's
    -- reason: CR 702.5d's enchant-player Auras need the Pool axis, so the printed
    -- field and the granted one are the same shape and
    -- Parun.Engine.Card.foldEnchant folds them together under CR 702.5c.
    --
    -- APPENDED to the projection's list rather than replacing it (CR 702.5c: "if
    -- an Aura has multiple instances of enchant, all of them apply"), which is
    -- also what keeps a granted instance off the copiable values: the seed carries
    -- the printed instances alone (CR 707.2), the same posture activatedAbilities
    -- takes.
    --
    -- Its Filter is matched by Parun.Engine.Target.admittedGiven, which fills
    -- `perspective` and `source`, and fills `slotObjects` and `slotNames` from
    -- whatever the announcement has already bound -- so a granted enchant naming
    -- IsBound or Shares Name Bound is judged against exactly the context a PRINTED
    -- one is, and each of those two answers False where the announcement bound
    -- nothing. Which way an unfilled read answers is per ATOM rather than a
    -- property of that context: CR 110.2's ControllerRelatesToBound widens instead,
    -- and Parun.CardSpec's Framing keeps it out of this slot and the printed one
    -- alike. A "HeldBy Controller You" conjunct, the shape
    -- Old-Growth Troll prints, is answered honestly.
    GainEnchant TargetSlot.TargetSlot
  | -- | layer 6, CR 613.1f / CR 702.5a: this object loses every enchant instance
    -- equal to this one (Animate Dead's "loses 'enchant creature card in a
    -- graveyard'").
    LoseEnchant TargetSlot.TargetSlot
  | -- | layer 6, CR 613.1f / 601.3: this object gains a permission to be cast
    -- (a granted Panglacial Wurm clause).
    GainCastingPermission CastingPermission.CastingPermission
  | -- | layer 6, CR 613.1f: this object gains a whole quoted ability, authored on
    -- the granting card (Presence of Gond's "Enchanted creature has '{T}: Create
    -- a 1/1 green Elf Warrior creature token.'", Sixth Sense's "Enchanted
    -- creature has 'Whenever this creature deals combat damage to a player, you
    -- may draw a card.'").
    --
    -- A RESOLUTION reaches this arm too, through Parun.Types.ModifyTarget's own
    -- ability variable: Retraction Helix's "Until end of turn, target creature
    -- gains '{T}: Return target nonland permanent to its owner's hand.'" stores
    -- exactly what an Aura's static ability grants.
    --
    -- Folded into the ProjectedCharacteristics list CR 113.3 puts its kind in,
    -- which is what decides everything about the granted ability's identity: it
    -- becomes an ability OF THE RECEIVING OBJECT, so CR 113.7 makes that object
    -- the ability's source, CR 602.2 makes that object's controller the default
    -- activator of an activated one, CR 603.3a makes that same player the controller of a
    -- triggered one, CR 113.8 makes them the controller of the ability on the
    -- stack, and every binding it names -- the tap cost, IsSource, the counter it
    -- puts on "this creature", the "you" that draws -- resolves against the
    -- receiver. The granting permanent supplies only the text and, via CR 613.7a,
    -- the timestamp.
    --
    -- CR 303.4e says as much outright for the Aura case: "if the Aura grants an
    -- ability to the enchanted object (with 'gains' or 'has'), the enchanted
    -- object's controller is the only one who can activate that ability".
    --
    -- Rejected: keeping the ability anchored to the GRANTER and activating it
    -- there. Presence of Gond on an opponent's creature is the board that refutes
    -- that -- the opponent taps their own creature and gets the token, both of
    -- which a granter-anchored ability gets backwards. Sixth Sense refutes it in
    -- the other half: the card that draws is the enchanted creature's
    -- controller's.
    --
    -- Rejected: an arm per ability kind. The ability variable is the one this
    -- module cannot name, so two arms would need two variables, and every
    -- position instantiating them -- StaticAbility, ContinuousEffect,
    -- ModifyTarget -- would carry both. The sum lives one module out
    -- instead, in Parun.Types.GrantedAbility.
    GainAbility ability
  | -- | layer 6, CR 613.1f \/ 702.165a: this object gains the non-backup
    -- abilities of THIS effect's SOURCE, the grant backup's minted trigger makes
    -- ("it also gains the non-backup abilities of this creature").
    --
    -- The source is read rather than named, for SetControllerToSource's
    -- reason: a keyword's mint is card-independent data and cannot name the
    -- abilities of a card it has not met. What it carries is the keywords the
    -- card prints ABOVE the backup line (Parun.Types.Backup's printedAbove),
    -- which rule 702.165a's "printed below this one" keeps out.
    --
    -- EXPANDED AS THE ABILITY RESOLVES, by Parun.Engine.Resolve.Effect's
    -- ModifyTarget arm, into one ordinary GainKeyword or GainAbility per ability
    -- (the CR 613.11 rule abilities as one bundle) the source's COPIABLE
    -- characteristics (CR 707.2) carried as the ability
    -- was put on the stack (CR 702.165d), which is when Parun.Engine.Engine's
    -- placeBorne stamps them. So this arm never
    -- reaches Parun.Engine.Projection, and the grant outlives the source: a
    -- projection-time read would evaporate when the creature with backup died,
    -- where CR 702.165a's "until end of turn" keeps it.
    --
    -- The copiable values and not the printed face, which is CR 702.165b and CR
    -- 702.165c together: a permanent that entered as a COPY of a card with
    -- backup grants what it copied, and an ability a layer-6 effect afterwards
    -- gave the creature with backup is not granted. Parun.KeywordTriggerSpec's Backup group
    -- proves the first half.
    GainAbilitiesOfSource (Set.Set Keyword.Keyword)
  | -- | layer 6, CR 613.1f: this object has each activated ability of each
    -- card in exile the payload names, each carrying the payload's extra
    -- restrictions (Locus of Enlightenment, Mairsil, the Pretender).
    GainExiledCardAbilities ExiledCardAbilities.ExiledCardAbilities
  | -- | layer 6, CR 613.1f / 123.7a: this object has the abilities printed on
    -- the ability stickers on this effect's source, read off the stickers
    -- (Pin Collection).
    --
    -- Not implemented: the stickers on objects other than the source
    -- (Clandestine Chameleon) (#4935).
    GainAbilitiesOfStickers
  | LoseAllAbilities -- layer 6 (Humility)
  | -- | layer 6, CR 613.1f: this object loses the abilities carrying this name
    -- -- "this creature loses this ability", the clause every Licid prints ahead
    -- of animating itself into an Aura.
    --
    -- A NAME and not an index, Parun.Types.ActivatedAbility's own posture: that
    -- type's header rules an index out for Action.Activate, and the same argument
    -- rules it out here. The name is written on the ability by its own card and
    -- joined back here, so the removal survives a card whose list of abilities is
    -- reordered.
    --
    -- An ACTIVATED ability (ActivatedAbility.name), a TRIGGERED ability
    -- (TriggeredAbility.name), a PRINTED REPLACEMENT (PrintedReplacement.name)
    -- and a STATIC ability (StaticAbility.name) are the carriers of a name, so
    -- those are what this reaches: Gliding Licid removes the first, Synthetic
    -- Silenced Sentinel the second, Glittering Lion the third, Synthetic Muted
    -- Captain the fourth. So are the rule and player abilities CR 116.2d's
    -- ignore names (AffectedUnless.name, PlayerStaticAbility.name,
    -- ActivationProhibition.name), read per row by
    -- Projection.namedAbilityRemoval: Synthetic Grounded Sentry removes a
    -- "can't block", Synthetic Hushed Warden a "can't gain life".
    --
    -- Distinct from LoseAllAbilities above, and observably so: a Licid keeps its
    -- other printed ability ("Enchanted creature has flying") while losing the
    -- one it activated, which a wipe gets wrong in both directions.
    LoseNamedAbility AbilityName.AbilityName
  | -- | layer 6, CR 613.1f: this object loses this rule-702 keyword -- Sky
    -- Tether's "enchanted creature has defender and loses flying", the clause an
    -- Aura or Equipment prints beside a drawback.
    --
    -- The MIRROR of GainKeyword above, and a closed-half CITATION for the same
    -- reason: the payload is a Keyword, which rule 702 defines, so casing on it
    -- is the act CLAUDE.md licenses rather than the effect-identity case it
    -- forbids.
    --
    -- Distinct from both removals above, and observably so. LoseAllAbilities
    -- would take the enchanted creature's other abilities with the flying, and
    -- LoseNamedAbility reaches only an ability the card that prints it named,
    -- which no printed keyword carries.
    --
    -- Carries a WRITTEN Keyword rather than a KeywordFamily, which is what the
    -- printings ask for: every one that removes a single keyword names the
    -- instance, payload and all -- "loses flying", "loses defender", "loses
    -- protection from black" (Cephalid Snitch), "loses forestwalk" (Scarwood
    -- Hag) -- so a family designator would be a second spelling of the same
    -- removal, the objection KeywordFamily's own header raises against widening
    -- HasKeyword. The removal that DOES name a family is the arm below, which
    -- reaches every written instance at once.
    LoseKeyword Keyword.Keyword
  | -- | layer 6, CR 613.1f / 702.14a: this object loses every keyword of one
    -- FAMILY, Hammerheim's "target creature loses all landwalk abilities".
    --
    -- Beside LoseKeyword above rather than in place of it. CR 702.14a's "landwalk
    -- is a generic term" is the clause this arm writes and the written removals
    -- cannot: naming forestwalk leaves swampwalk standing, and a card that names
    -- the family has no list of instances to enumerate.
    -- Parun.Engine.Projection.applyModification deletes every projected keyword
    -- whose Parun.Engine.Keyword.familyOf matches, which is why the payload is a
    -- KeywordFamily and not a representative Keyword.
    --
    -- A closed-half CITATION exactly as LoseKeyword's Keyword is: KeywordFamily
    -- names rule 702's abilities with their payloads dropped.
    --
    -- Not implemented: a removal scoped to every keyword an object has at once,
    -- which names no family -- Modular Monstrosity's "loses all keyword
    -- abilities" (gap #2983).
    LoseKeywordFamily KeywordFamily.KeywordFamily
  | SetBasePowerToughness SetBasePowerToughness.SetBasePowerToughness -- layer 7b (Humility 1/1; Opalescence mana value)
  | ModifyPowerToughness ModifyPowerToughness.ModifyPowerToughness -- layer 7c (Giant Growth +3/+3)
  | -- | layer 4, CR 305.7: this object's land subtype becomes this one, or gains
    -- it in addition to its others, as the mode says (Blood Moon -> Mountain,
    -- Urborg -> Swamp). CR 305.7's ability strip is the Replace mode's alone.
    LandSubtype ChangeMode.ChangeMode Subtype.Subtype
  | -- | layer 4, CR 613.1d / 205.1a / 205.1b: LandSubtype or CreatureSubtype, as
    -- the family says, with the subtype chosen for THIS effect's SOURCE
    -- (Object.chosenSubtype), as it entered or by Effect.ChooseQuality.
    -- Convincing Mirage's "enchanted land is the chosen type"; Mystic Compass's,
    -- which a resolution bakes; Adaptive Automaton's "is the chosen type in
    -- addition to its other types".
    --
    -- A constructor rather than a value LandSubtype could carry, for ChosenColor's
    -- reason: a static ability's modification is card data and cannot name a type
    -- a player will choose. The family is written rather than read off the
    -- choice so that Parun.Engine.Projection.setsLandSubtype, CR 305.7's strip,
    -- classifies by constructor as it does LandSubtype's.
    ChosenSubtype ChangeMode.ChangeMode SubtypeFamily.SubtypeFamily
  | -- | layer 4, CR 205.1a / 205.1b: this object's creature types become this
    -- one, or it gains it in addition to them, as the mode says (Turn to Frog ->
    -- Frog, Life and Limb -> Saproling). Strips no ability and touches no card
    -- type. A card setting two (Otherworldly Escort's "It's a Spirit Detective")
    -- lists a Replace, then an InAddition, in one effect.
    CreatureSubtype ChangeMode.ChangeMode Subtype.Subtype
  | -- | layer 4, CR 205.1b add over the WHOLE of CR 205.3m: this object gains
    -- every creature type. "Gains all creature types" (Wings of Velis Vel) and
    -- "is every creature type" (Maskwood Nexus) are the two printed wordings.
    --
    -- NULLARY, where CreatureSubtype above carries one type: rule 205.3m's
    -- list is the payload, it grows with every set, and no card enumerates it.
    -- A card that could would be authoring the rulebook.
    --
    -- An ADD, so the object keeps its other families (a Vehicle stays a Vehicle)
    -- and its own creature types. That is CR 702.73a's changeling stated as an
    -- ordinary timestamped effect -- which is exactly what the keyword becomes
    -- when anything GRANTS it, a static ability or a resolution alike (CR 604.3a
    -- denies the granted instance CDA status), so
    -- Parun.Engine.Projection.grantedDefiningParts mints this arm.
    AddEveryCreatureSubtype
  | -- | layer 4, CR 613.1d / CR 205.1a: this object loses every creature type.
    -- "Loses all creature types" (Nameless Inversion) is the printed wording.
    --
    -- NULLARY, the mirror of AddEveryCreatureSubtype above and for its reason:
    -- rule 205.3m's list is the payload and no card enumerates it.
    --
    -- A REMOVAL rather than a CreatureSubtype Replace over an empty set, which is
    -- LoseAllAbilities' shape: CR 205.1a's last sentence -- "removing an
    -- object's subtype doesn't affect its card types at all" -- is a statement
    -- about removal, and it is what keeps a stripped artifact creature an
    -- artifact. Parun.ProjectionSpec's "CR 205.1a Nameless Inversion strips the
    -- Wall type, and the Wall blocks what no Wall may block" proves that.
    LoseEveryCreatureSubtype
  | -- | layer 4, CR 613.1d / 205.1a set: this object's creature types become
    -- those of the card its source exiled LAST among those the filter matches
    -- (CR 607.2a, 613.7d) -- Duplicant. No such card leaves them alone.
    SetCreatureSubtypesOfLastCardExiledWith (Filter.Filter Keyword.Keyword)
  | -- | layer 4, CR 613.1d / CR 205.1b add, over the subtype families the two
    -- family-tagged arms above cannot reach: CR 205.3g's artifact types (Ygra,
    -- Eater of All's "other creatures are Food artifacts in addition to their
    -- other types") and CR 205.3h's enchantment types (a permanent that becomes
    -- an Aura). CR 205.3d still refuses a type that corresponds to no card type
    -- the object has, so a card granting one authors the card type first.
    --
    -- UNTAGGED where LandSubtype and CreatureSubtype carry their family
    -- implicitly, and that is the whole reason those two are not generalised into
    -- this: their constructor IS CR 612.2's gate in
    -- Parun.Engine.Projection.rewriteModificationWith, which asks whether the word
    -- being swapped is a land type or a creature type. This arm has no such gate
    -- to state, so it is deliberately left unrewritten there. Every printed text
    -- changer swaps a colour word, a basic land type or a creature type, and none
    -- reaches an artifact or enchantment type -- Scryfall
    -- o:"replacing all instances of one", 2026-08-22, twelve cards, all read.
    -- Parun.CardSpec holds the fence: no AddSubtype in the pool may carry a land
    -- type or a creature type, since those have their own arms and their own gate.
    AddSubtype Subtype.Subtype
  | -- | layer 4, CR 613.1d / 205.1a / 205.1b: this object's card types become
    -- this one, or it gains it in addition to them, as the mode says (Song of the
    -- Dryads -> Land, Opalescence -> Creature).
    --
    -- The Replace mode alone carries CR 205.1a's consequences: instant and
    -- sorcery survive it, and a subtype whose family correlates only with a card
    -- type just removed goes with it (Parun.Engine.Subtype's
    -- correlatedCardTypes), which is why
    -- Parun.Engine.Projection.modificationWrites gives that mode Subtypes as well
    -- as Types.
    --
    -- Carries one CardType. A card that adds two ("becomes an artifact
    -- creature") is CR 205.1b's retaining phrase, so InAddition twice over --
    -- rule 702.122a's crew is written that way in Parun.Engine.Keyword. Gliding
    -- Licid stops being a Creature by becoming an Enchantment, which is the
    -- Replace mode and not the removal below.
    CardType ChangeMode.ChangeMode CardType.CardType
  | -- | layer 4, CR 613.1d / 205.1a removal: this card type is taken away and no
    -- other put in its place -- CR 702.151b's "attaching an Equipment with
    -- reconfigure to another creature causes the Equipment to stop being a
    -- creature". The third layer-4 card-type arm, and the only one that leaves
    -- the object with FEWER types than it had: CardType's Replace mode replaces
    -- every type, and its InAddition mode removes none.
    --
    -- CR 205.1a's own consequence for subtypes rides along, exactly as it does
    -- on CardType's Replace mode: a subtype correlated only with the removed card type goes with
    -- it (an attached Rabbit Battery is no longer a Rabbit), and one correlated
    -- with a card type the object still has stays (it is still an Equipment,
    -- Equipment being an artifact type). Parun.Engine.Projection.cardTypesAfter
    -- threads the whole unit's answer into that check, so both arms ask one
    -- predicate.
    LoseCardType CardType.CardType
  | -- | layer 4, CR 613.1d / 205.4b: this object gains a supertype (Leyline of
    -- Singularity's "All nonland permanents are legendary"). An ADD and never a
    -- set, because CR 205.4b says so outright -- "when an object gains or loses a
    -- supertype, it retains any other supertypes it had" -- so no supertype arm
    -- has the ChangeMode the subtypes need.
    --
    -- Carries one Supertype rather than a set, the narrowing LandSubtype and
    -- CreatureSubtype already take: no printing grants two at once, and a card
    -- that did would author two modifications.
    AddSupertype Supertype.Supertype
  | -- | layer 4, CR 613.1d / 205.4b: this object loses a supertype (Arcum's
    -- Weathervane's "Target snow land is no longer snow"). The removal beside the
    -- grant above, and the same rule governs it: the object's OTHER supertypes
    -- survive, and neither its card types nor its subtypes move.
    RemoveSupertype Supertype.Supertype
  | ChangeWord ChangeWord.ChangeWord -- layer 3, CR 612 (Magical Hack, Sleight of Mind: from -> to)
  | -- | layer 3, CR 613.1c / 612.5: the two objects in this effect's affected set
    -- exchange their text boxes (Exchange of Words, which CR 612.5 names as the
    -- only card that does it).
    --
    -- NULLARY and MUTUAL: the two sides are the effect's own affected set, which
    -- CR 611.2c froze to exactly two ids at resolution, so one continuous effect
    -- with one timestamp produces both rewrites and neither can be applied twice
    -- or half-undone. Parun.Engine.Projection.exchangePartner is what reads the
    -- other side out of that set, which is why this arm carries no ObjectId of
    -- its own -- one that did would need two effects, and CR 613.7a would then
    -- have two timestamps to order.
    --
    -- Layer 3 and not layer 1: CR 612.5 replaces the RULES TEXT alone, where a
    -- copy effect (CR 706/707) would take the name, types and P/T with it. So a
    -- 5/5 Dragon given a 1/1 Bird's text box stays a 5/5 Dragon, and CR 707.2
    -- leaves the copiable values untouched, so a Clone of either creature copies
    -- the PRINTED text.
    --
    -- The text moved is the receiving object's, so CR 113.7 makes the receiver
    -- the source of every ability that arrives and each "this permanent"
    -- self-reference re-binds to it -- the same posture GainAbility takes, and
    -- for the same reason.
    ExchangeTextBoxes
  | -- | layer 3, CR 613.1c / 612.7: this object also has the name of every card
    -- whose face matches the Filter (Spy Kit).
    AddNamesMatching (Filter.Filter Keyword.Keyword)
  | -- | layer 3, CR 613.1c / 612.6: this object has the full text of the top
    -- card of a graveyard (Volrath's Shapeshifter).
    HasFullText (FullText.FullText ability)
  | -- | layer 3, CR 612.8: this object has only this name (Witness Protection).
    SetName CardName.CardName
  | -- | layer 3, CR 123.6 / 612.9: a name sticker's word in this object's
    -- names. Engine-minted (Parun.Engine.Projection.stickerGathered); no card
    -- authors it.
    InsertNameWords NameInsertion.NameInsertion
  | -- | layer 2, CR 613.1b: set this object's controller. The PlayerId is BAKED at
    -- effect creation (CR 611.2c) by Resolve.applyEffect, never chosen: the
    -- effect's source's controller for GainControl, the OTHER permanent's
    -- controller for CR 701.12b's ExchangeControl. Applied only by
    -- Projection.controllerOf.
    --
    -- Meant to be runtime-only, and nothing ENFORCES that in the type: the
    -- codec round-trips the PlayerId, so card JSON could author one into an
    -- Effect.ModifyTarget. Baking a PlayerId into static card text is
    -- meaningless, so Parun.CardSpec lints the pool against it (#199).
    SetController PlayerId.PlayerId
  | -- | layer 2, CR 613.1b: this object's controller becomes the controller of
    -- THIS effect's SOURCE (Control Magic). Payload-free because the player is
    -- DERIVED at projection time, the contrast with SetController above, whose
    -- PlayerId CR 611.2c fixes at resolution. A static ability's modification is
    -- CARD DATA and cannot name a PlayerId, so this is the only shape in which a
    -- printed card can grant control.
    --
    -- CR 303.4e: an Aura's controller and the enchanted object's controller are
    -- separate. Deriving from the SOURCE's controller is what keeps them so --
    -- gaining control of the creature does not gain control of the Aura, and
    -- gaining control of the Aura DOES move the creature.
    SetControllerToSource
  | -- | layer 5, CR 613.1e / 105.3: this object becomes these colours, replacing
    -- its colours or in addition to them as the mode says. An empty set under
    -- Replace is "becomes colourless" (CR 105.2c).
    Colors ChangeMode.ChangeMode (Set.Set Color.Color)
  | -- | layer 5, CR 613.1e / 105.3: this object becomes the colour chosen for
    -- THIS effect's SOURCE (Object.chosenColors), replacing its colours or in
    -- addition to them as the mode says. Shifting Sky's and Painter's Servant's
    -- "the chosen color"; Distorting Lens's, which a resolution bakes.
    --
    -- The colour is DERIVED at projection time from the source rather than
    -- baked into card data: a static ability's modification cannot name a
    -- colour a player will choose, which is why this is a constructor beside
    -- Colors rather than a value it could carry.
    ChosenColor ChangeMode.ChangeMode
  | -- | layer 7d, CR 613.4d: switch this object's power and toughness. It acts
    -- on whatever 7a, 7b and 7c already produced, not on the printed box.
    -- Carries no payload: two applications return the object to normal for free.
    SwitchPowerToughness
  | -- | CR 510.1a: this creature assigns combat damage equal to its toughness.
    AssignCombatDamageWithToughness
  | -- | CR 510.1b-c: this creature's controller may have it assign all its
    -- combat damage where the option says instead.
    MayAssignCombatDamage CombatDamageOption.CombatDamageOption
  | -- | CR 702.184c: while this object's controller controls it, that player's
    -- station abilities read the tapped creature's toughness where it exceeds
    -- its power (Tapestry Warden). Self-only, like DestructionR: a fact about the
    -- controller, not a set of affected permanents.
    GrantsStationToughness
  | -- | Alchemy's "intensifies by N" (Static Discharge): add N to the object's
    -- intensity, which no CR rule names.
    Intensify Quantity.Quantity
  deriving (Eq, Ord, Show)
