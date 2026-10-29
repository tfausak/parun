{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamageRewrite where

import qualified Data.Typeable as Typeable
import qualified Numeric.Natural as Natural
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.Codec.Scaling as Scaling
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageRewrite as DamageRewrite
import qualified Parun.Types.Recipient as Recipient.Type

-- | The wire format is unchanged by the conversion to a bundle.
--
-- The effect codec is a PARAMETER rather than an import, for the reason
-- Parun.Codec.DamageR gives: @RunEffects@ carries a card's effects and neither
-- module may name the other.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (DamageRewrite.DamageRewrite effect)
codec effectCodec =
  Arm.tagged
    tagOf
    [ Arm.nullary "PreventAll" DamageRewrite.PreventAll,
      Arm.nullary "PreventRemovingShieldCounter" DamageRewrite.PreventRemovingShieldCounter,
      Arm.payload "PreventNext" Common.natural DamageRewrite.PreventNext (\x -> case x of DamageRewrite.PreventNext y -> Just y; _ -> Nothing),
      Arm.payload "PreventAllBut" Common.natural DamageRewrite.PreventAllBut (\x -> case x of DamageRewrite.PreventAllBut y -> Just y; _ -> Nothing),
      Arm.payload "PreventUpTo" Quantity.codec DamageRewrite.PreventUpTo (\x -> case x of DamageRewrite.PreventUpTo y -> Just y; _ -> Nothing),
      Arm.payload "SetAmount" Common.natural DamageRewrite.SetAmount (\x -> case x of DamageRewrite.SetAmount y -> Just y; _ -> Nothing),
      Arm.payload "Scale" Scaling.codec DamageRewrite.Scale (\x -> case x of DamageRewrite.Scale y -> Just y; _ -> Nothing),
      Arm.payload "Redirect" Recipient.codec DamageRewrite.Redirect (\x -> case x of DamageRewrite.Redirect y -> Just y; _ -> Nothing),
      Arm.payload "RedirectNext" redirectNext (uncurry DamageRewrite.RedirectNext) (\x -> case x of DamageRewrite.RedirectNext n y -> Just (n, y); _ -> Nothing),
      Arm.payload "RedirectMatching" (Filter.codec Keyword.codec) DamageRewrite.RedirectMatching (\x -> case x of DamageRewrite.RedirectMatching y -> Just y; _ -> Nothing),
      Arm.payload "RunEffects" (Common.seq effectCodec) DamageRewrite.RunEffects (\x -> case x of DamageRewrite.RunEffects y -> Just y; _ -> Nothing),
      Arm.nullary "TurnFaceUp" DamageRewrite.TurnFaceUp
    ]

-- | The counted redirection's two halves keyed by name rather than positional,
-- the convention every payload follows (#1464): the remaining amount and the
-- destination it moves damage to.
redirectNext :: Codec.Codec (Natural.Natural, Recipient.Type.Recipient)
redirectNext = Fields.object $ do
  remaining <- Fields.required "remaining" Common.natural fst
  to <- Fields.required "to" Recipient.codec snd
  pure (remaining, to)

tagOf :: DamageRewrite.DamageRewrite effect -> String
tagOf x = case x of
  DamageRewrite.PreventAll {} -> "PreventAll"
  DamageRewrite.PreventRemovingShieldCounter {} -> "PreventRemovingShieldCounter"
  DamageRewrite.PreventNext {} -> "PreventNext"
  DamageRewrite.PreventAllBut {} -> "PreventAllBut"
  DamageRewrite.PreventUpTo {} -> "PreventUpTo"
  DamageRewrite.SetAmount {} -> "SetAmount"
  DamageRewrite.Scale {} -> "Scale"
  DamageRewrite.Redirect {} -> "Redirect"
  DamageRewrite.RedirectNext {} -> "RedirectNext"
  DamageRewrite.RedirectMatching {} -> "RedirectMatching"
  DamageRewrite.RunEffects {} -> "RunEffects"
  DamageRewrite.TurnFaceUp {} -> "TurnFaceUp"
