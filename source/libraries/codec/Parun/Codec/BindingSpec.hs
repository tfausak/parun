module Parun.Codec.BindingSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.Binding as Binding
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Binding as Binding
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.StickerKind as StickerKind
import qualified Parun.Types.StickerRef as StickerRef

-- | MkBinding at its all-Nothing unit (Binding.empty).
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Binding" $ do
  Spec.it s "MkBinding, the empty binding" $
    Common.assertCodec
      s
      Binding.codec
      Binding.empty
      " {} "
  -- A codec totality check, not a claim about a reachable game state: no real
  -- slot carries all eight fields at once. The stand-in snapshot is needed
  -- because this sublibrary cannot reach the registry or Projection.project.
  Spec.it s "MkBinding, every field populated" $
    Common.assertCodec
      s
      Binding.codec
      ( Binding.MkBinding
          { Binding.targets = Just (Set.singleton (Recipient.ToPlayer (PlayerId.MkPlayerId 0))),
            Binding.amount = Just 3,
            Binding.modes = Just (Seq.fromList [ModeIndex.MkModeIndex 0, ModeIndex.MkModeIndex 2, ModeIndex.MkModeIndex 2]),
            Binding.copy = Just ProjectedCharacteristicsSpec.testCharacteristics,
            Binding.objects = Just (Seq.fromList [ObjectId.MkObjectId 7, ObjectId.MkObjectId 4]),
            Binding.sticker = Just (StickerRef.MkStickerRef (PlayerId.MkPlayerId 0) 2 StickerKind.Name 1),
            Binding.votes = Just (Map.fromList [(PlayerId.MkPlayerId 0, 2), (PlayerId.MkPlayerId 1, 0)]),
            Binding.division = Just (Map.fromList [(Recipient.ToPlayer (PlayerId.MkPlayerId 0), 3), (Recipient.ToCreature (ObjectId.MkObjectId 7), 1)])
          }
      )
      ( "{\"targets\":[{\"type\":\"ToPlayer\",\"value\":0}],"
          <> "\"amount\":3,\"modes\":[0,2,2],\"copy\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"objects\":[7,4],\"sticker\":{\"owner\":0,\"sheet\":2,\"kind\":{\"type\":\"Name\"},\"index\":1},\"votes\":{\"0\":2,\"1\":0},"
          <> "\"division\":[{\"key\":{\"type\":\"ToCreature\",\"value\":7},\"value\":1},{\"key\":{\"type\":\"ToPlayer\",\"value\":0},\"value\":3}]}"
      )
  -- A name-keyed map is a JSON OBJECT keyed by the slot name, written in
  -- ascending key order. The two entries are inserted in DESCENDING slot-name
  -- order, so a trip that emitted the map's incidental traversal order rather
  -- than Map.toAscList fails this case -- Parun.Json.Object is a list of pairs,
  -- so the order written is the order rendered.
  Spec.it s "toJsonMap/fromJsonMap sorts by slot name" $
    Common.assertJsonCodec
      s
      (Codec.encode Binding.codecMap)
      (Codec.decode Binding.codecMap)
      ( Map.fromList
          [ (SlotName.MkSlotName (Text.pack "z-slot"), Binding.empty {Binding.amount = Just 1}),
            (SlotName.MkSlotName (Text.pack "a-slot"), Binding.empty {Binding.amount = Just 2})
          ]
      )
      ( "{\"a-slot\":{\"amount\":2},"
          <> "\"z-slot\":{\"amount\":1}}"
      )
