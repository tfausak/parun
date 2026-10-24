module Parun.Codec.CostSubject where

import qualified Parun.Codec.ActivationCriteria as ActivationCriteria
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CostSubject as CostSubject

codec :: Codec.Codec CostSubject.CostSubject
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Spells" CostSubject.Spells,
      Arm.payload "Activations" ActivationCriteria.codec CostSubject.Activations (\x -> case x of CostSubject.Activations y -> Just y; _ -> Nothing)
    ]

tagOf :: CostSubject.CostSubject -> String
tagOf x = case x of
  CostSubject.Spells {} -> "Spells"
  CostSubject.Activations {} -> "Activations"
