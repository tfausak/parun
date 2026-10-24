{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamageR where

import qualified Data.Sequence as Seq
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.DamagePattern as DamagePattern
import qualified Parun.Codec.DamageRewrite as DamageRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageR as DamageR

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.DamageR gives: the record is parametric in the effect so that
-- neither module has to name the other.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (DamageR.DamageR effect)
codec effectCodec = Fields.object $ do
  matching <- Fields.required "matching" DamagePattern.codec DamageR.matching
  rewrite <- Fields.required "rewrite" (DamageRewrite.codec effectCodec) DamageR.rewrite
  riders <- Fields.defaulted "riders" Seq.empty (Common.seq effectCodec) DamageR.riders
  pure
    DamageR.MkDamageR
      { DamageR.matching = matching,
        DamageR.rewrite = rewrite,
        DamageR.riders = riders
      }
