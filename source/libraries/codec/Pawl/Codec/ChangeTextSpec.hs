module Pawl.Codec.ChangeTextSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Codec.ChangeText as ChangeText
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ChangeText as ChangeText
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.TextWord as TextWord
import qualified Pawl.Types.WordFamily as WordFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ChangeText" $ do
  -- CR 612's text change, within one family. The forbidden set is what the
  -- chooser may NOT pick, and it is written even when empty is the common case,
  -- because a required key says the family and the exclusions are two
  -- different questions. CR 611.2a's Indefinite is the default and is omitted.
  Spec.it s "MkChangeText, an empty forbidden set" $
    Common.assertCodec
      s
      ChangeText.codec
      ( ChangeText.MkChangeText
          { ChangeText.families = Set.singleton WordFamily.BasicLandType,
            ChangeText.forbidden = Set.empty,
            ChangeText.slot = SlotName.MkSlotName (Text.pack "target"),
            ChangeText.duration = Duration.Indefinite
          }
      )
      " {\"families\":[{\"type\":\"BasicLandType\"}],\"forbidden\":[],\"slot\":\"target\"} "
  -- The set is ascending and deduplicated on the wire, which Common.set's
  -- decoder additionally rejects a repeat for.
  Spec.it s "MkChangeText, forbidden subtypes are written in order" $
    Common.assertCodec
      s
      ChangeText.codec
      ( ChangeText.MkChangeText
          { ChangeText.families = Set.singleton WordFamily.BasicLandType,
            ChangeText.forbidden = Set.fromList [TextWord.SubtypeWord Subtype.Island, TextWord.SubtypeWord Subtype.Forest],
            ChangeText.slot = SlotName.MkSlotName (Text.pack "target"),
            ChangeText.duration = Duration.Indefinite
          }
      )
      " {\"families\":[{\"type\":\"BasicLandType\"}],\"forbidden\":[{\"type\":\"Forest\"},{\"type\":\"Island\"}],\"slot\":\"target\"} "
  -- Whim of Volrath's two families and stated duration.
  Spec.it s "MkChangeText, two families until end of turn" $
    Common.assertCodec
      s
      ChangeText.codec
      ( ChangeText.MkChangeText
          { ChangeText.families = Set.fromList [WordFamily.Color, WordFamily.BasicLandType],
            ChangeText.forbidden = Set.empty,
            ChangeText.slot = SlotName.MkSlotName (Text.pack "target"),
            ChangeText.duration = Duration.UntilEndOfTurn
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"families\":[{\"type\":\"BasicLandType\"},{\"type\":\"Color\"}],\"forbidden\":[],\"slot\":\"target\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChangeText.codec
