module Pawl.Codec.AbilityView where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.AbilityView as AbilityView

-- | A bare object keyed by the record's field name; `source` is null when the
-- seat may not know where the ability came from.
codec :: Codec.Codec AbilityView.AbilityView
codec = Fields.object (AbilityView.MkAbilityView <$> Fields.required "source" (Common.maybe ObjectId.codec) AbilityView.source)
