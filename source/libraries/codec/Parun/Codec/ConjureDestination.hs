module Parun.Codec.ConjureDestination where

import qualified Data.Maybe as Maybe
import qualified Parun.Codec.ConjureEntry as ConjureEntry
import qualified Parun.Codec.LibraryDepth as LibraryDepth
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ConjureDestination as ConjureDestination
import qualified Parun.Types.ConjureEntry as ConjureEntry

-- | @Library@ is 'Arm.optionalPayload' so a conjure naming no place (Toralf\'s
-- Disciple) writes the bare tag.
--
-- @Battlefield@ is 'Arm.optionalPayload' rather than 'Arm.payload' for
-- Parun.Codec.Conjure's reason: "onto the battlefield" states nothing about the
-- arrival, so it writes the bare tag and only "tapped" or "attacking" writes a
-- value. An explicit default still decodes, and encodes back to the bare tag,
-- which is the canonical spelling Parun.CardSpec's corpus round trip holds every
-- card file to.
codec :: Codec.Codec ConjureDestination.ConjureDestination
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Hand" ConjureDestination.Hand,
      Arm.optionalPayload "Library" LibraryDepth.codec ConjureDestination.Library (\x -> case x of ConjureDestination.Library y -> Just y; _ -> Nothing),
      Arm.nullary "Graveyard" ConjureDestination.Graveyard,
      Arm.nullary "Exile" ConjureDestination.Exile,
      Arm.optionalPayload
        "Battlefield"
        ConjureEntry.codec
        (ConjureDestination.Battlefield . Maybe.fromMaybe ConjureEntry.defaultValue)
        ( \x -> case x of
            ConjureDestination.Battlefield entry
              | entry == ConjureEntry.defaultValue -> Just Nothing
              | otherwise -> Just (Just entry)
            _ -> Nothing
        )
    ]

-- | Total, which is what makes a new constructor an error here rather than a
-- silent @{}@ -- 'Arm.tagged' says why it takes this beside the arm list.
tagOf :: ConjureDestination.ConjureDestination -> String
tagOf x = case x of
  ConjureDestination.Hand -> "Hand"
  ConjureDestination.Library _ -> "Library"
  ConjureDestination.Graveyard -> "Graveyard"
  ConjureDestination.Battlefield _ -> "Battlefield"
  ConjureDestination.Exile -> "Exile"
