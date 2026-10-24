module Parun.Codec.TypesAreSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.TypesAre as TypesAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName.Type
import qualified Parun.Types.CardType as CardType.Type
import qualified Parun.Types.Reference as Reference.Type
import qualified Parun.Types.TypesAre as TypesAre.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TypesAre" $ do
  Spec.it s "card types are bare names" $
    Common.assertCodec
      s
      TypesAre.codec
      (TypesAre.Type.MkTypesAre (Reference.Type.Printed (CardName.Type.MkCardName (Text.pack "Soldier Token")) 1) (Set.fromList [CardType.Type.Creature, CardType.Type.Battle]))
      " {\"object\":\"Soldier Token\",\"types\":[\"Battle\",\"Creature\"]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TypesAre.codec
