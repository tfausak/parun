{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SetOwner where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SetOwner as SetOwner

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec SetOwner.SetOwner
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec SetOwner.player
  ref <- Fields.required "ref" ObjectRef.codec SetOwner.ref
  pure
    SetOwner.MkSetOwner
      { SetOwner.player = player,
        SetOwner.ref = ref
      }
