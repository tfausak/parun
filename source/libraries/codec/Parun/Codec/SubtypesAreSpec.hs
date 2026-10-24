module Parun.Codec.SubtypesAreSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.SubtypesAre as SubtypesAre
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Reference as Reference.Type
import qualified Parun.Types.Subtype as Subtype.Type
import qualified Parun.Types.SubtypesAre as SubtypesAre.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SubtypesAre" $ do
  Spec.it s "an object and its subtypes" $
    Common.assertCodec s SubtypesAre.codec (SubtypesAre.Type.MkSubtypesAre (Reference.Type.Labelled (Label.Type.MkLabel (Text.pack "piker"))) (Set.fromList [Subtype.Type.Elf, Subtype.Type.Warrior])) " {\"object\":\"$piker\",\"subtypes\":[\"Elf\",\"Warrior\"]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s SubtypesAre.codec
