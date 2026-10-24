module Parun.Codec.RestrictedCreatures where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures

-- | Tagged, in Parun.Codec.AffectedPlayers' shape and PARAMETRIC for its reason:
-- a card writes @RestrictedCreatures ObjectRef@ (Parun.Codec.ForbidAttack passes
-- Parun.Codec.ObjectRef's codec) and the store holds @RestrictedCreatures
-- ObjectId@ (Parun.Codec.ActiveAttackProhibition passes Parun.Codec.ObjectId's).
codec ::
  (Typeable.Typeable named) =>
  Codec.Codec named ->
  Codec.Codec (RestrictedCreatures.RestrictedCreatures named)
codec namedCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "Named" namedCodec RestrictedCreatures.Named (\x -> case x of RestrictedCreatures.Named y -> Just y; _ -> Nothing),
      Arm.payload "Matching" (Filter.codec Keyword.codec) RestrictedCreatures.Matching (\x -> case x of RestrictedCreatures.Matching y -> Just y; _ -> Nothing)
    ]

tagOf :: RestrictedCreatures.RestrictedCreatures named -> String
tagOf x = case x of
  RestrictedCreatures.Named {} -> "Named"
  RestrictedCreatures.Matching {} -> "Matching"
