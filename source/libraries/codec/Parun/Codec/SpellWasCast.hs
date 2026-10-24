{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpellWasCast where

import qualified Data.Set as Set
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpellWasCast as SpellWasCast

-- | A bare object keyed by the record's field names, replacing the positional
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec SpellWasCast.SpellWasCast
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec SpellWasCast.player
  spell <- Fields.required "spell" ObjectId.codec SpellWasCast.spell
  characteristics <- Fields.required "characteristics" ProjectedCharacteristics.codec SpellWasCast.characteristics
  zone <- Fields.defaulted "zone" Nothing (Common.maybe Zone.codec) SpellWasCast.zone
  castUsing <- Fields.defaulted "castUsing" Nothing (Common.maybe Keyword.codec) SpellWasCast.castUsing
  lapsedGrants <- Fields.defaulted "lapsedGrants" Set.empty (Common.set Condition.codec) SpellWasCast.lapsedGrants
  pure
    SpellWasCast.MkSpellWasCast
      { SpellWasCast.player = player,
        SpellWasCast.spell = spell,
        SpellWasCast.characteristics = characteristics,
        SpellWasCast.zone = zone,
        SpellWasCast.castUsing = castUsing,
        SpellWasCast.lapsedGrants = lapsedGrants
      }
