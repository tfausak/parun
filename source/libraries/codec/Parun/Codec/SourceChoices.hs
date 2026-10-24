{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SourceChoices where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.Color as Color
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SourceChoices as SourceChoices

codec :: Codec.Codec SourceChoices.SourceChoices
codec = Fields.object $ do
  names <- Fields.defaulted "names" Map.empty (Common.naturalMap PlayerId.codec CardName.codec) SourceChoices.names
  colors <- Fields.defaulted "colors" Set.empty (Common.set Color.codec) SourceChoices.colors
  subtype <- Fields.defaulted "subtype" Nothing (Common.maybe Subtype.codec) SourceChoices.subtype
  pure
    SourceChoices.MkSourceChoices
      { SourceChoices.names = names,
        SourceChoices.colors = colors,
        SourceChoices.subtype = subtype
      }
