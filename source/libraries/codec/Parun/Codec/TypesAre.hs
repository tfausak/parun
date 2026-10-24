{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TypesAre where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TypesAre as TypesAre

-- | Card types as bare names: @["Battle", "Creature"]@.
codec :: Codec.Codec TypesAre.TypesAre
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec TypesAre.object
  types <- Fields.required "types" (Common.set Arm.keyedEnum) TypesAre.types
  pure TypesAre.MkTypesAre {TypesAre.object = object, TypesAre.types = types}
