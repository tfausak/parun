{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Binding where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.ModeIndex as ModeIndex
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.Codec.StickerRef as StickerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Binding as Binding
import qualified Parun.Types.SlotName as SlotName

-- | Runtime-only, never in card JSON: the codec must stay total over the
-- transitive closure of what the game state carries.
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec Binding.Binding
codec = Fields.object $ do
  targets <- Fields.defaulted "targets" Nothing (Common.maybe (Common.set Recipient.codec)) Binding.targets
  amount <- Fields.defaulted "amount" Nothing (Common.maybe Common.natural) Binding.amount
  modes <- Fields.defaulted "modes" Nothing (Common.maybe (Common.seq ModeIndex.codec)) Binding.modes
  copy <- Fields.defaulted "copy" Nothing (Common.maybe ProjectedCharacteristics.codec) Binding.copy
  objects <- Fields.defaulted "objects" Nothing (Common.maybe (Common.seq ObjectId.codec)) Binding.objects
  sticker <- Fields.defaulted "sticker" Nothing (Common.maybe StickerRef.codec) Binding.sticker
  votes <- Fields.defaulted "votes" Nothing (Common.maybe (Common.naturalMap PlayerId.codec Common.natural)) Binding.votes
  division <- Fields.defaulted "division" Nothing (Common.maybe (Common.multiset Recipient.codec)) Binding.division
  pure
    Binding.MkBinding
      { Binding.targets = targets,
        Binding.amount = amount,
        Binding.modes = modes,
        Binding.copy = copy,
        Binding.objects = objects,
        Binding.sticker = sticker,
        Binding.votes = votes,
        Binding.division = division
      }

-- | A name-keyed map as a JSON OBJECT keyed by the slot name.
codecMap :: Codec.Codec (Map.Map SlotName.SlotName Binding.Binding)
codecMap = Common.textMap SlotName.unwrap (Right . SlotName.MkSlotName) codec
