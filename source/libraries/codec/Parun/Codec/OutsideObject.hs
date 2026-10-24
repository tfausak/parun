{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.OutsideObject where

import qualified Parun.Codec.ComponentCard as ComponentCard
import qualified Parun.Codec.Facing as Facing
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Facing as Facing.Type
import qualified Parun.Types.OutsideObject as OutsideObject

-- | A bare object keyed by the record's field names, mirroring
-- Parun.Codec.Amass's shape.
codec :: Codec.Codec OutsideObject.OutsideObject
codec = Fields.object $ do
  owner <- Fields.required "owner" PlayerId.codec OutsideObject.owner
  printing <- Fields.required "printing" PrintingId.codec OutsideObject.printing
  facing <- Fields.defaulted "facing" Facing.Type.FaceUp Facing.codec OutsideObject.facing
  cards <- Fields.required "cards" (Common.nonEmpty ComponentCard.codec) OutsideObject.cards
  pure
    OutsideObject.MkOutsideObject
      { OutsideObject.owner = owner,
        OutsideObject.printing = printing,
        OutsideObject.facing = facing,
        OutsideObject.cards = cards
      }
