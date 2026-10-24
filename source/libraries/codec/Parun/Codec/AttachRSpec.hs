module Parun.Codec.AttachRSpec where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.AttachR as AttachR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AsCopy as AsCopy
import qualified Parun.Types.AttachR as AttachR
import qualified Parun.Types.AttachRewrite as AttachRewrite
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CopyDomain as CopyDomain
import qualified Parun.Types.CopyRecipient as CopyRecipient
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachR" $ do
  -- Dinosaur Headdress's "as this Equipment becomes attached to a creature,
  -- choose an exiled creature card used to craft this Equipment".
  Spec.it s "MkAttachR (Dinosaur Headdress)" $
    Common.assertCodec
      s
      (AttachR.codec Common.text Common.text)
      ( AttachR.MkAttachR
          { AttachR.matching = Filter.IsSource,
            AttachR.rewrite = AttachRewrite.AsCopy (AsCopy.MkAsCopy (Filter.HasCardType CardType.Creature) [] False Seq.empty (CopyDomain.InPile ExiledPile.CraftMaterials) Nothing CopyRecipient.ItsHost False)
          }
      )
      " {\"matching\":{\"type\":\"IsSource\"},\"rewrite\":{\"type\":\"AsCopy\",\"value\":{\"eligible\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"among\":{\"type\":\"InPile\",\"value\":{\"type\":\"CraftMaterials\"}},\"recipient\":{\"type\":\"ItsHost\"},\"optional\":false}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (AttachR.codec Common.text Common.text)
