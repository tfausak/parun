module Parun.Codec.AttachRestrictionSpec where

import qualified Parun.Codec.AttachRestriction as AttachRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AttachRestriction as AttachRestriction
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachRestriction" $ do
  -- Consecrate Land's second clause (CR 303.4 / CR 101.2), which is also the one
  -- shape in the pool that pairs Affected.Attached with a filter naming the
  -- source -- so this round-trips "other Auras" in the position a card actually
  -- writes it, not only as a bare filter.
  Spec.it s "MkAttachRestriction" $
    Common.assertCodec
      s
      AttachRestriction.codec
      ( AttachRestriction.MkAttachRestriction
          { AttachRestriction.affected = Affected.Attached,
            AttachRestriction.attachers =
              Filter.And
                [ Filter.HasSubtype Subtype.Aura,
                  Filter.Not Filter.IsSource
                ]
          }
      )
      " {\"affected\":{\"type\":\"Attached\"},\"attachers\":{\"type\":\"And\",\"value\":[{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Aura\"}},{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachRestriction.codec
