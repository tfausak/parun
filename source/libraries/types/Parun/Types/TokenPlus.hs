module Parun.Types.TokenPlus where

-- | What Parun.Types.TokenR's `plus` puts into a token creation (CR 614.1a): a
-- lot of this card in the SAME creation event, beside the matched tokens or in
-- their place.
--
-- Parametric in @card@ for Parun.Types.TokenR's reason.
data TokenPlus card
  = -- | "those tokens plus a 1/1 white Soldier creature token" (Queen Allenal of
    -- Ruadach): one more token.
    One card
  | -- | "those tokens plus that many 1/1 green Squirrel creature tokens"
    -- (Chatterfang, Squirrel General): one more per token the event creates.
    ThatMany card
  | -- | "that many 5/5 red Dragon creature tokens with flying are created
    -- instead" (Draconic Visitor): the matched tokens' lots become this card's.
    Instead card
  deriving (Eq, Ord, Show)

instance Functor TokenPlus where
  fmap f plus = case plus of
    One card -> One (f card)
    ThatMany card -> ThatMany (f card)
    Instead card -> Instead (f card)

instance Foldable TokenPlus where
  foldr f z plus = case plus of
    One card -> f card z
    ThatMany card -> f card z
    Instead card -> f card z
