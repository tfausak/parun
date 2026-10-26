module Parun.Codec.PlayerRef where

import qualified Parun.Codec.AttackingPlayers as AttackingPlayers
import qualified Parun.Codec.Holder as Holder
import qualified Parun.Codec.Hop as Hop
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerChoice as PlayerChoice
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.Superlative as Superlative
import qualified Parun.Codec.TurnRole as TurnRole
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | The wire format is the hand-written pair's, which 'Arm.tagged' emits
-- identically; what the conversion added is the schema. "Candidate",
-- "HolderOfBound" and "EachPlayerExcept" are the tags written since.
codec :: Codec.Codec PlayerRef.PlayerRef
codec =
  Arm.tagged
    tagOf
    [ -- The table minus one seat, which a card writes: Shahrazad's "each player
      -- who doesn't win the subgame".
      Arm.payload "EachPlayerExcept" SlotName.codec PlayerRef.EachPlayerExcept (\x -> case x of PlayerRef.EachPlayerExcept y -> Just y; _ -> Nothing),
      Arm.payload "EachOpponentExcept" SlotName.codec PlayerRef.EachOpponentExcept (\x -> case x of PlayerRef.EachOpponentExcept y -> Just y; _ -> Nothing),
      Arm.payload "Relative" PlayerRelation.codec PlayerRef.Relative (\x -> case x of PlayerRef.Relative y -> Just y; _ -> Nothing),
      Arm.payload "InSlot" SlotName.codec PlayerRef.InSlot (\x -> case x of PlayerRef.InSlot y -> Just y; _ -> Nothing),
      -- InSlot's plural, which a card writes: Jungle Wayfinder's searchers are
      -- every seat that took CR 603.5's "may".
      Arm.payload "EachInSlot" SlotName.codec PlayerRef.EachInSlot (\x -> case x of PlayerRef.EachInSlot y -> Just y; _ -> Nothing),
      -- CR 611.2b's baked half. Decodable because an Expiry.While serialises its
      -- whole Condition (CR 603.7b's delayed ability), never because a card may
      -- write one -- Parun.CardSpec sweeps the pool for that.
      Arm.payload "Specific" PlayerId.codec PlayerRef.Specific (\x -> case x of PlayerRef.Specific y -> Just y; _ -> Nothing),
      -- The fold's own candidate, which a card DOES write: Malignus names it
      -- inside an Aggregation.Greatest over Scope.OverPlayers.
      Arm.nullary "Candidate" PlayerRef.Candidate,
      -- CR 608.2h's reference, which a card writes: Spikeshell Harrier names the
      -- controller of the permanent its trigger targeted, The Deck of Many
      -- Things the owner of a creature it reanimated, Soul Bleed the controller
      -- of the creature it enchants.
      Arm.payload "HolderOfBound" holderOfBound (\(h, o, y) -> PlayerRef.HolderOfBound h o y) (\x -> case x of PlayerRef.HolderOfBound h o y -> Just (h, o, y); _ -> Nothing),
      -- The arm above, baked: decodable for Specific's reason, and swept out of
      -- card data beside it.
      Arm.payload "HolderOfObject" holderOfObject (uncurry PlayerRef.HolderOfObject) (\x -> case x of PlayerRef.HolderOfObject h y -> Just (h, y); _ -> Nothing),
      Arm.payload "ChosenPlayerOfBound" (Common.tuple SlotName.codec PlayerChoice.codec) (uncurry PlayerRef.ChosenPlayerOfBound) (\x -> case x of PlayerRef.ChosenPlayerOfBound y z -> Just (y, z); _ -> Nothing),
      -- CR 508.6's set, which a card writes: Curse of Vitality names "each
      -- opponent attacking that player".
      Arm.payload "Attacking" AttackingPlayers.codec PlayerRef.Attacking (\x -> case x of PlayerRef.Attacking y -> Just y; _ -> Nothing),
      -- The table's leaders on a measure, which a card writes: Raiders'
      -- Allegiance rewards "each player with the most point counters".
      Arm.payload "Superlative" Superlative.codec PlayerRef.Superlative (\x -> case x of PlayerRef.Superlative y -> Just y; _ -> Nothing),
      -- The turn's role holders, which a card writes: Stand or Fall's "for each
      -- defending player".
      Arm.payload "InRole" TurnRole.codec PlayerRef.InRole (\x -> case x of PlayerRef.InRole y -> Just y; _ -> Nothing)
    ]

tagOf :: PlayerRef.PlayerRef -> String
tagOf x = case x of
  PlayerRef.EachPlayerExcept {} -> "EachPlayerExcept"
  PlayerRef.EachOpponentExcept {} -> "EachOpponentExcept"
  PlayerRef.Relative {} -> "Relative"
  PlayerRef.InSlot {} -> "InSlot"
  PlayerRef.EachInSlot {} -> "EachInSlot"
  PlayerRef.Specific {} -> "Specific"
  PlayerRef.Candidate {} -> "Candidate"
  PlayerRef.HolderOfBound {} -> "HolderOfBound"
  PlayerRef.HolderOfObject {} -> "HolderOfObject"
  PlayerRef.ChosenPlayerOfBound {} -> "ChosenPlayerOfBound"
  PlayerRef.Attacking {} -> "Attacking"
  PlayerRef.Superlative {} -> "Superlative"
  PlayerRef.InRole {} -> "InRole"

-- | The object-player read keyed by name: which of its players, which object,
-- and the slot naming the object it starts from.
holderOfBound :: Codec.Codec (Holder.Holder, Hop.Hop, SlotName.SlotName)
holderOfBound =
  Fields.object $
    (,,)
      <$> Fields.required "holder" Holder.codec (\(h, _, _) -> h)
      <*> Fields.required "hop" Hop.codec (\(_, o, _) -> o)
      <*> Fields.required "slot" SlotName.codec (\(_, _, y) -> y)

-- | The object-player read baked: which of its players, and the object.
holderOfObject :: Codec.Codec (Holder.Holder, ObjectId.ObjectId)
holderOfObject =
  Fields.object $
    (,)
      <$> Fields.required "holder" Holder.codec fst
      <*> Fields.required "object" ObjectId.codec snd
