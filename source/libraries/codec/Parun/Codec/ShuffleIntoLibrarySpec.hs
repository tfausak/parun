module Parun.Codec.ShuffleIntoLibrarySpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Parun.Codec.ShuffleIntoLibrary as ShuffleIntoLibrary
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.ShuffleIntoLibrary as ShuffleIntoLibrary
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ShuffleIntoLibrary" $ do
  -- Riftsweeper's "its owner shuffles it into their library": the library is
  -- derived from the objects (CR 400.3), so there is no key to write.
  Spec.it s "MkShuffleIntoLibrary, library elided" $
    Common.assertCodec
      s
      ShuffleIntoLibrary.codec
      ( ShuffleIntoLibrary.MkShuffleIntoLibrary
          { ShuffleIntoLibrary.library = Nothing,
            ShuffleIntoLibrary.refs = NonEmpty.singleton (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))),
            ShuffleIntoLibrary.slot = Nothing
          }
      )
      " {\"refs\":[{\"type\":\"InSlot\",\"value\":\"target\"}]} "
  -- CR 701.24c's named library -- Dwell on the Past's "their library", which
  -- is shuffled whether or not any of the named cards arrive.
  Spec.it s "MkShuffleIntoLibrary, library named" $
    Common.assertCodec
      s
      ShuffleIntoLibrary.codec
      ( ShuffleIntoLibrary.MkShuffleIntoLibrary
          { ShuffleIntoLibrary.library = Just (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "player"))),
            ShuffleIntoLibrary.refs = NonEmpty.singleton (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "cards"))),
            ShuffleIntoLibrary.slot = Nothing
          }
      )
      " {\"library\":{\"type\":\"InSlot\",\"value\":\"player\"},\"refs\":[{\"type\":\"InSlot\",\"value\":\"cards\"}]} "
  -- Timetwister's "their hand and graveyard": two sets in one instruction.
  Spec.it s "MkShuffleIntoLibrary, two refs" $
    Common.assertCodec
      s
      ShuffleIntoLibrary.codec
      ( ShuffleIntoLibrary.MkShuffleIntoLibrary
          { ShuffleIntoLibrary.library = Nothing,
            ShuffleIntoLibrary.refs = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "hand")) NonEmpty.:| [ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "graveyard"))],
            ShuffleIntoLibrary.slot = Nothing
          }
      )
      " {\"refs\":[{\"type\":\"InSlot\",\"value\":\"hand\"},{\"type\":\"InSlot\",\"value\":\"graveyard\"}]} "
  -- Winds of Change's "then draws that many": the shuffled-in cards bound.
  Spec.it s "MkShuffleIntoLibrary, slot named" $
    Common.assertCodec
      s
      ShuffleIntoLibrary.codec
      ( ShuffleIntoLibrary.MkShuffleIntoLibrary
          { ShuffleIntoLibrary.library = Nothing,
            ShuffleIntoLibrary.refs = NonEmpty.singleton (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "hand"))),
            ShuffleIntoLibrary.slot = Just (SlotName.MkSlotName (Text.pack "shuffled"))
          }
      )
      " {\"refs\":[{\"type\":\"InSlot\",\"value\":\"hand\"}],\"slot\":\"shuffled\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ShuffleIntoLibrary.codec
