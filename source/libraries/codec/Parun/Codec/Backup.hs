{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Backup where

import qualified Data.Set as Set
import qualified Data.Typeable as Typeable
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Backup as Backup

-- | printedAbove defaults to empty, the shape of every backup card that prints
-- backup first. The keyword codec is a PARAMETER; see Parun.Codec.Filter's
-- header.
codec :: (Typeable.Typeable keyword, Ord keyword) => Codec.Codec keyword -> Codec.Codec (Backup.Backup keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural Backup.count
  printedAbove <- Fields.defaulted "printedAbove" Set.empty (Common.set keywordCodec) Backup.printedAbove
  pure Backup.MkBackup {Backup.count = count, Backup.printedAbove = printedAbove}
