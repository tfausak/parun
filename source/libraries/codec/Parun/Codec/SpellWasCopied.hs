{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SpellWasCopied where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SpellWasCopied as SpellWasCopied

-- | Parun.Codec.Exploited's shape: a bare object keyed by the record's field
-- names. Runtime-only, GameEvent serialising transcripts rather than card data.
codec :: Codec.Codec SpellWasCopied.SpellWasCopied
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec SpellWasCopied.player
  copy <- Fields.required "copy" ObjectId.codec SpellWasCopied.copy
  pure
    SpellWasCopied.MkSpellWasCopied
      { SpellWasCopied.player = player,
        SpellWasCopied.copy = copy
      }
