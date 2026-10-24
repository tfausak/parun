module Parun.Codec.LookAtSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.LookAt as LookAt
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LookAt as LookAt
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TopOfLibrary as TopOfLibrary

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LookAt" $ do
  -- Into the Wilds' "look at the top card of your library".
  Spec.it s "MkLookAt" $
    Common.assertCodec
      s
      LookAt.codec
      ( LookAt.MkLookAt
          (ObjectRef.TopOfLibrary (TopOfLibrary.MkTopOfLibrary (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 1)))
          (SlotName.MkSlotName (Text.pack "looked"))
          (PlayerRef.Relative PlayerRelation.You)
      )
      " {\"ref\":{\"type\":\"TopOfLibrary\",\"value\":{\"count\":{\"type\":\"Literal\",\"value\":1},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}},\"slot\":\"looked\"} "
  -- A non-default looker is written out; nothing in the pool has one yet.
  Spec.it s "MkLookAt, a named looker" $
    Common.assertCodec
      s
      LookAt.codec
      ( LookAt.MkLookAt
          (ObjectRef.TopOfLibrary (TopOfLibrary.MkTopOfLibrary (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 1)))
          (SlotName.MkSlotName (Text.pack "looked"))
          (PlayerRef.Relative PlayerRelation.Opponent)
      )
      " {\"looker\":{\"type\":\"Relative\",\"value\":{\"type\":\"Opponent\"}},\"ref\":{\"type\":\"TopOfLibrary\",\"value\":{\"count\":{\"type\":\"Literal\",\"value\":1},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}},\"slot\":\"looked\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LookAt.codec
