{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ArrangeInLibrary where

import qualified Pawl.Codec.ObjectRef as ObjectRef
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ArrangeInLibrary as ArrangeInLibrary
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation

-- | @chooser@ defaults to "you", the reading of every printed "put them back in
-- any order" that names nobody (CR 608.2c).
codec :: Codec.Codec ArrangeInLibrary.ArrangeInLibrary
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec ArrangeInLibrary.ref
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec ArrangeInLibrary.chooser
  pure
    ArrangeInLibrary.MkArrangeInLibrary
      { ArrangeInLibrary.ref = ref,
        ArrangeInLibrary.chooser = chooser
      }
