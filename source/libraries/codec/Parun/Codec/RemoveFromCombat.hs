{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RemoveFromCombat where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Unblocking as Unblocking
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RemoveFromCombat as RemoveFromCombat
import qualified Parun.Types.Unblocking as Unblocking.Type

codec :: Codec.Codec RemoveFromCombat.RemoveFromCombat
codec = Fields.object $ do
  removed <- Fields.required "removed" ObjectRef.codec RemoveFromCombat.removed
  unblocking <- Fields.defaulted "unblocking" Unblocking.Type.StayBlocked Unblocking.codec RemoveFromCombat.unblocking
  pure
    RemoveFromCombat.MkRemoveFromCombat
      { RemoveFromCombat.removed = removed,
        RemoveFromCombat.unblocking = unblocking
      }
