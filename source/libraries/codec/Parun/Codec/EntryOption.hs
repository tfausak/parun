{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EntryOption where

import qualified Data.Set as Set
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EntryOption as EntryOption

-- | 'power' and 'toughness' stay REQUIRED (R5 of the omit-defaults design): a
-- token whose printed characteristics are 0/0 is a legal EntryOption, so an
-- absent power must not read as 0 when it means the file forgot to state one.
codec :: Codec.Codec EntryOption.EntryOption
codec = Fields.object $ do
  power <- Fields.required "power" Common.integer EntryOption.power
  toughness <- Fields.required "toughness" Common.integer EntryOption.toughness
  keywords <- Fields.defaulted "keywords" Set.empty (Common.set Keyword.codec) EntryOption.keywords
  subtypes <- Fields.defaulted "subtypes" Set.empty (Common.set Subtype.codec) EntryOption.subtypes
  pure
    EntryOption.MkEntryOption
      { EntryOption.power = power,
        EntryOption.toughness = toughness,
        EntryOption.keywords = keywords,
        EntryOption.subtypes = subtypes
      }
