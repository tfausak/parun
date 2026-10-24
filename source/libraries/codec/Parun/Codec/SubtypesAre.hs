{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SubtypesAre where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SubtypesAre as SubtypesAre

-- | Subtypes as bare names, as Parun.Codec.TypesAre spells card types.
codec :: Codec.Codec SubtypesAre.SubtypesAre
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec SubtypesAre.object
  subtypes <- Fields.required "subtypes" (Common.set Arm.keyedEnum) SubtypesAre.subtypes
  pure SubtypesAre.MkSubtypesAre {SubtypesAre.object = object, SubtypesAre.subtypes = subtypes}
