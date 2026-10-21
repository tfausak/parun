{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ArrangedArrival where

import qualified Pawl.Codec.LibraryPosition as LibraryPosition
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ArrangedArrival as ArrangedArrival
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation

-- | @chooser@ defaults to "you", Pawl.Codec.ArrangeInLibrary's reading of a
-- printed "in any order" that names nobody (CR 608.2c).
codec :: Codec.Codec ArrangedArrival.ArrangedArrival
codec = Fields.object $ do
  position <- Fields.required "position" LibraryPosition.codec ArrangedArrival.position
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec ArrangedArrival.chooser
  pure
    ArrangedArrival.MkArrangedArrival
      { ArrangedArrival.position = position,
        ArrangedArrival.chooser = chooser
      }
