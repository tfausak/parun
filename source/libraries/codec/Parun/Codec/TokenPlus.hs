module Parun.Codec.TokenPlus where

import qualified Data.Typeable as Typeable
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TokenPlus as TokenPlus

-- | The card codec is a PARAMETER for Parun.Codec.TokenR's reason.
codec :: (Typeable.Typeable card) => Codec.Codec card -> Codec.Codec (TokenPlus.TokenPlus card)
codec cardCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "One" cardCodec TokenPlus.One (\x -> case x of TokenPlus.One y -> Just y; _ -> Nothing),
      Arm.payload "ThatMany" cardCodec TokenPlus.ThatMany (\x -> case x of TokenPlus.ThatMany y -> Just y; _ -> Nothing)
    ]

tagOf :: TokenPlus.TokenPlus card -> String
tagOf x = case x of
  TokenPlus.One {} -> "One"
  TokenPlus.ThatMany {} -> "ThatMany"
