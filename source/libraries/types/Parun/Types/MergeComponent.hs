module Parun.Types.MergeComponent where

import qualified Parun.Types.ComponentCard as ComponentCard
import qualified Parun.Types.MeldSource as MeldSource
import qualified Parun.Types.PrintingId as PrintingId

-- | CR 730.2: one component of a merged permanent -- "the card or copy that
-- represented that object in addition to any other components that were
-- representing it". What represents the component, plus which KIND of component
-- it is.
--
-- The kind is carried because CR 730.2d asks it -- "if a merged permanent
-- contains a token, the resulting permanent is a token only if the topmost
-- component is a token" -- and CR 730.3's departure asks it again: a card
-- component is put into a zone and a token component ceases to exist there (CR
-- 111.7). A bare printing cannot answer either, tokens being interned as
-- printings like everything else.
--
-- A SEPARATE type rather than Parun.Types.Source itself, which would make Source
-- recursive and admit an ability or an emblem as a component. These are the
-- shapes rule 730.2's sentence names, and no more.
--
-- POSITIONAL rather than a shared `printing` field, which the meld arm cannot
-- carry: two cards represent that component and neither is the printing its
-- characteristics come off (CR 712.8g). Parun.Engine.Game.printingOfComponent is
-- the total read that field used to be, beside the other classifiers over this
-- type.
data MergeComponent
  = -- | CR 108.2: a card component, with the identity it keeps (CR 108.3).
    OfCard ComponentCard.ComponentCard
  | -- | CR 111.3 / 111.13: a token component, a merged copy of a mutating spell
    -- included, named by the printing its characteristics were interned as.
    OfToken PrintingId.PrintingId
  | -- | CR 701.42a: a melded component -- one component that two cards represent,
    -- which Parun.Types.MeldSource carries and documents.
    --
    -- ONE component rather than one per card, which is the only reading under
    -- which CR 730.2a is answerable: rule 701.42a puts the two cards down as "a
    -- single object", giving them no order between them, so a model that made
    -- each its own component would leave "its topmost component" with two heads
    -- and no tie-break. CR 730.2c is what keeps the meld intact across the merge
    -- -- "a merged permanent is the same object that it was before" -- so CR
    -- 712.8g still gives that component only the combined back face, which is
    -- what Parun.Engine.Game.printingOfComponent answers with.
    -- docs/decisions.md, "Whether a melded permanent is one mutate component
    -- or two".
    --
    -- CR 730.3's departure still puts down two CARDS, not a melded permanent:
    -- Parun.Engine.Game.componentsOf expands this arm into rule 712.21's two
    -- cards, so every reader of that classifier keeps quantifying over cards.
    OfMeld MeldSource.MeldSource
  deriving (Eq, Ord, Show)
