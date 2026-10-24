module Parun.Codec.RestrictedCreaturesSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RestrictedCreatures" $ do
  Spec.it s "Named" $
    Common.assertCodec
      s
      (RestrictedCreatures.codec ObjectRef.codec)
      (RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "Matching" $
    Common.assertCodec
      s
      (RestrictedCreatures.codec ObjectRef.codec)
      (RestrictedCreatures.Matching (Filter.HasCardType CardType.Creature))
      " {\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- The other instantiation, which Parun.Types.ActiveAttackProhibition holds: the
  -- same two tags, with the id the ref was read as in place of the ref.
  Spec.it s "Named at an id rather than a ref" $
    Common.assertCodec
      s
      (RestrictedCreatures.codec ObjectId.codec)
      (RestrictedCreatures.Named (ObjectId.MkObjectId 3))
      " {\"type\":\"Named\",\"value\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (RestrictedCreatures.codec ObjectRef.codec)
