module Pawl.Codec.MovedSpec where

import qualified Data.Sequence as Seq
import qualified Pawl.Codec.Moved as Moved
import qualified Pawl.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Moved as Moved
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Zone as Zone
import qualified Pawl.Types.ZoneChange as ZoneChange

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Moved" $ do
  -- CR 400.7's move, with a NEW id on arrival -- the shape that makes the two
  -- ObjectId keys inside the ZoneChange distinguishable.
  Spec.it s "MkMoved, both keys" $
    Common.assertCodec
      s
      Moved.codec
      ( Moved.MkMoved
          { Moved.change = ZoneChange.MkZoneChange (ObjectId.MkObjectId 1) (ObjectId.MkObjectId 2) Zone.Battlefield Zone.Graveyard,
            Moved.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Moved.otherArrivals = Seq.empty,
            Moved.otherDepartures = Seq.empty,
            Moved.duringResolution = False,
            Moved.revealed = False,
            Moved.seenArriving = False
          }
      )
      ( "{\"change\":{\"departed\":1,\"object\":2,\"from\":{\"type\":\"Battlefield\"},\"to\":{\"type\":\"Graveyard\"}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"otherArrivals\":[]}"
      )
  -- CR 712.21's departure: one permanent left and TWO cards arrived, so the
  -- second one rides in `otherArrivals` while `change` names the first.
  Spec.it s "MkMoved, a melded permanent's second arriving card" $
    Common.assertCodec
      s
      Moved.codec
      ( Moved.MkMoved
          { Moved.change = ZoneChange.MkZoneChange (ObjectId.MkObjectId 1) (ObjectId.MkObjectId 2) Zone.Battlefield Zone.Graveyard,
            Moved.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Moved.otherArrivals = Seq.fromList [ObjectId.MkObjectId 3],
            Moved.otherDepartures = Seq.empty,
            Moved.duringResolution = False,
            Moved.revealed = False,
            Moved.seenArriving = False
          }
      )
      ( "{\"change\":{\"departed\":1,\"object\":2,\"from\":{\"type\":\"Battlefield\"},\"to\":{\"type\":\"Graveyard\"}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"otherArrivals\":[3]}"
      )
  -- CR 701.42a's entry: two cards left exile and ONE permanent arrived, so the
  -- second departure rides in `otherDepartures` while `change` names the first.
  Spec.it s "MkMoved, a meld's second departing card" $
    Common.assertCodec
      s
      Moved.codec
      ( Moved.MkMoved
          { Moved.change = ZoneChange.MkZoneChange (ObjectId.MkObjectId 1) (ObjectId.MkObjectId 2) Zone.Exile Zone.Battlefield,
            Moved.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Moved.otherArrivals = Seq.empty,
            Moved.otherDepartures = Seq.fromList [ObjectId.MkObjectId 3],
            Moved.duringResolution = False,
            Moved.revealed = False,
            Moved.seenArriving = False
          }
      )
      ( "{\"change\":{\"departed\":1,\"object\":2,\"from\":{\"type\":\"Exile\"},\"to\":{\"type\":\"Battlefield\"}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"otherArrivals\":[],\"otherDepartures\":[3]}"
      )
  -- CR 608.2n's own move: the one Moved event that carries the flag, which is
  -- also the one shape the defaulted key appears in.
  Spec.it s "MkMoved, CR 608.2n's move during a spell's own resolution" $
    Common.assertCodec
      s
      Moved.codec
      ( Moved.MkMoved
          { Moved.change = ZoneChange.MkZoneChange (ObjectId.MkObjectId 1) (ObjectId.MkObjectId 2) Zone.Stack Zone.Graveyard,
            Moved.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Moved.otherArrivals = Seq.empty,
            Moved.otherDepartures = Seq.empty,
            Moved.duringResolution = True,
            Moved.revealed = False,
            Moved.seenArriving = False
          }
      )
      ( "{\"change\":{\"departed\":1,\"object\":2,\"from\":{\"type\":\"Stack\"},\"to\":{\"type\":\"Graveyard\"}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"otherArrivals\":[],\"duringResolution\":true}"
      )
  -- CR 603.10a's revealed card leaving a hand: the one shape the flag's
  -- defaulted key appears in.
  Spec.it s "MkMoved, CR 603.10a's revealed card leaving a hidden zone" $
    Common.assertCodec
      s
      Moved.codec
      ( Moved.MkMoved
          { Moved.change = ZoneChange.MkZoneChange (ObjectId.MkObjectId 1) (ObjectId.MkObjectId 2) Zone.Hand Zone.Library,
            Moved.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Moved.otherArrivals = Seq.empty,
            Moved.otherDepartures = Seq.empty,
            Moved.duringResolution = False,
            Moved.revealed = True,
            Moved.seenArriving = False
          }
      )
      ( "{\"change\":{\"departed\":1,\"object\":2,\"from\":{\"type\":\"Hand\"},\"to\":{\"type\":\"Library\"}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"otherArrivals\":[],\"revealed\":true}"
      )
  -- CR 400.2's card seen arriving: a land put onto the battlefield from a
  -- library, the one shape the flag's defaulted key appears in.
  Spec.it s "MkMoved, CR 400.2's card seen arriving in a public zone" $
    Common.assertCodec
      s
      Moved.codec
      ( Moved.MkMoved
          { Moved.change = ZoneChange.MkZoneChange (ObjectId.MkObjectId 1) (ObjectId.MkObjectId 2) Zone.Library Zone.Battlefield,
            Moved.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Moved.otherArrivals = Seq.empty,
            Moved.otherDepartures = Seq.empty,
            Moved.duringResolution = False,
            Moved.revealed = False,
            Moved.seenArriving = True
          }
      )
      ( "{\"change\":{\"departed\":1,\"object\":2,\"from\":{\"type\":\"Library\"},\"to\":{\"type\":\"Battlefield\"}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"otherArrivals\":[],\"seenArriving\":true}"
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s Moved.codec
