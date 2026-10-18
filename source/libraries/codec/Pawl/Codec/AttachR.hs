{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.AttachR where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.AttachRewrite as AttachRewrite
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.AttachR as AttachR

-- | A bare object keyed by the record's field names, Pawl.Codec.TurnUpR's shape.
codec ::
  (Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) =>
  Codec.Codec ability ->
  Codec.Codec effect ->
  Codec.Codec (AttachR.AttachR ability effect)
codec abilityCodec effectCodec = Fields.object $ do
  matching <- Fields.required "matching" (Filter.codec Keyword.codec) AttachR.matching
  rewrite <- Fields.required "rewrite" (AttachRewrite.codec abilityCodec effectCodec) AttachR.rewrite
  pure AttachR.MkAttachR {AttachR.matching = matching, AttachR.rewrite = rewrite}
