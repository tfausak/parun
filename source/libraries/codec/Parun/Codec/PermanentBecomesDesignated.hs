{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentBecomesDesignated where

import qualified Parun.Codec.Designation as Designation
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be.
codec :: Codec.Codec PermanentBecomesDesignated.PermanentBecomesDesignated
codec = Fields.object $ do
  designation <- Fields.required "designation" Designation.codec PermanentBecomesDesignated.designation
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PermanentBecomesDesignated.filter
  pure
    PermanentBecomesDesignated.MkPermanentBecomesDesignated
      { PermanentBecomesDesignated.designation = designation,
        PermanentBecomesDesignated.filter = filter_
      }
