{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Equip where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.EquipTarget as EquipTarget
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Equip as Equip
import qualified Parun.Types.EquipTarget as EquipTarget

-- | A bare object keyed by the record's field names, Parun.Codec.Cycling's shape;
-- @target@ is defaulted, so plain equip writes no key.
-- The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Equip.Equip keyword)
codec keywordCodec = Fields.object $ do
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Equip.cost
  quality <- Fields.required "quality" (Common.maybe (Filter.codec keywordCodec)) Equip.quality
  target <- Fields.defaulted "target" EquipTarget.Creature EquipTarget.codec Equip.target
  pure Equip.MkEquip {Equip.cost = cost, Equip.quality = quality, Equip.target = target}
