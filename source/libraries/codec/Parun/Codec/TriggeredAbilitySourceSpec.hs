module Parun.Codec.TriggeredAbilitySourceSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.TriggeredAbilitySource as TriggeredAbilitySource
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.Card as Card
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TriggeredAbilitySource as TriggeredAbilitySource

-- | What the ability itself encodes to is Parun.Codec.TriggeredAbility's own
-- case; a bare enters trigger is enough to show the two keys this record adds
-- around it.
ability :: TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)
ability =
  TriggeredAbility.MkTriggeredAbility
    { TriggeredAbility.condition = TriggerCondition.SelfEnters,
      TriggeredAbility.modal =
        Modal.MkModal
          (Seq.singleton (Mode.MkMode Seq.empty Map.empty))
          (ModeSelection.ChooseExactly 1),
      TriggeredAbility.intervening = Nothing,
      TriggeredAbility.name = Nothing,
      TriggeredAbility.limit = TriggerLimit.Unlimited,
      TriggeredAbility.functionsFrom = Set.empty
    }

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TriggeredAbilitySource" $ do
  -- CR 603.3: the source permanent's id travels with the ability, which is why
  -- the ability resolves after the source has left (CR 603.3d). The key is
  -- `source`, and Parun.Codec.InherentTriggerSource's is `controller`: the two
  -- records carry the same ability under different first fields.
  Spec.it s "a triggered ability and the id of what it came from" $
    Common.assertCodec
      s
      TriggeredAbilitySource.codec
      TriggeredAbilitySource.MkTriggeredAbilitySource
        { TriggeredAbilitySource.source = ObjectId.MkObjectId 6,
          TriggeredAbilitySource.ability = ability,
          TriggeredAbilitySource.createdAt = Nothing,
          TriggeredAbilitySource.delayed = Map.empty,
          TriggeredAbilitySource.acquisition = Acquisition.Own
        }
      " {\"source\":6,\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}}} "
  -- CR 603.7a: the same record for an ability that fired from a delayed entry,
  -- which is the one case the key is present for.
  Spec.it s "a delayed triggered ability, which carries when it was created" $
    Common.assertCodec
      s
      TriggeredAbilitySource.codec
      TriggeredAbilitySource.MkTriggeredAbilitySource
        { TriggeredAbilitySource.source = ObjectId.MkObjectId 6,
          TriggeredAbilitySource.ability = ability,
          TriggeredAbilitySource.createdAt = Just (Timestamp.MkTimestamp 3),
          TriggeredAbilitySource.delayed = Map.empty,
          TriggeredAbilitySource.acquisition = Acquisition.Own
        }
      " {\"source\":6,\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"createdAt\":3} "
  -- CR 113.7a: the delayed declarations frozen as the ability triggered.
  Spec.it s "a triggered ability carrying its source's delayed declarations" $
    Common.assertCodec
      s
      TriggeredAbilitySource.codec
      TriggeredAbilitySource.MkTriggeredAbilitySource
        { TriggeredAbilitySource.source = ObjectId.MkObjectId 6,
          TriggeredAbilitySource.ability = ability,
          TriggeredAbilitySource.createdAt = Nothing,
          TriggeredAbilitySource.delayed = Map.singleton (AbilityName.MkAbilityName (Text.pack "later")) ability,
          TriggeredAbilitySource.acquisition = Acquisition.Own
        }
      " {\"source\":6,\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"delayed\":{\"later\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}}}} "
  -- CR 607.5: an ability a copy effect gave its source, which is the one case
  -- the key is present for.
  Spec.it s "a triggered ability a copy effect gave its source" $
    Common.assertCodec
      s
      TriggeredAbilitySource.codec
      TriggeredAbilitySource.MkTriggeredAbilitySource
        { TriggeredAbilitySource.source = ObjectId.MkObjectId 6,
          TriggeredAbilitySource.ability = ability,
          TriggeredAbilitySource.createdAt = Nothing,
          TriggeredAbilitySource.delayed = Map.empty,
          TriggeredAbilitySource.acquisition = Acquisition.Copied (Timestamp.MkTimestamp 4)
        }
      " {\"source\":6,\"ability\":{\"condition\":{\"type\":\"SelfEnters\"},\"modal\":{\"modes\":[{}]}},\"acquisition\":{\"type\":\"Copied\",\"value\":4}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TriggeredAbilitySource.codec
