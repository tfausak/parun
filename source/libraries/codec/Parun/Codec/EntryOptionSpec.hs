module Parun.Codec.EntryOptionSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.EntryOption as EntryOption
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryOption as EntryOption
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Subtype as Subtype

-- CR 208.2b / 614.1c: one of the shapes an as-enters choice offers. EntryOption
-- has one constructor, so both shapes ride one case -- a plain option and one
-- carrying a nonempty keyword set.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryOption" $ do
  Spec.it s "MkEntryOption round-trips with an empty keyword set" $
    Common.assertCodec
      s
      EntryOption.codec
      (EntryOption.MkEntryOption {EntryOption.power = 3, EntryOption.toughness = 3, EntryOption.keywords = Set.empty, EntryOption.subtypes = Set.empty})
      " {\"power\":3,\"toughness\":3} "
  Spec.it s "MkEntryOption round-trips with its keyword set" $
    Common.assertCodec
      s
      EntryOption.codec
      (EntryOption.MkEntryOption {EntryOption.power = 1, EntryOption.toughness = 6, EntryOption.keywords = Set.singleton Keyword.Defender, EntryOption.subtypes = Set.empty})
      " {\"power\":1,\"toughness\":6,\"keywords\":[{\"type\":\"Defender\"}]} "
  -- Primal Clay's "1/6 Wall artifact creature with defender".
  Spec.it s "MkEntryOption round-trips with its subtype set" $
    Common.assertCodec
      s
      EntryOption.codec
      (EntryOption.MkEntryOption {EntryOption.power = 1, EntryOption.toughness = 6, EntryOption.keywords = Set.singleton Keyword.Defender, EntryOption.subtypes = Set.singleton Subtype.Wall})
      " {\"power\":1,\"toughness\":6,\"keywords\":[{\"type\":\"Defender\"}],\"subtypes\":[{\"type\":\"Wall\"}]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s EntryOption.codec
