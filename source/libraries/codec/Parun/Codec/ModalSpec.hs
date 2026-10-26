module Parun.Codec.ModalSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Modal as Modal
import qualified Parun.Codec.ModeSelection as ModeSelection
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TargetSlot as TargetSlot

-- | The `card` parameter is instantiated at 'Text.Text' throughout.
-- 'Modal.codec' reach it only through the supplied Mode
-- codec, so any type proves the shape.
cardCodec :: Codec.Codec Text.Text
cardCodec = Common.text

-- | And the `ability` parameter likewise: it too is reached only through the
-- codec supplied here, so any type proves the shape.
abilityCodec :: Codec.Codec Text.Text
abilityCodec = Common.text

codec :: Codec.Codec (Modal.Modal Text.Text Text.Text)
codec = Modal.codec cardCodec abilityCodec

toJson :: Modal.Modal Text.Text Text.Text -> Value.Value
toJson = Codec.encode codec

fromJson :: Value.Value -> Either Text.Text (Modal.Modal Text.Text Text.Text)
fromJson = Codec.decode codec

-- One constructor, so three cases: a populated payload in CR 700.2's non-modal
-- shape, the `selection` field defaulted (the only omissible one -- `modes` is
-- required and non-empty by invariant), and the empty-modes decode failure.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Modal" $ do
  Spec.it s "MkModal, rule 702.6a's equip payload" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( Modal.MkModal
          ( Seq.singleton
              ( Mode.MkMode
                  (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Attach (SlotName.MkSlotName (Text.pack "target"))))))
                  (Map.singleton (SlotName.MkSlotName (Text.pack "target")) (TargetSlot.required Pool.Creatures (Just (Filter.HeldBy Holder.Controller PlayerRelation.You))))
              )
          )
          (ModeSelection.ChooseExactly 1)
      )
      " {\"modes\":[{\"clauses\":[{\"effects\":[{\"type\":\"Attach\",\"value\":\"target\"}]}],\"targetSlots\":{\"target\":{\"pool\":{\"type\":\"Creatures\"},\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}}}}]} "
  Spec.it s "omits a ChooseExactly 1 selection" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      (Modal.MkModal (Seq.singleton (Mode.MkMode Seq.empty Map.empty)) Modal.defaultSelection)
      " {\"modes\":[{}]} "
  -- CR 700.2's non-modal payload is a single Mode: a modal PAYLOAD has at
  -- least one mode by invariant, so an empty `modes` array is a decode
  -- failure, not a spell that offers no choices.
  Spec.it s "empty modal is a decode error" $
    Spec.assertBool
      s
      ( either
          (const True)
          (const False)
          (fromJson (Value.object [Value.pair "modes" (Value.array []), Value.pair "selection" (Codec.encode ModeSelection.codec (ModeSelection.ChooseExactly 1))]))
      )
      "left"
