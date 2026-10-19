module Pawl.Codec.AttachRewriteSpec where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.AttachRewrite as AttachRewrite
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AsCopy as AsCopy
import qualified Pawl.Types.AttachRewrite as AttachRewrite
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.CopyDomain as CopyDomain
import qualified Pawl.Types.CopyRecipient as CopyRecipient
import qualified Pawl.Types.ExiledPile as ExiledPile
import qualified Pawl.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.AttachRewrite" $ do
  Spec.it s "AsCopy (Dinosaur Headdress)" $
    Common.assertCodec
      s
      (AttachRewrite.codec Common.text Common.text)
      (AttachRewrite.AsCopy (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty (CopyDomain.InPile ExiledPile.CraftMaterials) Nothing CopyRecipient.ItsHost False))
      " {\"type\":\"AsCopy\",\"value\":{\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"among\":{\"type\":\"InPile\",\"value\":{\"type\":\"CraftMaterials\"}},\"recipient\":{\"type\":\"ItsHost\"},\"optional\":false}} "
  Spec.it s "ChooseColors (Sanctuary Blade)" $
    Common.assertCodec s (AttachRewrite.codec Common.text Common.text) (AttachRewrite.ChooseColors 1) " {\"type\":\"ChooseColors\",\"value\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (AttachRewrite.codec Common.text Common.text)
