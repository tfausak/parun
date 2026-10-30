module Parun.Types.DrawRewrite where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.FromOutsideTheGame as FromOutsideTheGame

-- | CR 614.1a / 614.11: how a replacement rewrites a would-draw-a-card event.
-- Once an arm replaces the draw it does not happen (CR 614.6), so CR 121.4's
-- draw-from-an-empty-library is never attempted. YouDraw leaves a draw
-- standing, by another seat, and OthersMayPayLife leaves it standing when
-- nobody pays.
--
-- A type rather than a payload-free Parun.Types.ReplacementEffect arm, for
-- Parun.Types.UntapRewrite's reason: a replacement effect is classified by the
-- event class it intercepts AND the rewrite shape it applies.
--
-- A shape per rewrite rather than a general list of effects: the printings
-- replace a draw with different things, and an arm naming which one keeps
-- Parun.Engine.Replacement.readsApplier and Parun.Engine.Resolve.Slots.replacementRowReads
-- able to classify a row without running it.
data DrawRewrite
  = -- | CR 614.1a: Words of Worship's "you gain 5 life instead".
    --
    -- The gainer is the player the EVENT names -- the one who would have drawn --
    -- and not the row's controller, whom CR 109.5 would make "you". The two are
    -- one seat on the producer in the pool, whose clause reads "the next time YOU
    -- would draw a card" and so writes Parun.Types.DrawR's `whose` as Related You.
    -- Reading the event is what keeps Parun.Engine.Replacement.readsApplier
    -- answering False for this rewrite; a printing whose two halves named
    -- different seats would have to revisit that.
    GainLife Natural.Natural
  | -- | CR 400.11c: Ring of Ma'rûf's "instead put a card you own from outside the
    -- game into your hand".
    --
    -- The player is the one the EVENT names, GainLife's seat above and for its
    -- reason -- every producer's Parun.Types.DrawR writes `whose` as Related You, so
    -- the two are one seat on it.
    FromOutsideTheGame FromOutsideTheGame.FromOutsideTheGame
  | -- | CR 702.52a: dredge N -- "you may instead mill N cards and return this
    -- card from your graveyard to your hand".
    --
    -- The card returned is the row's own SOURCE, so the arm carries only the
    -- count: rule 702.52a says "this card", and the row is minted onto the card
    -- in the graveyard (Parun.Engine.Keyword.graveyardReplacementsOf).
    --
    -- The miller is the player the EVENT names, GainLife's seat above and for
    -- its reason.
    --
    -- Rule 702.52a's "as long as you have at least N cards in your library" is
    -- asked by Parun.Engine.Replacement.applies rather than written here, which
    -- is also rule 702.52b: a row that cannot mill N is not offered at all, so
    -- CR 616.1's choice never sees it.
    Dredge Natural.Natural
  | -- | CR 614.10 / 614.6: Plagiarize's "that player skips that draw and you draw
    -- a card" -- the draw stands, made by the row's controller instead.
    YouDraw
  | -- | CR 614.6 / 101.4: Zur's Weirding's "they reveal it instead. Then any
    -- other player may pay N life. If a player does, put that card into its
    -- owner's graveyard. Otherwise, that player draws a card."
    OthersMayPayLife Natural.Natural
  | -- | CR 614.6 / 104.3e: Forbidden Crypt's graveyard card to hand, or the game lost.
    FromGraveyardOrLose
  | -- | CR 614.1a / 701.20a: Abundance's "you may instead choose land or nonland
    -- and reveal cards from the top of your library until you reveal a card of
    -- the chosen kind", that card to hand and the rest to the bottom in any
    -- order.
    RevealUntilChosenKind
  | -- | CR 614.1a / 614.5: Alhammarret's Archive's "draw two cards instead",
    -- each a new draw this row does not apply to.
    DrawInstead Natural.Natural
  | -- | CR 614.1a / 701.9a / 701.17a: Chains of Mephistopheles' "discards a card
    -- instead. If the player discards a card this way, they draw a card. If the
    -- player doesn't discard a card this way, they mill a card."
    DiscardThenDrawOrMill
  deriving (Eq, Ord, Show)
