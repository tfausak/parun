{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EnteringTogether where

import qualified Data.Sequence as Seq
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EnteringTogether as EnteringTogether

-- | Both fields defaulted to empty, so a batch nothing has entered yet is `{}`.
codec :: Codec.Codec EnteringTogether.EnteringTogether
codec = Fields.object $ do
  arrivals <- Fields.defaulted "arrivals" Seq.empty (Common.seq ObjectId.codec) EnteringTogether.arrivals
  minted <- Fields.defaulted "minted" Seq.empty (Common.seq ObjectId.codec) EnteringTogether.minted
  pure
    EnteringTogether.MkEnteringTogether
      { EnteringTogether.arrivals = arrivals,
        EnteringTogether.minted = minted
      }
