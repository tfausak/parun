module Pawl.Types.CastOffer where

import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ManaSpending as ManaSpending
import qualified Pawl.Types.TurnUpEvent as TurnUpEvent

-- | What an effect says about a cast IT offers, beyond what casting the card
-- would ordinarily mean -- CR 310.12b's "you may cast it transformed without
-- paying its mana cost", whose two riders are the first two fields.
--
-- Carried by the OPCODE (OfferCast) and not by the card, for
-- Pawl.Types.EntryRiders' reason: neither rider is a characteristic of the
-- object (CR 109.3). One printed card can be offered transformed by one effect
-- and normally by another, and CR 118.9's alternative cost is applied to a spell
-- "from another effect" in the rule's own words.
--
-- TWO independent riders, because the rules make them independent. `transformed`
-- is CR 712.11a, which is about which FACE is put onto the stack and says
-- nothing about what is paid; `withoutPayingManaCost` is CR 118.9's alternative
-- cost, which is about payment and says nothing about faces. Cards print each
-- without the other -- a cascade's "you may cast it without paying its mana
-- cost" transforms nothing.
--
-- Those two are Bools rather than richer choices because each is the presence
-- or absence of one printed clause. `payingInstead` is CR 118.9's OTHER wording
-- -- "you may pay [cost] rather than its mana cost" -- and it is a third field
-- rather than another value of the second for exactly the reason this haddock
-- gave before it existed: a stated cost is a different rider, not a different
-- setting of "without paying".
--
-- CR 118.9a allows a spell only ONE alternative cost, so the two cost riders are
-- never both meaningful at once; Pawl.Engine.Resolve.Effect.offerCast reads
-- `withoutPayingManaCost` first, and no producer sets both. Rule 702.94a's
-- miracle and rule 702.35a's madness are what set this one, carried here rather
-- than on the card for this type's own reason: the cost is not a characteristic,
-- and the same card cast any other way pays what it prints.
data CastOffer = MkCastOffer
  { transformed :: Bool,
    withoutPayingManaCost :: Bool,
    payingInstead :: Maybe (Cost.Cost Keyword.Keyword),
    -- | CR 118.14's "and mana of any type can be spent to cast that spell",
    -- printed on Tinybones, the Pickpocket beside the offer itself.
    --
    -- A rider of its OWN and not a setting of the three above, for the reason
    -- `payingInstead` is its own field: rule 118.14 widens how a cost may be PAID
    -- and says nothing about which cost or which face, so it is independent of
    -- both. Rule 118.14's last sentence is why it rides the offer rather than the
    -- card -- the permission is the offering effect's, so the same card cast any
    -- other way pays its printed colours.
    spending :: ManaSpending.ManaSpending,
    -- | CR 702.85a's second condition -- "if the RESULTING SPELL's mana value is
    -- less than this spell's mana value" -- as a quality the half being offered
    -- must have. Nothing is the unmarked case every other offer takes.
    --
    -- A rider of its own, `payingInstead`'s reason: rule 702.85a states it in a
    -- sentence separate from the permission, and it narrows neither the payment
    -- nor the face-up-ness but WHICH HALF may be taken. Asked per castable half
    -- for CR 709.3a's and CR 712.11c's reason, which is the whole point of it:
    -- the CARD's mana value already passed the walk that exiled it, and an
    -- adventurer card's other half (Fae of Wishes' Granted, {3}{U} behind a
    -- {1}{U} creature) is the spell whose mana value the rule asks about second.
    --
    -- Matched in Pawl.Engine.Resolve.Effect.offerCast against the FACE's own view
    -- and the resolution's Filter.Context, so an OfSource mana value operand
    -- reads the same source mana value here that the exiling walk read.
    restriction :: Maybe (Filter.Filter Keyword.Keyword),
    -- | CR 601.2b: the keyword ability whose cost this offer states, or Nothing
    -- for an offer no keyword ability is behind -- which is every offer but rule
    -- 702.62a's third ability and rule 702.35a's second.
    -- Pawl.Engine.Resolve.Effect.offerCast writes it
    -- onto the candidate it builds, so it reaches Pawl.Types.Object's castUsing
    -- as any printed alternative's tag does.
    --
    -- A rider of its OWN, `payingInstead`'s reason: it names WHO offered the
    -- cost and narrows neither the payment nor the face, and the same cost
    -- offered by an effect rather than by a keyword carries no tag.
    offeredBy :: Maybe Keyword.Keyword,
    -- | CR 708.4: cast the card face down, as CR 708.2a's 2\/2 under
    -- FaceDownReason.CastFaceDown -- "unless otherwise specified by the effect
    -- that ... allowed it to be cast face down", and no producer specifies
    -- otherwise. The set is the events the offering effect turns the permanent
    -- face up before (Pawl.Types.FaceDownState's `turnsUpBefore`). Nothing for
    -- a face-up cast.
    --
    -- A rider of its own, `transformed`'s reason: it says which characteristics
    -- the spell has (CR 708.4) and nothing about what is paid.
    faceDown :: Maybe (Set.Set TurnUpEvent.TurnUpEvent),
    -- | Illusionary Mask's "a creature card in your hand whose mana cost could be
    -- paid by some amount of, or all of, the mana you spent on {X}": only a card
    -- whose mana cost the mana spent on the offering ability's {X} could pay is
    -- on offer, colours and all -- the activation's mana (CR 602.2b,
    -- Pawl.Types.Object.manaSpent) less what paid the rest of its total, a cost
    -- increase's included (Object.manaCostPaid).
    payableFromSpent :: Bool,
    -- | CR 601.2f: the generic mana the offered cast costs less -- God-Eternal
    -- Kefnet's "that copy costs {2} less to cast" -- in Pawl.Types.CandidateCost's
    -- `reductions` shape, so it applies after every increase. 0 for none.
    -- Pawl.Types.CastFromZone's `reduction` on the offer rather than a
    -- permission.
    reduction :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
