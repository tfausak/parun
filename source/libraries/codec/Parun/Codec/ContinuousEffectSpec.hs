module Parun.Codec.ContinuousEffectSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.ContinuousEffect as ContinuousEffect
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

-- | The card parameter at 'Text.Text', the posture Parun.Codec.ModificationSpec
-- takes: what this module has to prove is the record's own five fields, which
-- the card codec being a parameter makes independent of what a card is.
codec :: Codec.Codec (ContinuousEffect.ContinuousEffect Text.Text)
codec = ContinuousEffect.codec Common.text

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ContinuousEffect" $ do
  -- CR 611.2 with CR 611.2c's fixed set: the objects were chosen as the effect
  -- began, so they are ids rather than a filter.
  Spec.it s "a stored effect over a fixed set of objects" $
    Common.assertCodec
      s
      codec
      ContinuousEffect.MkContinuousEffect
        { ContinuousEffect.source = ObjectId.MkObjectId 1,
          ContinuousEffect.timestamp = Timestamp.MkTimestamp 2,
          ContinuousEffect.expiry = Expiry.AtCleanup,
          ContinuousEffect.modification = Modification.GainKeyword Keyword.Deathtouch,
          ContinuousEffect.affected = Affected.TheseObjects (Set.singleton (ObjectId.MkObjectId 3))
        }
      " {\"source\":1,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"modification\":{\"type\":\"GainKeyword\",\"value\":{\"type\":\"Deathtouch\"}},\"affected\":{\"type\":\"TheseObjects\",\"value\":[3]}} "
  -- CR 611.2a's "for the rest of the game" with a matcher rather than a set --
  -- the shape a Titania's Song row keeps after CR 604.2 has taken its source
  -- away (StaticAbility.lingers).
  Spec.it s "a lingering effect over a matcher" $
    Common.assertCodec
      s
      codec
      ContinuousEffect.MkContinuousEffect
        { ContinuousEffect.source = ObjectId.MkObjectId 4,
          ContinuousEffect.timestamp = Timestamp.MkTimestamp 5,
          ContinuousEffect.expiry = Expiry.Never,
          ContinuousEffect.modification = Modification.LoseAllAbilities,
          ContinuousEffect.affected = Affected.Matching (Filter.HasCardType CardType.Artifact)
        }
      " {\"source\":4,\"timestamp\":5,\"expiry\":{\"type\":\"Never\"},\"modification\":{\"type\":\"LoseAllAbilities\"},\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s codec
