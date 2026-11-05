module Parun.Codec.DrawRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.DrawRewrite as DrawRewrite

codec :: (Eq effect, Typeable.Typeable effect) => Codec.Codec effect -> Codec.Codec (DrawRewrite.DrawRewrite effect)
codec effectCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "GainLife" Common.natural DrawRewrite.GainLife (\x -> case x of DrawRewrite.GainLife y -> Just y; _ -> Nothing),
      Arm.payload "FromOutsideTheGame" FromOutsideTheGame.codec DrawRewrite.FromOutsideTheGame (\x -> case x of DrawRewrite.FromOutsideTheGame y -> Just y; _ -> Nothing),
      Arm.payload "Dredge" Common.natural DrawRewrite.Dredge (\x -> case x of DrawRewrite.Dredge y -> Just y; _ -> Nothing),
      Arm.nullary "YouDraw" DrawRewrite.YouDraw,
      Arm.payload "OthersMayPayLife" Common.natural DrawRewrite.OthersMayPayLife (\x -> case x of DrawRewrite.OthersMayPayLife y -> Just y; _ -> Nothing),
      Arm.nullary "FromGraveyardOrLose" DrawRewrite.FromGraveyardOrLose,
      Arm.nullary "RevealUntilChosenKind" DrawRewrite.RevealUntilChosenKind,
      Arm.payload "DrawInstead" Common.natural DrawRewrite.DrawInstead (\x -> case x of DrawRewrite.DrawInstead y -> Just y; _ -> Nothing),
      Arm.nullary "DiscardThenDrawOrMill" DrawRewrite.DiscardThenDrawOrMill,
      Arm.payload "KeepOneOfTopThenDraw" Quantity.codec DrawRewrite.KeepOneOfTopThenDraw (\x -> case x of DrawRewrite.KeepOneOfTopThenDraw y -> Just y; _ -> Nothing),
      Arm.payload "MaySkipFor" (Common.seq effectCodec) DrawRewrite.MaySkipFor (\x -> case x of DrawRewrite.MaySkipFor y -> Just y; _ -> Nothing)
    ]

tagOf :: DrawRewrite.DrawRewrite effect -> String
tagOf x = case x of
  DrawRewrite.GainLife {} -> "GainLife"
  DrawRewrite.FromOutsideTheGame {} -> "FromOutsideTheGame"
  DrawRewrite.Dredge {} -> "Dredge"
  DrawRewrite.YouDraw {} -> "YouDraw"
  DrawRewrite.OthersMayPayLife {} -> "OthersMayPayLife"
  DrawRewrite.FromGraveyardOrLose {} -> "FromGraveyardOrLose"
  DrawRewrite.RevealUntilChosenKind {} -> "RevealUntilChosenKind"
  DrawRewrite.DrawInstead {} -> "DrawInstead"
  DrawRewrite.DiscardThenDrawOrMill {} -> "DiscardThenDrawOrMill"
  DrawRewrite.KeepOneOfTopThenDraw {} -> "KeepOneOfTopThenDraw"
  DrawRewrite.MaySkipFor {} -> "MaySkipFor"
