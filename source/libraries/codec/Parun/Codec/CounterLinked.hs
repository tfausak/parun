module Parun.Codec.CounterLinked where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounterLinked as CounterLinked

-- | The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (CounterLinked.CounterLinked keyword)
codec keywordCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "PutWith" (CounterKind.codec keywordCodec) CounterLinked.PutWith (\x -> case x of CounterLinked.PutWith y -> Just y; _ -> Nothing),
      Arm.payload "RemovedWith" (CounterKind.codec keywordCodec) CounterLinked.RemovedWith (\x -> case x of CounterLinked.RemovedWith y -> Just y; _ -> Nothing)
    ]

tagOf :: CounterLinked.CounterLinked keyword -> String
tagOf x = case x of
  CounterLinked.PutWith {} -> "PutWith"
  CounterLinked.RemovedWith {} -> "RemovedWith"
