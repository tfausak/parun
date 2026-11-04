module Parun.Codec.CounterHolder where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounterHolder as CounterHolder

codec :: Codec.Codec CounterHolder.CounterHolder
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Self" CounterHolder.Self,
      Arm.payload "Permanent" (Filter.codec Keyword.codec) CounterHolder.Permanent (\x -> case x of CounterHolder.Permanent y -> Just y; _ -> Nothing)
    ]

tagOf :: CounterHolder.CounterHolder -> String
tagOf x = case x of
  CounterHolder.Self {} -> "Self"
  CounterHolder.Permanent {} -> "Permanent"
