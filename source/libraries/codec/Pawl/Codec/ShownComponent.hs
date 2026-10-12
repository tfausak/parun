{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ShownComponent where

import qualified Pawl.Codec.CardName as CardName
import qualified Pawl.Codec.MergeComponent as MergeComponent
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ShownComponent as ShownComponent

codec :: Codec.Codec ShownComponent.ShownComponent
codec = Fields.object $ do
  component <- Fields.required "component" MergeComponent.codec ShownComponent.component
  face <- Fields.defaulted "face" Nothing (Common.maybe CardName.codec) ShownComponent.face
  pure
    ShownComponent.MkShownComponent
      { ShownComponent.component = component,
        ShownComponent.face = face
      }
