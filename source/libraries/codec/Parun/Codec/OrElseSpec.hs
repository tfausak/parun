module Parun.Codec.OrElseSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.OrElse as OrElse
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.OrElse as OrElse
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

toJson :: OrElse.OrElse -> Value.Value
toJson = Codec.encode OrElse.codec

fromJson :: Value.Value -> Either Text.Text OrElse.OrElse
fromJson = Codec.decode OrElse.codec

-- One constructor, so three cases: the unmarked chooser, which is elided, a card
-- that names somebody else, and CR 701.55a's villainous flag, elided the same
-- way.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.OrElse" $ do
  Spec.it s "a branch announced by the resolving controller writes only its sibling" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (OrElse.MkOrElse (ClauseIndex.MkClauseIndex 1) (PlayerRef.Relative PlayerRelation.You) False)
      " {\"sibling\":1} "
  Spec.it s "and one the whole table announces writes the chooser" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (OrElse.MkOrElse (ClauseIndex.MkClauseIndex 0) (PlayerRef.Relative PlayerRelation.AnyPlayer) False)
      " {\"sibling\":0,\"chooser\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}} "
  Spec.it s "CR 701.55a a villainous choice writes the flag" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (OrElse.MkOrElse (ClauseIndex.MkClauseIndex 1) (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))) True)
      " {\"sibling\":1,\"chooser\":{\"type\":\"InSlot\",\"value\":\"target\"},\"villainous\":true} "
