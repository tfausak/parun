-- Covers Pawl.Engine.Visibility. Its other arms are proven by the scenarios
-- under data/scenarios/visibility; this holds the one no priority point reaches.
module Pawl.VisibilitySpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map as Map
import qualified Data.Text as Text
import qualified Pawl.Engine.Visibility as Visibility
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.Staged as Staged
import qualified Pawl.Types.Visibility as Visibility.Type

spec :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Pawl.Engine.Visibility" $ do
  -- A card CR 121.8 keeps face down in hand exists only mid-cast, which no
  -- scenario check reaches, so the mark is written onto the state directly.
  Spec.it s "CR 121.8 / 708.5 a card kept face down in hand is hidden from its owner" $ do
    built <- S.buildBoardOrFail s registry (S.board (S.hand S.alice [S.aliased "wrath" (S.cardSetup "Thunderous Wrath")] NonEmpty.:| [S.playerSetup S.bob]) S.alice S.precombatMain)
    wrath <- maybe (Spec.assertFailure s "no wrath") pure (Map.lookup (Label.MkLabel (Text.pack "wrath")) (Staged.objects built))
    let gs = Staged.state built
        kept = gs {GameState.keptFaceDown = Just (Map.singleton wrath 0)}
    Spec.assertEqWith s "the control: unmarked, its owner sees it" (Visibility.sees S.alice wrath gs) Visibility.Type.Visible
    Spec.assertEqWith s "marked by CR 121.8, its owner does not" (Visibility.sees S.alice wrath kept) Visibility.Type.Obscured
