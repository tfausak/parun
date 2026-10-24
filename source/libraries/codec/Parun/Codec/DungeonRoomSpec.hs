module Parun.Codec.DungeonRoomSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.DungeonRoom as DungeonRoom
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.DungeonRoom as DungeonRoom
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Face as Face
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RoomIndex as RoomIndex

-- | The `card` parameter is instantiated at 'Text.Text', TriggeredAbilitySpec's
-- posture: the codec reaches it only through the supplied Modal codec.
cardCodec :: Codec.Codec Text.Text
cardCodec = Common.text

codec :: Codec.Codec (DungeonRoom.DungeonRoom Text.Text)
codec = DungeonRoom.codec cardCodec

toJson :: DungeonRoom.DungeonRoom Text.Text -> Value.Value
toJson = Codec.encode codec

fromJson :: Value.Value -> Either Text.Text (DungeonRoom.DungeonRoom Text.Text)
fromJson = Codec.decode codec

drawOne :: Modal.Modal Text.Text (GrantedAbility.GrantedAbility Text.Text)
drawOne =
  Modal.MkModal
    ( Seq.singleton
        ( Mode.MkMode
            (Seq.singleton (Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.singleton (Effect.Draw (Draw.MkDraw (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 1) Nothing)))))
            Map.empty
        )
    )
    (ModeSelection.ChooseExactly 1)

-- One constructor, so two cases: a room with arrows and an ability, and a room
-- writing neither optional key -- the bottommost room of a dungeon whose printed
-- effect parun cannot express. No card in data/cards is in that state today, so
-- this is where the codec's ability default is exercised at all.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DungeonRoom" $ do
  Spec.it s "MkDungeonRoom, Lost Mine of Phandelver's Temple of Dumathoin" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( DungeonRoom.MkDungeonRoom
          { DungeonRoom.name = AbilityName.MkAbilityName (Text.pack "Temple of Dumathoin"),
            DungeonRoom.ability = drawOne,
            DungeonRoom.exits = Set.empty
          }
      )
      " {\"name\":\"Temple of Dumathoin\",\"ability\":{\"modes\":[{\"clauses\":[{\"effects\":[{\"type\":\"Draw\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":1}}}]}]}]}} "
  -- CR 309.5a: a room with two arrows out of it. The ability is left at its
  -- default, which is what a room whose printed effect parun cannot express writes.
  Spec.it s "MkDungeonRoom, Cave Entrance's two arrows and no expressible ability" $
    Common.assertJsonCodec
      s
      toJson
      fromJson
      ( DungeonRoom.MkDungeonRoom
          { DungeonRoom.name = AbilityName.MkAbilityName (Text.pack "Cave Entrance"),
            DungeonRoom.ability = Face.defaultSpell,
            DungeonRoom.exits = Set.fromList [RoomIndex.MkRoomIndex 1, RoomIndex.MkRoomIndex 2]
          }
      )
      " {\"name\":\"Cave Entrance\",\"exits\":[1,2]} "
