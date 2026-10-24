{-# LANGUAGE ApplicativeDo #-}

-- | Where the card knot is tied: @Parun.Codec.Face@ carries the printed
-- characteristics and is parametric in the card codec, and this module passes
-- its own back in.
--
-- Every @Parun.Types.*@ module stays JSON-free. Casing on an effect's identity
-- anywhere under @Parun.Codec@ is open-half machinery, not the rules core.
module Parun.Codec.Card where

import qualified Parun.Codec.Face as Face
import qualified Parun.Codec.Layout as Layout
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Layout as Layout

-- | RECURSIVE: 'codec' names itself, which is the knot. It terminates for
-- Parun.Codec.Effect's reason -- 'Fields.object' reaches WHNF as a
-- 'Codec.MkCodec' without forcing its field list, and 'Define.define' registers
-- this type's name before running the schema body, so the re-entry emits a
-- @$ref@.
--
-- The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec Card.Card
codec = Fields.object (fields id)

-- | A card's keys, read off whatever record holds it -- Parun.Codec.Printing
-- writes them beside a printing's own.
fields :: (o -> Card.Card) -> Fields.Fields o Card.Card
fields project = do
  -- Common.nonEmpty rejects an empty array, which is where the at-least-one-face
  -- invariant is enforced -- the UnsafeX posture Parun.Types.Modal's modes field
  -- documents.
  faces <- Fields.required "faces" (Common.nonEmpty (Face.codec codec)) (Card.faces . project)
  -- CR 709-722: Normal is the absence of a card saying otherwise, so it is a
  -- default rather than a required key and most single-face files say nothing
  -- about it.
  layout <- Fields.defaulted "layout" Layout.Normal Layout.codec (Card.layout . project)
  pure Card.MkCard {Card.layout = layout, Card.faces = faces}
