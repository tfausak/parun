module Parun.Codec.PastActivationSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.PastActivation as PastActivation
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Types.PastActivation as PastActivation
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PastActivation" $ do
  let snapshotOf n =
        ObjectSnapshot.MkObjectSnapshot
          { ObjectSnapshot.object = ObjectId.MkObjectId n,
            ObjectSnapshot.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            ObjectSnapshot.controller = Just (PlayerId.MkPlayerId 1),
            ObjectSnapshot.owner = PlayerId.MkPlayerId 1,
            ObjectSnapshot.zone = Zone.Stack,
            ObjectSnapshot.home = Zone.Battlefield,
            ObjectSnapshot.lapsedGrants = Set.empty
          }
      snapshotJson n = "{\"object\":" <> show (n :: Integer) <> ",\"characteristics\":" <> ProjectedCharacteristicsSpec.testCharacteristicsJson <> ",\"controller\":1,\"owner\":1,\"zone\":{\"type\":\"Stack\"}}"
      -- The barest printed ability: no cost, one empty mode.
      bare = ActivatedAbility.MkActivatedAbility (Cost.MkCost Nothing []) [] 0 Nothing (Modal.MkModal (Seq.singleton (Mode.MkMode Seq.empty Map.empty)) (ModeSelection.ChooseExactly 1)) [] Activator.Controller Nothing Nothing Nothing
  Spec.it s "an ability announced at one target" $
    Common.assertCodec
      s
      PastActivation.codec
      PastActivation.MkPastActivation
        { PastActivation.activator = PlayerId.MkPlayerId 2,
          PastActivation.source = snapshotOf 5,
          PastActivation.ability = Just bare,
          PastActivation.kind = AbilityKind.NonManaAbility,
          PastActivation.targets = [snapshotOf 6]
        }
      (" {\"activator\":2,\"source\":" <> snapshotJson 5 <> ",\"ability\":{\"cost\":{\"mana\":null},\"modal\":{\"modes\":[{}]}},\"kind\":{\"type\":\"NonManaAbility\"},\"targets\":[" <> snapshotJson 6 <> "]} ")
  -- CR 605.1a: a mana ability names no target.
  Spec.it s "a mana ability" $
    Common.assertCodec
      s
      PastActivation.codec
      PastActivation.MkPastActivation
        { PastActivation.activator = PlayerId.MkPlayerId 1,
          PastActivation.source = snapshotOf 7,
          PastActivation.ability = Nothing,
          PastActivation.kind = AbilityKind.ManaAbility,
          PastActivation.targets = []
        }
      (" {\"activator\":1,\"source\":" <> snapshotJson 7 <> ",\"ability\":null,\"kind\":{\"type\":\"ManaAbility\"},\"targets\":[]} ")
  Spec.it s "has a schema" $
    Common.assertHasSchema s PastActivation.codec
