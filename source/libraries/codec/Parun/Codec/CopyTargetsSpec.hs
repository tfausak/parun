module Parun.Codec.CopyTargetsSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Codec.CopyTargets as CopyTargets
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CopyTargets as CopyTargets
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CopyTargets" $ do
  Spec.it s "Copied" $
    Common.assertCodec s CopyTargets.codec CopyTargets.Copied " {\"type\":\"Copied\"} "
  Spec.it s "ChosenByController" $
    Common.assertCodec s CopyTargets.codec CopyTargets.ChosenByController " {\"type\":\"ChosenByController\"} "
  Spec.it s "ForEach" $
    Common.assertCodec
      s
      CopyTargets.codec
      (CopyTargets.ForEach (ObjectRef.EachMatching (Filter.HeldBy Holder.Controller PlayerRelation.You) NonEmpty.:| [ObjectRef.EachPlayer]))
      " {\"type\":\"ForEach\",\"value\":[{\"type\":\"EachMatching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}},{\"type\":\"EachPlayer\"}]} "
  Spec.it s "Stated" $
    Common.assertCodec
      s
      CopyTargets.codec
      (CopyTargets.Stated (ObjectRef.EachMatching Filter.IsSource))
      " {\"type\":\"Stated\",\"value\":{\"type\":\"EachMatching\",\"value\":{\"type\":\"IsSource\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CopyTargets.codec
