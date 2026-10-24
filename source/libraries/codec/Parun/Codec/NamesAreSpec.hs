module Parun.Codec.NamesAreSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.NamesAre as NamesAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.NamesAre as NamesAre.Type
import qualified Parun.Types.Reference as Reference.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.NamesAre" $ do
  Spec.it s "an object and its names" $
    Common.assertCodec s NamesAre.codec (NamesAre.Type.MkNamesAre (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "clone"))) (Set.singleton (CardName.Type.MkCardName (Text.pack "Goblin Piker")))) " {\"object\":\"$clone\",\"names\":[\"Goblin Piker\"]} "
  Spec.it s "a nameless object" $
    Common.assertCodec s NamesAre.codec (NamesAre.Type.MkNamesAre (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "clone"))) Set.empty) " {\"object\":\"$clone\",\"names\":[]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s NamesAre.codec
