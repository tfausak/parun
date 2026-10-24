{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ShownComponent where

import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.Facing as Facing
import qualified Parun.Codec.MergeComponent as MergeComponent
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Facing as Facing.Type
import qualified Parun.Types.ShownComponent as ShownComponent

codec :: Codec.Codec ShownComponent.ShownComponent
codec = Fields.object $ do
  component <- Fields.required "component" MergeComponent.codec ShownComponent.component
  face <- Fields.defaulted "face" Nothing (Common.maybe CardName.codec) ShownComponent.face
  facing <- Fields.defaulted "facing" Facing.Type.FaceUp Facing.codec ShownComponent.facing
  pure
    ShownComponent.MkShownComponent
      { ShownComponent.component = component,
        ShownComponent.face = face,
        ShownComponent.facing = facing
      }
