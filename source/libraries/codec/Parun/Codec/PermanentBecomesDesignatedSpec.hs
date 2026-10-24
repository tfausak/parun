module Parun.Codec.PermanentBecomesDesignatedSpec where

import qualified Parun.Codec.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermanentBecomesDesignated" $ do
  Spec.it s "MkPermanentBecomesDesignated, Renowned over a controlled set" $
    Common.assertCodec
      s
      PermanentBecomesDesignated.codec
      ( PermanentBecomesDesignated.MkPermanentBecomesDesignated
          { PermanentBecomesDesignated.designation = Designation.Renowned,
            PermanentBecomesDesignated.filter = Filter.ControlledBy PlayerRelation.You
          }
      )
      " {\"designation\":{\"type\":\"Renowned\"},\"filter\":{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}}} "
  -- The other designation, over the source itself.
  Spec.it s "MkPermanentBecomesDesignated, Monstrous over the source" $
    Common.assertCodec
      s
      PermanentBecomesDesignated.codec
      ( PermanentBecomesDesignated.MkPermanentBecomesDesignated
          { PermanentBecomesDesignated.designation = Designation.Monstrous,
            PermanentBecomesDesignated.filter = Filter.IsSource
          }
      )
      " {\"designation\":{\"type\":\"Monstrous\"},\"filter\":{\"type\":\"IsSource\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PermanentBecomesDesignated.codec
