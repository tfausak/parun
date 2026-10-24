{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ArrangeInLibrary where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ArrangeInLibrary as ArrangeInLibrary
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

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
