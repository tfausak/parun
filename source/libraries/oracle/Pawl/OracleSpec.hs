-- Covers Pawl.Oracle on hand-built cards. Pawl.IngestSpec checks it against the
-- pool and the keyword codec.
module Pawl.OracleSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Oracle as Oracle
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Layout as Layout
import qualified Pawl.Types.TypeLine as TypeLine

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Oracle" $ do
  Spec.it s "normalise drops reminder text and splits a keyword line" $ do
    Spec.assertEq s (fmap Text.pack ["flying", "trample", "vigilance"]) (Oracle.normalise (Text.pack "Flying, vigilance\nTrample (This creature can deal excess combat damage.)"))
    Spec.assertEq s [] (Oracle.normalise (Text.pack "({T}: Add {G}.)"))
    Spec.assertEq s (fmap Text.pack ["haste", "horsemanship"]) (Oracle.normalise (Text.pack "Haste; horsemanship (This creature can't be blocked except by creatures with horsemanship.)"))

  Spec.it s "render prints one keyword per line, and nothing for a vanilla face" $ do
    Spec.assertEq s (Just (Text.pack "Flying\nVigilance")) (Oracle.render (card Layout.Normal [[Keyword.Flying, Keyword.Vigilance]]))
    Spec.assertEq s (Just Text.empty) (Oracle.render (card Layout.Normal [[]]))

  Spec.it s "render answers only for a single normal face" $ do
    Spec.assertEq s Nothing (Oracle.render (card Layout.Normal [[Keyword.Flying], [Keyword.Flying]]))
    Spec.assertEq s Nothing (Oracle.render (card Layout.Split [[Keyword.Flying]]))

-- A card of the given layout whose faces carry the given keywords and nothing
-- else.
card :: Layout.Layout -> [[Keyword.Keyword]] -> Card.Card
card layout keywords =
  Card.MkCard
    { Card.layout = layout,
      Card.faces = NonEmpty.fromList (fmap face keywords)
    }
  where
    face ks = Oracle.bare (CardName.MkCardName (Text.pack "X")) Nothing Nothing Set.empty (TypeLine.MkTypeLine Set.empty Set.empty Set.empty) Nothing Nothing (Map.fromList (fmap (\k -> (k, 1)) ks))
