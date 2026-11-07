module Parun.Codec.AttackCompany where

import qualified Data.Maybe as Maybe
import qualified Parun.Codec.AloneAmong as AloneAmong
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AloneAmong as AloneAmongType
import qualified Parun.Types.AttackCompany as AttackCompany

codec :: Codec.Codec AttackCompany.AttackCompany
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AnyCompany" AttackCompany.AnyCompany,
      Arm.optionalPayload "Alone" AloneAmong.codec (AttackCompany.Alone . Maybe.fromMaybe AloneAmongType.EveryAttacker) projectAlone,
      Arm.payload "WithAnother" (Filter.codec Keyword.codec) AttackCompany.WithAnother (\x -> case x of AttackCompany.WithAnother y -> Just y; _ -> Nothing)
    ]

tagOf :: AttackCompany.AttackCompany -> String
tagOf x = case x of
  AttackCompany.AnyCompany -> "AnyCompany"
  AttackCompany.Alone {} -> "Alone"
  AttackCompany.WithAnother {} -> "WithAnother"

-- | CR 506.5's "alone" is the bare tag; CR 506.6's carries its value.
projectAlone :: AttackCompany.AttackCompany -> Maybe (Maybe AloneAmongType.AloneAmong)
projectAlone x = case x of
  AttackCompany.Alone AloneAmongType.EveryAttacker -> Just Nothing
  AttackCompany.Alone among -> Just (Just among)
  _ -> Nothing
