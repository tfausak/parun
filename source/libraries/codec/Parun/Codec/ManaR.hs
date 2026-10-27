{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ManaR where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ManaR as ManaR

codec :: Codec.Codec ManaR.ManaR
codec = Fields.object $ do
  matching <- Fields.required "matching" (Filter.codec Keyword.codec) ManaR.matching
  produces <- Fields.required "produces" ManaType.codec ManaR.produces
  pure
    ManaR.MkManaR
      { ManaR.matching = matching,
        ManaR.produces = produces
      }
