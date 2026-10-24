{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlanarDieRolled where

import qualified Parun.Codec.PlanarDieFace as PlanarDieFace
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlanarDieRolled as PlanarDieRolled

codec :: Codec.Codec PlanarDieRolled.PlanarDieRolled
codec = Fields.object $ do
  roller <- Fields.required "roller" PlayerId.codec PlanarDieRolled.roller
  face <- Fields.required "face" PlanarDieFace.codec PlanarDieRolled.face
  pure PlanarDieRolled.MkPlanarDieRolled {PlanarDieRolled.roller = roller, PlanarDieRolled.face = face}
