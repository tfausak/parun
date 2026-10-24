{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.NamesAre where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.NamesAre as NamesAre

codec :: Codec.Codec NamesAre.NamesAre
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec NamesAre.object
  names <- Fields.required "names" (Common.set CardName.codec) NamesAre.names
  pure NamesAre.MkNamesAre {NamesAre.object = object, NamesAre.names = names}
