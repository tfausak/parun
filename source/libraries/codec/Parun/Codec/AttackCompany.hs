module Parun.Codec.AttackCompany where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackCompany as AttackCompany

codec :: Codec.Codec AttackCompany.AttackCompany
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AnyCompany" AttackCompany.AnyCompany,
      Arm.nullary "Alone" AttackCompany.Alone,
      Arm.payload "WithAnother" (Filter.codec Keyword.codec) AttackCompany.WithAnother (\x -> case x of AttackCompany.WithAnother y -> Just y; _ -> Nothing)
    ]

tagOf :: AttackCompany.AttackCompany -> String
tagOf x = case x of
  AttackCompany.AnyCompany -> "AnyCompany"
  AttackCompany.Alone -> "Alone"
  AttackCompany.WithAnother {} -> "WithAnother"
