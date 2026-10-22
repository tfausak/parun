module Pawl.Types.AsCopy where

import qualified Data.Sequence as Seq
import qualified Pawl.Types.CopyClause as CopyClause
import qualified Pawl.Types.CopyDomain as CopyDomain
import qualified Pawl.Types.CopyRecipient as CopyRecipient
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.Keyword as Keyword

-- | CR 707.5 / 614.1c: the payload of Pawl.Types.EntryRewrite's @AsCopy@ arm --
-- "you may have this permanent enter as a copy of [any enchantment on the
-- battlefield]" -- and of Pawl.Types.TurnUpRewrite's, CR 614.1e's "as this
-- creature is turned face up ... it becomes a copy" (Vesuvan Shapeshifter) --
-- and of Pawl.Types.AttachRewrite's (Dinosaur Headdress).
--
-- The Filter is the printed noun phrase after "a copy of", read as a quality of
-- the candidate: Clone's "any creature", Copy Enchantment's "any enchantment",
-- Clever Impersonator's negated "any nonland permanent".
-- It is NOT the rewrite's @matching@ field, which says which ENTERING permanent
-- the replacement modifies (CR 614.12's subject); these are two different
-- objects and Clone writes @IsSource@ for the one and @HasCardType Creature@ for
-- the other. Both are read with the replacement's source as "this", so Essence
-- of the Wild's "enter as a copy of this creature" is the reverse, @IsSource@
-- as the Filter, and Infinite Reflection's "of enchanted creature" is
-- @IsHostOfSource@.
--
-- "On the battlefield" is not in the Filter and cannot be: the zone is the
-- offer's domain rather than a quality of a candidate. It is `among` instead,
-- which Pawl.Engine.Replacement.legalCopyTargets walks.
--
-- The exceptions are CR 707.9's "except ..." clause, empty for a plain Clone.
-- They ride the rewrite rather than being a rewrite of their own, because CR
-- 707.9 makes them modifications OF the copying process: they happen only when a
-- copy is actually made, so declining the "may" leaves the object its printed
-- self and no exception applies.
data AsCopy ability effect = MkAsCopy
  { eligible :: Filter.Filter Keyword.Keyword,
    -- | CR 707.9: the parts of the "except ..." clause, each applying always
    -- or under a CR 707.9f condition (Pawl.Types.CopyClause). Empty for a plain
    -- Clone.
    clauses :: [CopyClause.CopyClause ability],
    -- | CR 614.1d inside CR 614.1c's sentence: Vesuva's "you may have this land
    -- enter TAPPED as a copy of any land on the battlefield". One replacement
    -- doing two things, so the status rides the rewrite rather than sitting in a
    -- second EntryRewrite.Tapped beside it: a second replacement would tap a
    -- Vesuva that DECLINED the copy, which the printed sentence does not.
    --
    -- Not a CopyException: CR 707.2 excludes status from the copiable values, so
    -- this may not be written into the snapshot. It goes onto the object through
    -- Pawl.Engine.Event.enterTapped, the same write EntryRewrite.Tapped makes.
    tapped :: Bool,
    -- | CR 707.9g / 603.11: the triggered ability linked to this replacement,
    -- "When you do, ..." in the same paragraph (Wall of Stolen Identity). Empty
    -- for none. Its effects read the copied object under
    -- Pawl.Engine.Binding.copiedObject.
    --
    -- Effects rather than a printed triggered ability, because the copy
    -- overwrites the permanent's abilities (CR 707.2) and the ability is not
    -- one it has afterwards: it rides the replacement, and
    -- Pawl.Engine.Event.becomeCopyAs arms it as a reflexive entry only where a
    -- copy was made.
    whenYouDo :: Seq.Seq effect,
    -- | CR 707.5's domain: the battlefield for "any creature on the
    -- battlefield" (Clone), every graveyard for "any creature card in a
    -- graveyard" (Superior Spider-Man), the craft materials for "an exiled
    -- creature card used to craft this Equipment" (Dinosaur Headdress).
    among :: CopyDomain.CopyDomain,
    -- | CR 611.2a: how long the copy lasts (Vesuvan Shapeshifter's "until this
    -- creature is turned face down"), Nothing for a printing stating none.
    -- BecomeCopy.duration's field and read the same way: Nothing stamps the
    -- copy, a stated duration stores it as a Pawl.Types.ActiveCopy row that can
    -- end.
    duration :: Maybe Duration.Duration,
    -- | Which object becomes the copy: the entering one (Clone), or what it is
    -- attached to (Metamorphic Alteration). Onto its host and with no
    -- `duration`, the copy is a static ability's (CR 611.3a), stored to follow
    -- the host for as long as the source exists (CopyCoverage.SourceHost).
    recipient :: CopyRecipient.CopyRecipient,
    -- | CR 707.5's "you may" (Clone), False for a printed "choose"
    -- (Metamorphic Alteration's "choose a creature") or a mandatory "enter as
    -- a copy" (Essence of the Wild).
    optional :: Bool
  }
  deriving (Eq, Ord, Show)
