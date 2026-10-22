-- CR 612.2's word families over Pawl.Types.TextWord: which family a word
-- belongs to, which pairs a text change may swap, and what a list of swaps
-- leaves a word as. A word's family is the rulebook's (CR 105.1, CR 205.3), so
-- casing on one is the same kind of act as casing on a Phase.
module Pawl.Engine.TextWord where

import qualified Data.List as List
import qualified Data.Set as Set
import qualified Pawl.Engine.Subtype as Subtype
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Subtype as Subtype.Type
import qualified Pawl.Types.TextWord as TextWord
import qualified Pawl.Types.WordFamily as WordFamily

-- | CR 612.2's question -- is this word one of the family's? -- where the
-- family is named by a card's text rather than fixed by a constructor.
--
-- BasicLandType answers with the whole of CR 205.3i, not CR 305.6's five: the
-- narrowing to basics is on what a player may CHOOSE (`swappable`), while the
-- family a swap may reach is the land types.
inFamily :: WordFamily.WordFamily -> TextWord.TextWord -> Bool
inFamily family word = case word of
  TextWord.ColorWord _ -> family == WordFamily.Color
  TextWord.SubtypeWord s -> case family of
    WordFamily.BasicLandType -> Subtype.isLandType s
    WordFamily.CreatureType -> Subtype.isCreatureType s
    -- CR 205.3h, read off correlatedCardTypes' list rather than restated. A
    -- regression fence: its one reader is Rewrite.swapWordIn over a
    -- ChangeText's forbidden set, and Synthetic Enchanted Evolution forbids
    -- nothing.
    WordFamily.EnchantmentType -> Set.member CardType.Enchantment (Subtype.correlatedCardTypes s)
    WordFamily.Color -> False

-- | CR 612.2: whether a text change naming these families may replace @from@
-- with @to@ -- both words one family's, BasicLandType narrowed to CR 305.6's
-- five, @to@ outside the card's @forbidden@, and, per Magical Hack's, Artificial
-- Evolution's and Sleight of Mind's rulings, two different words. Neither word
-- need appear on the target (the same rulings).
swappable :: Set.Set WordFamily.WordFamily -> Set.Set TextWord.TextWord -> (TextWord.TextWord, TextWord.TextWord) -> Bool
swappable families forbidden (from, to) =
  from /= to
    && any (\family -> choosable family from && choosable family to) families
    && Set.notMember to forbidden

-- `swappable`'s family test, apart from the pair.
choosable :: WordFamily.WordFamily -> TextWord.TextWord -> Bool
choosable family word = case (family, word) of
  (WordFamily.BasicLandType, TextWord.SubtypeWord s) -> Subtype.isBasicLandType s
  _ -> inFamily family word

-- | The first `swappable` pair in TextWord's order: what a swap prompt's
-- answer falls back to when it is not swappable, the filter-not-trust posture
-- of Pawl.Engine.Game.chooseAmong. Nothing only when the card forbids all but
-- one word of every family it names.
firstSwap :: Set.Set WordFamily.WordFamily -> Set.Set TextWord.TextWord -> Maybe (TextWord.TextWord, TextWord.TextWord)
firstSwap families forbidden =
  let offered = filter (\word -> any (`choosable` word) families) everyWord
   in List.find (swappable families forbidden) [(from, to) | from <- offered, to <- offered]

-- Every word of every family, colours first.
everyWord :: [TextWord.TextWord]
everyWord = fmap TextWord.ColorWord [minBound ..] <> fmap TextWord.SubtypeWord [minBound ..]

-- | The subtype a table of swaps leaves this one as: an exact lookup, so the
-- family a word is used AS is the family it belongs to (CR 612.2).
subtypeAfter :: [(TextWord.TextWord, TextWord.TextWord)] -> Subtype.Type.Subtype -> Subtype.Type.Subtype
subtypeAfter pairs s = case lookup (TextWord.SubtypeWord s) pairs of
  Just (TextWord.SubtypeWord t) -> t
  _ -> s

-- | `subtypeAfter` for a colour word used as a colour word (CR 612.2).
colorAfter :: [(TextWord.TextWord, TextWord.TextWord)] -> Color.Color -> Color.Color
colorAfter pairs c = case lookup (TextWord.ColorWord c) pairs of
  Just (TextWord.ColorWord d) -> d
  _ -> c
