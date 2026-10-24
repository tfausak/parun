module Parun.Codec.AttackersAreSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Parun.Codec.AttackersAre as AttackersAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackersAre as AttackersAre.Type
import qualified Parun.Types.CardName as CardName.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackersAre" $ do
  Spec.it s "keyed by attacker" $
    Common.assertCodec
      s
      AttackersAre.codec
      ( AttackersAre.Type.MkAttackersAre
          ( Map.fromList
              [ (labelled "bear", labelled "bob"),
                (Reference.Type.Printed (CardName.Type.MkCardName (Text.pack "Goblin Piker")) 2, Reference.Type.Printed (CardName.Type.MkCardName (Text.pack "Jace Beleren")) 1)
              ]
          )
      )
      " {\"attackers\":{\"$bear\":\"$bob\",\"Goblin Piker#2\":\"Jace Beleren\"}} "
  Spec.it s "nothing attacking" $
    Common.assertCodec s AttackersAre.codec (AttackersAre.Type.MkAttackersAre Map.empty) " {\"attackers\":{}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s AttackersAre.codec

labelled :: String -> Reference.Type.Reference
labelled = Reference.Type.Labelled . Label.Type.MkLabel . Text.pack
