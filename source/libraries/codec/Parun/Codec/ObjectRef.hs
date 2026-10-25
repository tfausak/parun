module Parun.Codec.ObjectRef where

import qualified Parun.Codec.AttachedToBound as AttachedToBound
import qualified Parun.Codec.ChosenCardFromAmong as ChosenCardFromAmong
import qualified Parun.Codec.ChosenCardInGraveyard as ChosenCardInGraveyard
import qualified Parun.Codec.ChosenCardInHand as ChosenCardInHand
import qualified Parun.Codec.ChosenPermanents as ChosenPermanents
import qualified Parun.Codec.EachCardFromAmong as EachCardFromAmong
import qualified Parun.Codec.EachCardInExiledPile as EachCardInExiledPile
import qualified Parun.Codec.EachCardInGraveyard as EachCardInGraveyard
import qualified Parun.Codec.EachCardInHand as EachCardInHand
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.FromAnywhere as FromAnywhere
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.PlayersWho as PlayersWho
import qualified Parun.Codec.RandomCardInGraveyard as RandomCardInGraveyard
import qualified Parun.Codec.RandomCardInHand as RandomCardInHand
import qualified Parun.Codec.RandomCardInLibrary as RandomCardInLibrary
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.TopOfLibrary as TopOfLibrary
import qualified Parun.Codec.TopOfLibraryUntil as TopOfLibraryUntil
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ObjectRef as ObjectRef

-- | Tagged like every other sum. The arms were previously told apart by
-- JSON TYPE -- a string was a slot, an object the battlefield sweep's Filter,
-- and everything else an array leading with its own word -- which no schema can
-- state as a claim the decoder guarantees (#1304). The word an array led with
-- was already a tag in all but name; it now sits under @type@ where every other
-- sum's does, and the arms carrying no payload or one need no array at all.
--
-- A BUNDLE since 'Parun.Codec.PlayerRef' became one, which is what 'TopOfLibrary'
-- was waiting on. The wire format is unchanged by that conversion -- the same
-- tags, emitted identically -- and what it adds is the schema.
--
-- 'EachCardInGraveyard', 'EachCardInHand', 'EachCardInExiledPile', 'TopOfLibrary', 'TopOfLibraryUntil', 'ChosenCardInGraveyard',
-- 'ChosenCardInHand', 'ChosenCardFromAmong', 'EachCardFromAmong', 'RandomCardInHand', 'RandomCardInGraveyard', 'RandomCardInLibrary',
-- 'FromAnywhere', 'ChosenPermanents' and 'Players' each carry a payload record of their own (#1464), so no arm here writes a
-- positional array.
--
-- 'EachCardInYourLibrary' takes an OPTIONAL payload: the bare tag is the whole
-- library (CR 400.12), and a value narrows it to the cards a printing's own
-- words name. The widening left the printings written before it on the bare
-- tag, so it changed no card on the wire.
codec :: Codec.Codec ObjectRef.ObjectRef
codec =
  let -- Written once so the encoder, the decoder and the schema cannot disagree
      -- about which keyword codec the filter carries.
      filterCodec = Filter.codec Keyword.codec
   in Arm.tagged
        tagOf
        [ Arm.payload "InSlot" SlotName.codec ObjectRef.InSlot (\x -> case x of ObjectRef.InSlot y -> Just y; _ -> Nothing),
          Arm.payload "EachMatching" filterCodec ObjectRef.EachMatching (\x -> case x of ObjectRef.EachMatching y -> Just y; _ -> Nothing),
          Arm.payload "EachCardInGraveyard" EachCardInGraveyard.codec ObjectRef.EachCardInGraveyard (\x -> case x of ObjectRef.EachCardInGraveyard y -> Just y; _ -> Nothing),
          Arm.nullary "EachCardInYourHand" ObjectRef.EachCardInYourHand,
          Arm.payload "EachCardInHand" EachCardInHand.codec ObjectRef.EachCardInHand (\x -> case x of ObjectRef.EachCardInHand y -> Just y; _ -> Nothing),
          Arm.optionalPayload "EachCardInYourLibrary" filterCodec ObjectRef.EachCardInYourLibrary (\x -> case x of ObjectRef.EachCardInYourLibrary y -> Just y; _ -> Nothing),
          Arm.payload "EachCardYouOwn" filterCodec ObjectRef.EachCardYouOwn (\x -> case x of ObjectRef.EachCardYouOwn y -> Just y; _ -> Nothing),
          Arm.payload "EachCardInExiledPile" EachCardInExiledPile.codec ObjectRef.EachCardInExiledPile (\x -> case x of ObjectRef.EachCardInExiledPile y -> Just y; _ -> Nothing),
          Arm.optionalPayload "EachCardEncodedOnSource" filterCodec ObjectRef.EachCardEncodedOnSource (\x -> case x of ObjectRef.EachCardEncodedOnSource y -> Just y; _ -> Nothing),
          Arm.payload "EachSpell" filterCodec ObjectRef.EachSpell (\x -> case x of ObjectRef.EachSpell y -> Just y; _ -> Nothing),
          Arm.payload "EachAbility" filterCodec ObjectRef.EachAbility (\x -> case x of ObjectRef.EachAbility y -> Just y; _ -> Nothing),
          Arm.payload "EachOnStack" filterCodec ObjectRef.EachOnStack (\x -> case x of ObjectRef.EachOnStack y -> Just y; _ -> Nothing),
          Arm.nullary "EachPlayer" ObjectRef.EachPlayer,
          Arm.nullary "EachOpponent" ObjectRef.EachOpponent,
          Arm.nullary "ChosenPlayer" ObjectRef.ChosenPlayer,
          Arm.payload "Players" PlayersWho.codec ObjectRef.Players (\x -> case x of ObjectRef.Players y -> Just y; _ -> Nothing),
          Arm.payload "TopOfLibrary" TopOfLibrary.codec ObjectRef.TopOfLibrary (\x -> case x of ObjectRef.TopOfLibrary y -> Just y; _ -> Nothing),
          Arm.payload "TopOfLibraryUntil" TopOfLibraryUntil.codec ObjectRef.TopOfLibraryUntil (\x -> case x of ObjectRef.TopOfLibraryUntil y -> Just y; _ -> Nothing),
          -- CR 404.1's own end of the pile, and the one arm carrying a bare
          -- 'Parun.Codec.PlayerRef' rather than a payload record: with no depth and no
          -- filter to state, the seat is the whole of what a card writes.
          Arm.payload "TopOfGraveyard" PlayerRef.codec ObjectRef.TopOfGraveyard (\x -> case x of ObjectRef.TopOfGraveyard y -> Just y; _ -> Nothing),
          Arm.payload "ChosenCardInGraveyard" ChosenCardInGraveyard.codec ObjectRef.ChosenCardInGraveyard (\x -> case x of ObjectRef.ChosenCardInGraveyard y -> Just y; _ -> Nothing),
          Arm.payload "ChosenCardInHand" ChosenCardInHand.codec ObjectRef.ChosenCardInHand (\x -> case x of ObjectRef.ChosenCardInHand y -> Just y; _ -> Nothing),
          Arm.payload "ChosenCardFromAmong" ChosenCardFromAmong.codec ObjectRef.ChosenCardFromAmong (\x -> case x of ObjectRef.ChosenCardFromAmong y -> Just y; _ -> Nothing),
          Arm.payload "EachCardFromAmong" EachCardFromAmong.codec ObjectRef.EachCardFromAmong (\x -> case x of ObjectRef.EachCardFromAmong y -> Just y; _ -> Nothing),
          Arm.payload "RandomCardInHand" RandomCardInHand.codec ObjectRef.RandomCardInHand (\x -> case x of ObjectRef.RandomCardInHand y -> Just y; _ -> Nothing),
          Arm.payload "RandomCardInGraveyard" RandomCardInGraveyard.codec ObjectRef.RandomCardInGraveyard (\x -> case x of ObjectRef.RandomCardInGraveyard y -> Just y; _ -> Nothing),
          Arm.payload "RandomCardInLibrary" RandomCardInLibrary.codec ObjectRef.RandomCardInLibrary (\x -> case x of ObjectRef.RandomCardInLibrary y -> Just y; _ -> Nothing),
          Arm.payload "AtRandom" codec ObjectRef.AtRandom (\x -> case x of ObjectRef.AtRandom y -> Just y; _ -> Nothing),
          Arm.payload "ChosenPermanents" ChosenPermanents.codec ObjectRef.ChosenPermanents (\x -> case x of ObjectRef.ChosenPermanents y -> Just y; _ -> Nothing),
          Arm.payload "AttachedToBound" AttachedToBound.codec ObjectRef.AttachedToBound (\x -> case x of ObjectRef.AttachedToBound y -> Just y; _ -> Nothing),
          Arm.payload "FromAnywhere" FromAnywhere.codec ObjectRef.FromAnywhere (\x -> case x of ObjectRef.FromAnywhere y -> Just y; _ -> Nothing),
          Arm.payload "AllOf" (Common.nonEmpty codec) ObjectRef.AllOf (\x -> case x of ObjectRef.AllOf y -> Just y; _ -> Nothing)
        ]

tagOf :: ObjectRef.ObjectRef -> String
tagOf x = case x of
  ObjectRef.InSlot {} -> "InSlot"
  ObjectRef.EachMatching {} -> "EachMatching"
  ObjectRef.EachCardInGraveyard {} -> "EachCardInGraveyard"
  ObjectRef.EachCardInYourHand {} -> "EachCardInYourHand"
  ObjectRef.EachCardInHand {} -> "EachCardInHand"
  ObjectRef.EachCardInYourLibrary {} -> "EachCardInYourLibrary"
  ObjectRef.EachCardYouOwn {} -> "EachCardYouOwn"
  ObjectRef.EachCardInExiledPile {} -> "EachCardInExiledPile"
  ObjectRef.EachCardEncodedOnSource {} -> "EachCardEncodedOnSource"
  ObjectRef.EachSpell {} -> "EachSpell"
  ObjectRef.EachAbility {} -> "EachAbility"
  ObjectRef.EachOnStack {} -> "EachOnStack"
  ObjectRef.EachPlayer {} -> "EachPlayer"
  ObjectRef.EachOpponent {} -> "EachOpponent"
  ObjectRef.ChosenPlayer {} -> "ChosenPlayer"
  ObjectRef.Players {} -> "Players"
  ObjectRef.TopOfLibrary {} -> "TopOfLibrary"
  ObjectRef.TopOfLibraryUntil {} -> "TopOfLibraryUntil"
  ObjectRef.TopOfGraveyard {} -> "TopOfGraveyard"
  ObjectRef.ChosenCardInGraveyard {} -> "ChosenCardInGraveyard"
  ObjectRef.ChosenCardInHand {} -> "ChosenCardInHand"
  ObjectRef.ChosenCardFromAmong {} -> "ChosenCardFromAmong"
  ObjectRef.EachCardFromAmong {} -> "EachCardFromAmong"
  ObjectRef.RandomCardInHand {} -> "RandomCardInHand"
  ObjectRef.RandomCardInGraveyard {} -> "RandomCardInGraveyard"
  ObjectRef.RandomCardInLibrary {} -> "RandomCardInLibrary"
  ObjectRef.AtRandom {} -> "AtRandom"
  ObjectRef.ChosenPermanents {} -> "ChosenPermanents"
  ObjectRef.AttachedToBound {} -> "AttachedToBound"
  ObjectRef.FromAnywhere {} -> "FromAnywhere"
  ObjectRef.AllOf {} -> "AllOf"
