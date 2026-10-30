{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChangeTargets where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChangeTargets as ChangeTargets

-- | The stack objects are required; `onto` defaults to absent, CR 115.7a's
-- free change (Deflection).
codec :: Codec.Codec ChangeTargets.ChangeTargets
codec = Fields.object $ do
  objects <- Fields.required "objects" ObjectRef.codec ChangeTargets.objects
  onto <- Fields.defaulted "onto" Nothing (Common.maybe ObjectRef.codec) ChangeTargets.onto
  pure
    ChangeTargets.MkChangeTargets
      { ChangeTargets.objects = objects,
        ChangeTargets.onto = onto
      }
