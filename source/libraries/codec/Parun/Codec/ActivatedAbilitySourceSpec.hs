module Parun.Codec.ActivatedAbilitySourceSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Parun.Codec.ActivatedAbilitySource as ActivatedAbilitySource
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivatedAbilitySource as ActivatedAbilitySource
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeMemory as ModeMemory
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

-- | What the ability itself encodes to is Parun.Codec.ActivatedAbility's own
-- case; one mana cost and no modes is enough to show the two keys this record
-- adds around it.
ability :: ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)
ability =
  ActivatedAbility.MkActivatedAbility
    (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) [])
    []
    0
    Nothing
    (Modal.MkModal (Seq.singleton (Mode.MkMode Seq.empty Map.empty)) (ModeSelection.ChooseExactly 1) ModeMemory.NoMemory)
    []
    Activator.Controller
    Nothing
    Nothing
    Nothing

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActivatedAbilitySource" $ do
  -- CR 602: the source permanent's id travels beside the ability, so the two
  -- are separate keys rather than the ability alone.
  Spec.it s "an activated ability and the id of what it came from" $
    Common.assertCodec
      s
      ActivatedAbilitySource.codec
      ActivatedAbilitySource.MkActivatedAbilitySource
        { ActivatedAbilitySource.source = ObjectId.MkObjectId 5,
          ActivatedAbilitySource.ability = ability,
          ActivatedAbilitySource.delayed = Map.empty,
          ActivatedAbilitySource.acquisition = Acquisition.Own
        }
      " {\"source\":5,\"ability\":{\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"modal\":{\"modes\":[{}]}}} "
  -- CR 607.5: an ability a copy effect gave its source.
  Spec.it s "an activated ability a copy effect gave its source" $
    Common.assertCodec
      s
      ActivatedAbilitySource.codec
      ActivatedAbilitySource.MkActivatedAbilitySource
        { ActivatedAbilitySource.source = ObjectId.MkObjectId 5,
          ActivatedAbilitySource.ability = ability,
          ActivatedAbilitySource.delayed = Map.empty,
          ActivatedAbilitySource.acquisition = Acquisition.Copied (Timestamp.MkTimestamp 2)
        }
      " {\"source\":5,\"ability\":{\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"modal\":{\"modes\":[{}]}},\"acquisition\":{\"type\":\"Copied\",\"value\":2}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActivatedAbilitySource.codec
