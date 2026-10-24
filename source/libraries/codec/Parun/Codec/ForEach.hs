{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ForEach where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.LoopMembers as LoopMembers
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PayGate as PayGate
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ForEach as ForEach
import qualified Parun.Types.LoopMembers as LoopMembers

-- | A bare object keyed by the record's field names.
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.ForEach gives: the record is parametric in the effect so that
-- neither module has to name the other.
--
-- The three structural fields are REQUIRED, unlike Parun.Codec.PreventNextDamage's
-- rider: a loop with no body and a loop with no name for its member are both an
-- author's mistake rather than a shorter way of saying something. `individually`
-- is not one of them: CR 608.2f says simultaneous processing is what happens "in
-- most cases", so its False is the rule's own default and a card states only the
-- exception. `members` defaults to LoopMembers.Every for the same reason: "for
-- each" is every member unless the card says "you may". `payGate` defaults to
-- Nothing, Parun.Codec.Clause's posture for the same field, and `startingWith`
-- to Nothing, CR 101.4's APNAP order.
codec ::
  (Typeable.Typeable effect) =>
  Codec.Codec effect ->
  Codec.Codec (ForEach.ForEach effect)
codec effectCodec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec ForEach.ref
  members <- Fields.defaulted "members" LoopMembers.Every LoopMembers.codec ForEach.members
  slot <- Fields.required "slot" SlotName.codec ForEach.slot
  body <- Fields.required "body" (Common.seq effectCodec) ForEach.body
  individually <- Fields.defaulted "individually" False Common.boolean ForEach.individually
  payGate <- Fields.defaulted "payGate" Nothing (Common.maybe PayGate.codec) ForEach.payGate
  startingWith <- Fields.defaulted "startingWith" Nothing (Common.maybe PlayerRef.codec) ForEach.startingWith
  pure
    ForEach.MkForEach
      { ForEach.ref = ref,
        ForEach.members = members,
        ForEach.slot = slot,
        ForEach.body = body,
        ForEach.individually = individually,
        ForEach.payGate = payGate,
        ForEach.startingWith = startingWith
      }
