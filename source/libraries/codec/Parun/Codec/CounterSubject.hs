module Parun.Codec.CounterSubject where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounterSubject as CounterSubject

codec :: Codec.Codec CounterSubject.CounterSubject
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "ByEffect" CounterSubject.ByEffect,
      Arm.payload "ByPlayer" ControllerRelation.codec CounterSubject.ByPlayer (\x -> case x of CounterSubject.ByPlayer y -> Just y; _ -> Nothing),
      Arm.nullary "ByAnything" CounterSubject.ByAnything
    ]

tagOf :: CounterSubject.CounterSubject -> String
tagOf x = case x of
  CounterSubject.ByEffect {} -> "ByEffect"
  CounterSubject.ByPlayer {} -> "ByPlayer"
  CounterSubject.ByAnything {} -> "ByAnything"
