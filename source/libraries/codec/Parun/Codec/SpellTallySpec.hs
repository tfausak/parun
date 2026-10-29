module Parun.Codec.SpellTallySpec where

import qualified Parun.Codec.SpellTally as SpellTally
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SpellTally as SpellTally
import qualified Parun.Types.WhichTurn as WhichTurn

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SpellTally" $ do
  Spec.it s "this turn omits the turn" $
    Common.assertCodec
      s
      SpellTally.codec
      (SpellTally.MkSpellTally {SpellTally.player = PlayerRef.Candidate, SpellTally.turn = WhichTurn.ThisTurn})
      " {\"player\":{\"type\":\"Candidate\"}} "
  Spec.it s "last turn" $
    Common.assertCodec
      s
      SpellTally.codec
      (SpellTally.MkSpellTally {SpellTally.player = PlayerRef.Candidate, SpellTally.turn = WhichTurn.LastTurn})
      " {\"player\":{\"type\":\"Candidate\"},\"turn\":{\"type\":\"LastTurn\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SpellTally.codec
