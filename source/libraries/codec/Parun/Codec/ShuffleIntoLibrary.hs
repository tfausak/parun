{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ShuffleIntoLibrary where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ShuffleIntoLibrary as ShuffleIntoLibrary

-- | A bare object keyed by the record's field names, with the library-naming ref
-- and the slot elided when absent.
--
-- The positional payload this replaces was a lone ObjectRef or a pair, told
-- apart on decode by JSON TYPE -- which only worked once #1304 stopped an
-- ObjectRef from ever being an array itself. A named optional key needs no such
-- argument.
codec :: Codec.Codec ShuffleIntoLibrary.ShuffleIntoLibrary
codec = Fields.object $ do
  library <- Fields.defaulted "library" Nothing (Common.maybe PlayerRef.codec) ShuffleIntoLibrary.library
  refs <- Fields.required "refs" (Common.nonEmpty ObjectRef.codec) ShuffleIntoLibrary.refs
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) ShuffleIntoLibrary.slot
  pure
    ShuffleIntoLibrary.MkShuffleIntoLibrary
      { ShuffleIntoLibrary.library = library,
        ShuffleIntoLibrary.refs = refs,
        ShuffleIntoLibrary.slot = slot
      }
