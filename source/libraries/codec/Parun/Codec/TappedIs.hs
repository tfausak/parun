{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TappedIs where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.Codec.TapState as TapState
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TappedIs as TappedIs

codec :: Codec.Codec TappedIs.TappedIs
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec TappedIs.object
  tapped <- Fields.required "tapped" TapState.flag TappedIs.tapped
  pure TappedIs.MkTappedIs {TappedIs.object = object, TappedIs.tapped = tapped}
