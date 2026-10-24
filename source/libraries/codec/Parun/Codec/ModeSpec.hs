module Parun.Codec.ModeSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Mode as Mode
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TargetSlot as TargetSlot

-- | The `card` parameter is instantiated at 'Text.Text' throughout.
-- 'Mode.codec' reach it only through the supplied Effect
-- codec, so any type proves the shape.
cardCodec :: Codec.Codec Text.Text
cardCodec = Common.text

-- | And the `ability` parameter likewise: it too is reached only through the
-- codec supplied here, so any type proves the shape.
abilityCodec :: Codec.Codec Text.Text
abilityCodec = Common.text

codec :: Codec.Codec (Mode.Mode Text.Text Text.Text)
codec = Mode.codec cardCodec abilityCodec

toJson :: Mode.Mode Text.Text Text.Text -> Value.Value
toJson = Codec.encode codec

fromJson :: Value.Value -> Either Text.Text (Mode.Mode Text.Text Text.Text)
fromJson = Codec.decode codec

-- One constructor and two fields, so two cases: a populated mode, and the empty
-- one whose every key is omitted. The resolution-time riders belong to
-- Parun.Types.Clause now (CR 608.2e), and Parun.Codec.ClauseSpec covers them.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Mode" $ do
  Spec.it s "MkMode, Bonesplitter's Equip payload" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( Mode.MkMode
          (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Attach (SlotName.MkSlotName (Text.pack "target"))))))
          (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just (Filter.ControlledBy PlayerRelation.You))))
      )
      " {\"clauses\":[{\"effects\":[{\"type\":\"Attach\",\"value\":\"target\"}]}],\"targetSlots\":{\"target\":{\"pool\":{\"type\":\"Creatures\"},\"filter\":{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}}}}} "
  -- A mode with no clauses or targetSlots is what a card that says nothing
  -- extra means, and it round-trips through the empty object.
  Spec.it s "omits every default field" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Mode.MkMode Seq.empty Map.empty)
      " {} "
