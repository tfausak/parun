{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ArrangedArrival where

import qualified Parun.Codec.LibraryPosition as LibraryPosition
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ArrangedArrival as ArrangedArrival
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | @chooser@ defaults to "you", Parun.Codec.ArrangeInLibrary's reading of a
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
