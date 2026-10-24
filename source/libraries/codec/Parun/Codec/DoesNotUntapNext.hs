{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DoesNotUntapNext where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DoesNotUntapNext as DoesNotUntapNext

-- | A bare object keyed by the record's field names, `steps` defaulting to the
-- one step most cards print. The tag that picks it is written by
-- Parun.Codec.Effect's DoesNotUntapNext arm.
codec :: Codec.Codec DoesNotUntapNext.DoesNotUntapNext
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec DoesNotUntapNext.ref
  steps <- Fields.defaulted "steps" 1 Common.natural DoesNotUntapNext.steps
  pure
    DoesNotUntapNext.MkDoesNotUntapNext
      { DoesNotUntapNext.ref = ref,
        DoesNotUntapNext.steps = steps
      }
