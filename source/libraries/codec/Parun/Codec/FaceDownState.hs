{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FaceDownState where

import qualified Data.Set as Set
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.FaceDownCharacteristics as FaceDownCharacteristics
import qualified Parun.Codec.FaceDownReason as FaceDownReason
import qualified Parun.Codec.TurnUpEvent as TurnUpEvent
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FaceDownState as FaceDownState

codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (FaceDownState.FaceDownState ability)
codec abilityCodec = Fields.object $ do
  reason <- Fields.required "reason" FaceDownReason.codec FaceDownState.reason
  listed <- Fields.required "listed" (FaceDownCharacteristics.codec abilityCodec) FaceDownState.listed
  turnsUpBefore <- Fields.defaulted "turnsUpBefore" Set.empty (Common.set TurnUpEvent.codec) FaceDownState.turnsUpBefore
  pure FaceDownState.MkFaceDownState {FaceDownState.reason = reason, FaceDownState.listed = listed, FaceDownState.turnsUpBefore = turnsUpBefore}
