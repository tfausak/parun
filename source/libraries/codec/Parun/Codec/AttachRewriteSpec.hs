module Parun.Codec.AttachRewriteSpec where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.AttachRewrite as AttachRewrite
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AsCopy as AsCopy
import qualified Parun.Types.AttachRewrite as AttachRewrite
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChosenQuality as ChosenQuality
import qualified Parun.Types.CopyDomain as CopyDomain
import qualified Parun.Types.CopyRecipient as CopyRecipient
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachRewrite" $ do
  Spec.it s "AsCopy (Dinosaur Headdress)" $
    Common.assertCodec
      s
      (AttachRewrite.codec Common.text Common.text)
      (AttachRewrite.AsCopy (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty (CopyDomain.InPile ExiledPile.CraftMaterials) Nothing CopyRecipient.ItsHost False))
      " {\"type\":\"AsCopy\",\"value\":{\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"among\":{\"type\":\"InPile\",\"value\":{\"type\":\"CraftMaterials\"}},\"recipient\":{\"type\":\"ItsHost\"},\"optional\":false}} "
  Spec.it s "ChooseQuality (Sanctuary Blade)" $
    Common.assertCodec s (AttachRewrite.codec Common.text Common.text) (AttachRewrite.ChooseQuality (ChosenQuality.Colors 1)) " {\"type\":\"ChooseQuality\",\"value\":{\"type\":\"Colors\",\"value\":1}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (AttachRewrite.codec Common.text Common.text)
