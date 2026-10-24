module Parun.Types.CostComponent where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Behold as Behold
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CountersFromPermanents as CountersFromPermanents
import qualified Parun.Types.CountersFromThis as CountersFromThis
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.DiscardCause as DiscardCause
import qualified Parun.Types.ExileCardsFromGraveyard as ExileCardsFromGraveyard
import qualified Parun.Types.ExileCardsFromHand as ExileCardsFromHand
import qualified Parun.Types.ExileMaterials as ExileMaterials
import qualified Parun.Types.ExilePermanents as ExilePermanents
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Gift as Gift
import qualified Parun.Types.ReturnPermanents as ReturnPermanents
import qualified Parun.Types.Rounding as Rounding
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.TapForTotalPower as TapForTotalPower
import qualified Parun.Types.TapPermanents as TapPermanents

-- | One component of a Parun.Types.Cost's non-mana part, alongside its mana part
-- (CR 601.2f).
--
-- Open-half card data. Parun.Engine.Cost is where every reading of it lives but
-- one: CR 605.1a's "its cost and effect don't move any card to or from a
-- library" is Parun.Engine.ManaAbility.costMovesLibraryCard, which cannot route
-- through Parun.Engine.Cost without a module cycle (see that function).
-- Parun.Engine.Filter.rewriteComponent cases on it too and reads nothing -- CR
-- 612.1's word swap is a traversal that reconstructs every arm.
--
-- Either way what the rules core takes from it is a CLASSIFICATION (can this be
-- paid? does it require the tap symbol? does it touch a library?) and never the
-- identity of a component.
--
-- PARAMETRIC in the keyword for the Filter it carries, and for that type's
-- reason alone -- see Parun.Types.Filter.
data CostComponent keyword
  = -- | CR 107.5: tap this permanent; one already tapped can't pay the cost.
    -- CR 302.6 gates it on summoning sickness.
    TapThis
  | -- | CR 107.6: {Q}, untap this permanent; one already untapped can't pay the
    -- cost, and CR 302.6 gates it as it gates TapThis.
    UntapThis
  | -- | CR 701.21a / Mindslaver: sacrifice the object the cost is on.
    SacrificeThis
  | -- | CR 118.1 as a cost / Grinning Ignus: return the permanent the cost is on
    -- to its owner's hand.
    ReturnThis
  | -- | CR 119.4 / Greed, Hatred: pay this much life, payable only out of a life
    -- total at least that large.
    PayLife CostAmount.CostAmount
  | -- | CR 119.4 / 107.1a / Lurking Evil: pay half the paying player's life,
    -- rounded as printed, fixed to a PayLife by Parun.Engine.Cost.announce.
    PayHalfLife Rounding.Rounding
  | -- | CR 701.21a / Village Rites, Fireblast, Grim Hireling: sacrifice this many
    -- permanents matching the Filter, which the payer chooses.
    Sacrifice (Sacrifice.Sacrifice keyword)
  | -- | CR 702.122a's cost half / crew: tap any number of untapped permanents
    -- matching the Filter, chosen so that their TOTAL power reaches totalPower.
    TapForTotalPower (TapForTotalPower.TapForTotalPower keyword)
  | -- | CR 601.2f / Springleaf Drum: tap exactly this many permanents matching the
    -- Filter, chosen by the payer. CR 302.6 does not reach it -- see
    -- Parun.Engine.Cost.requiresSicknessCheck.
    TapPermanents (TapPermanents.TapPermanents keyword)
  | -- | CR 118.1 as a cost / Meloku the Clouded Mirror: return exactly this many
    -- permanents matching the Filter to their owners' hands, chosen by the payer.
    ReturnPermanents (ReturnPermanents.ReturnPermanents keyword)
  | -- | CR 118.1 / 406.2 as a cost / Food Chain: exile exactly this many
    -- permanents matching the Filter, chosen by the payer.
    ExilePermanents (ExilePermanents.ExilePermanents keyword)
  | -- | CR 601.2f / 701.9b / Cathartic Reunion, Magmatic Insight: discard this many
    -- cards matching the Filter from hand, which the discarding player chooses.
    DiscardCards (DiscardCards.DiscardCards keyword)
  | -- | CR 702.29a / 702.77a / Faerie Macabre: discard the card the cost is on,
    -- carrying the DiscardCause the payment logs, since CR 702.29c's cycling
    -- trigger reads which rule spelled the cost.
    DiscardThis DiscardCause.DiscardCause
  | -- | CR 118.12 in its hand-to-battlefield form / Hakbal of the Surging Soul: the
    -- paying player puts one card matching the Filter from their own hand onto the
    -- battlefield.
    PutCardFromHandOntoBattlefield (Filter.Filter keyword)
  | -- | CR 107.14 / Longtusk Cub, Sphinx of the Revelation: pay this many energy
    -- counters.
    PayEnergy CostAmount.CostAmount
  | -- | CR 606.4 / Jace Beleren: put this many loyalty counters on the permanent
    -- the cost is on.
    AddLoyaltyToThis Natural.Natural
  | -- | CR 606.4's other half / Jace Beleren: remove this many loyalty counters
    -- from the permanent the cost is on, which CR 606.6 gates on it having them.
    -- Tamiyo, Compleated Sage's [-X] is this with an announced amount.
    RemoveLoyaltyFromThis CostAmount.CostAmount
  | -- | CR 118.1 as a cost / Barkhide Troll, Hickory Woodlot: remove this many
    -- counters of one kind from the permanent the cost is on.
    RemoveCountersFromThis (CountersFromThis.CountersFromThis keyword)
  | -- | CR 118.1 as a cost / Zameck Guildmage, Tayam, Luminous Enigma,
    -- Retribution of the Ancients: remove this many counters from permanents
    -- matching the Filter, chosen by the payer.
    RemoveCounters (CountersFromPermanents.CountersFromPermanents keyword)
  | -- | CR 118.12's counter-placing cost / CR 701.63a's endure, Fortress
    -- Kin-Guard: put this many +1\/+1 counters on the permanent the cost is on,
    -- paid as the spell or ability resolves.
    PutPlusOneCountersOnThis Natural.Natural
  | -- | CR 701.68a as a cost / Bogslither's Embrace, Dawnhand Dissident: the paying
    -- player puts N -1\/-1 counters on a creature they control, and can't pay at
    -- all where they control none (CR 701.68b). Soul Immolation's "blight X"
    -- announces N; its printed ceiling rides Parun.Types.Face.maximumX (CR 101.1).
    Blight CostAmount.CostAmount
  | -- | CR 701.61a as a cost / Thornvault Forager, Camellia, the Seedmiser: the
    -- paying player forages, and can't pay at all where neither half of rule
    -- 701.61a can be carried out (CR 608.2d, Parun.Engine.Forage.canForage).
    --
    -- Nullary, rule 701.61a fixing everything but the forager's own two choices --
    -- Parun.Types.Effect's Forage arm is the same instruction from the other
    -- provenance, and Parun.Engine.Forage.forage is the one procedure both reach.
    Forage
  | -- | CR 705.1 as a cost / Karplusan Minotaur's "Cumulative upkeep--Flip a
    -- coin": the paying player flips one coin of CR 705.2's win/lose kind, and
    -- can always pay -- a coin is not one of CR 118.3's resources, so no board
    -- lacks it.
    --
    -- The OUTCOME is not part of the payment. Rule 705.2's win or loss is a
    -- property of the flip that other abilities watch (TriggerCondition's
    -- PlayerWinsCoinFlip and PlayerLosesCoinFlip), not a condition on whether the
    -- cost was paid; a lost flip pays the cost exactly as a won one does.
    --
    -- Nullary, rule 705.1 fixing everything but the flipper's call.
    -- Parun.Types.Effect's FlipCoin arm is the same instruction from the other
    -- provenance and binds a tally for a later effect to read, where a cost binds
    -- nothing; Parun.Engine.Event.flipWinLoseCoin is the one procedure both reach.
    FlipCoin
  | -- | CR 406.2 as a cost / Loxodon Surveyor: exile the card the cost is on, from
    -- the graveyard it is in -- the zone CR 113.6m then functions the ability in,
    -- read off the constructor by Parun.Engine.AbilityZone.costZones.
    ExileThisFromGraveyard
  | -- | CR 406.2 as a cost, from the other zone / Brittle Effigy: exile the
    -- permanent the cost is on, off the battlefield.
    ExileThis
  | -- | CR 406.2 in its choosing form / Headless Skaab: exile this many cards
    -- matching the Filter from the paying player's own graveyard (CR 400.3, CR
    -- 108.4), which the payer chooses.
    ExileCardsFromGraveyard (ExileCardsFromGraveyard.ExileCardsFromGraveyard keyword)
  | -- | CR 702.167a's [materials] / Tithing Blade: exile this many objects --
    -- or, where the payload says so, at least this many -- matching the Filter
    -- from among the permanents the paying player controls and the cards in their
    -- own graveyard, which the payer chooses.
    --
    -- A TWO-ZONE choice, Behold's shape below one zone over, and that is why this
    -- is not ExileCardsFromGraveyard with a wider criterion: rule 702.167b makes
    -- ONE criterion read over the battlefield and the graveyard at once, an
    -- exception to rule 109.2. Parun.Engine.Cost.materialCandidates is the union
    -- and Prompt.ChooseMaterials the ask.
    --
    -- BINDS the exiled materials for CR 702.167c's "the exiled cards used to
    -- craft it" (Parun.Engine.Binding.craftMaterials).
    ExileMaterials (ExileMaterials.ExileMaterials keyword)
  | -- | CR 406.2 in its fixed form / Circling Vultures: exile the topmost card of
    -- the paying player's graveyard matching the Filter, which CR 404.2's fixed
    -- order identifies without a prompt.
    ExileTopFromGraveyard (Filter.Filter keyword)
  | -- | CR 701.59a as a cost / Forensic Researcher: the paying player exiles any
    -- number of cards from their own graveyard whose total mana value reaches
    -- this number.
    --
    -- A THRESHOLD on an aggregate and not a count, TapForTotalPower's shape one
    -- zone over: how many cards a payment exiles is not settled until the payer
    -- picks them, which is why this is not ExileCardsFromGraveyard with a number.
    -- CR 701.59b is what makes it unpayable below the threshold.
    --
    -- BINDS the exiled cards under Parun.Engine.Binding.collectedEvidence, which
    -- is what CR 701.59c's "if evidence was collected" is read off through
    -- Quantity.WasBound; CR 118.8b's optional "you may collect evidence" is a
    -- Parun.Types.CostChoice, Behold's shape below.
    CollectEvidence Natural.Natural
  | -- | CR 701.59a as a cost / Urgent Necropsy: collect evidence N, N the total
    -- mana value of the permanents CR 601.2c's targets name
    -- (Parun.Engine.Cost.fixComputed).
    CollectEvidenceOfTargets
  | -- | CR 406.2 out of a hidden zone / Cadaverous Bloom, March of Wretched
    -- Sorrow: the paying player exiles this many cards matching the Filter from
    -- their own hand, which the payer chooses.
    ExileCardsFromHand (ExileCardsFromHand.ExileCardsFromHand keyword)
  | -- | CR 701.20a as a cost / Living Destiny: the paying player reveals one card
    -- matching the Filter from their own hand, which the payer chooses. CR 701.20b
    -- leaves the card in the hand, so this component spends nothing.
    RevealCardFromHand (Filter.Filter keyword)
  | -- | CR 701.4a as a cost / Caustic Exhale, Kindle the Inner Flame: the paying
    -- player beholds this many distinct objects matching the Filter, each either
    -- a matching card revealed from their hand or a matching permanent they
    -- control.
    --
    -- A TWO-ZONE choice, which is why this is not RevealCardFromHand with a wider
    -- criterion: rule 701.4a offers the hidden hand OR the battlefield, and the
    -- payer picks which. Parun.Engine.Cost.beholdCandidates is the union and
    -- Prompt.ChooseBehold the ask.
    --
    -- BINDS the beheld objects under Parun.Engine.Binding.beheldObject, which is
    -- what CR 701.4b's "if a [quality] was beheld" is read off through
    -- Quantity.WasBound; CR 118.8b's optional "you may behold" is an option of a
    -- Parun.Types.CostChoice whose other option is empty.
    Behold (Behold.Behold keyword)
  | -- | CR 701.4a then CR 406.2 / Champion of the Weird: the paying player
    -- beholds one object matching the Filter and exiles it, linking the card to
    -- the spell for CR 607.2q's "the exiled card".
    BeholdAndExile (Filter.Filter keyword)
  | -- | CR 701.17a as a cost / Millikin: the paying player mills this many cards.
    -- The only component that moves a card out of a library, which CR 605.1a reads
    -- to bar a mana ability and CR 601.2h reads to put the payment in its second
    -- pass.
    MillCards Natural.Natural
  | -- | CR 701.20a as a cost / Synthetic Tithe of Omens: the paying player
    -- reveals the top this-many cards of their library, which stay there.
    RevealTopOfLibrary Natural.Natural
  | -- | CR 702.174a as a cost / Scrapshooter: the paying player chooses an
    -- opponent to promise this gift to, recorded on the object the cost is on in
    -- Object.chosenPlayers so that CR 400.7d's exception carries it to the
    -- permanent the spell becomes.
    --
    -- The gift and nothing else: rule 702.174a fixes every word of this cost but
    -- the payer's own call, and the gift says which keyword's promise it is,
    -- Parun.Engine.Cost.nextPromise which instance's.
    -- Unpayable only where the payer has no opponent left (CR 102.2, CR 104.2a),
    -- which is what keeps it a cost rather than a no-op.
    ChooseOpponent Gift.Gift
  | -- | CR 701.67a as a cost / Geyser Leaper: this much of the cost's generic
    -- mana is a waterbend cost, so the payer may tap an untapped artifact or
    -- creature they control rather than pay each of it.
    --
    -- A LICENCE and not a payment. The mana is in the cost's own mana part, so
    -- CR 601.2f's increases and reductions reach it as they reach every other
    -- generic symbol and CR 601.2g's window pays it; `payComponent` spends
    -- nothing for this arm, and `claimOf` states no claim -- the taps the payer
    -- substitutes arrive as a TapPermanents component of their own
    -- (Parun.Engine.Cost.manaSubstitutions), which is what puts them on the
    -- ClaimAxis beside the rest of the cost.
    --
    -- The NUMBER is what CR 701.67b scopes the substitution to: the offer is
    -- capped at it even where the total cost holds other generic mana, so a
    -- waterbend {4} taxed {2} more by Suppression Field may tap four permanents
    -- and no more. Katara, Water Tribe's Hope's announced amount is the cost's
    -- own {X} (ManaSymbol.Variable), which the same announcement fixes.
    --
    -- A SPELL's mandatory additional waterbend cost rides the same way, its mana
    -- and this licence one Face.additionalCostChoices option (Water Whip); an
    -- optional one is the second option beside an empty one (Spirit Water
    -- Revival). So do a ward cost and an unless cost, paid at CR 118.12 (The
    -- Unagi of Kyoshi Island, Waterbending Lesson).
    Waterbend CostAmount.CostAmount
  | -- | CR 118.9 / 701.67a: Waterbend's licence and CR 701.67c event, paid as an
    -- alternative cost rather than an additional one, so it binds no record
    -- (Hama, the Bloodbender; Parun.Engine.Cost.permissionCost).
    WaterbendInstead Natural.Natural
  deriving (Eq, Ord, Show)
