module Parun.Codec.PlayerRefSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackingPlayers as AttackingPlayers
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Gift as Gift
import qualified Parun.Types.KeywordInstance as KeywordInstance
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerChoice as PlayerChoice
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerMeasure as PlayerMeasure
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Superlative as Superlative
import qualified Parun.Types.TurnRole as TurnRole

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerRef" $ do
  -- CR 102.1's whole table has one spelling, the relation every reader judges.
  Spec.it s "Relative AnyPlayer is the whole table" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.Relative PlayerRelation.AnyPlayer)
      " {\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}} "
  Spec.it s "Relative" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.Relative PlayerRelation.You)
      " {\"type\":\"Relative\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "InSlot" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"InSlot\",\"value\":\"target\"} "
  Spec.it s "EachInSlot" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.EachInSlot (SlotName.MkSlotName (Text.pack "thoseWhoMay")))
      " {\"type\":\"EachInSlot\",\"value\":\"thoseWhoMay\"} "
  Spec.it s "Specific" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.Specific (PlayerId.MkPlayerId 1))
      " {\"type\":\"Specific\",\"value\":1} "
  Spec.it s "Candidate" $
    Common.assertCodec
      s
      PlayerRef.codec
      PlayerRef.Candidate
      " {\"type\":\"Candidate\"} "
  Spec.it s "ControllerOfBound" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.ControllerOfBound (SlotName.MkSlotName (Text.pack "permanent")))
      " {\"type\":\"ControllerOfBound\",\"value\":\"permanent\"} "
  Spec.it s "OwnerOfBound" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.OwnerOfBound (SlotName.MkSlotName (Text.pack "permanent")))
      " {\"type\":\"OwnerOfBound\",\"value\":\"permanent\"} "
  Spec.it s "ControllerOfObject" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.ControllerOfObject (ObjectId.MkObjectId 7))
      " {\"type\":\"ControllerOfObject\",\"value\":7} "
  Spec.it s "OwnerOfObject" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.OwnerOfObject (ObjectId.MkObjectId 7))
      " {\"type\":\"OwnerOfObject\",\"value\":7} "
  -- CR 614.1c / CR 702.174b: ControllerOfBound's shape one record over.
  Spec.it s "ChosenPlayerOfBound" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.ChosenPlayerOfBound (SlotName.MkSlotName (Text.pack "permanent")) (PlayerChoice.Promised Gift.Card (KeywordInstance.Own 2)))
      " {\"type\":\"ChosenPlayerOfBound\",\"value\":[\"permanent\",{\"type\":\"Promised\",\"value\":[{\"type\":\"Card\"},{\"type\":\"Own\",\"value\":2}]}]} "
  Spec.it s "Attacking" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.Attacking (AttackingPlayers.MkAttackingPlayers PlayerRelation.Opponent (SlotName.MkSlotName (Text.pack "attackedPlayer"))))
      " {\"type\":\"Attacking\",\"value\":{\"relation\":{\"type\":\"Opponent\"},\"attacked\":\"attackedPlayer\"}} "
  Spec.it s "Superlative" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.Superlative (Superlative.MkSuperlative (PlayerMeasure.CountersOf PlayerCounterKind.Point) Comparison.AtLeast))
      " {\"type\":\"Superlative\",\"value\":{\"measure\":{\"type\":\"CountersOf\",\"value\":{\"type\":\"Point\"}},\"comparison\":{\"type\":\"AtLeast\"}}} "
  Spec.it s "InRole" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.InRole TurnRole.Defending)
      " {\"type\":\"InRole\",\"value\":{\"type\":\"Defending\"}} "
  Spec.it s "EachOpponentExcept" $
    Common.assertCodec
      s
      PlayerRef.codec
      (PlayerRef.EachOpponentExcept (SlotName.MkSlotName (Text.pack "defendingPlayer")))
      " {\"type\":\"EachOpponentExcept\",\"value\":\"defendingPlayer\"} "
  Spec.it s "an unknown tag is rejected" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " {\"type\":\"EachOpponent\"} ") >>= Codec.decode PlayerRef.codec))
      "expected a decode failure"
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerRef.codec
