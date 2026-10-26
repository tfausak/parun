module Parun.Codec.CopyException where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CardType as CardType
import qualified Parun.Codec.ChangeMode as ChangeMode
import qualified Parun.Codec.Color as Color
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SetPowerToughness as SetPowerToughness
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.Codec.Supertype as Supertype
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CopyException as CopyException

-- | The ability codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.CopyException is parametric: the ability codec reaches this one.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (CopyException.CopyException ability)
codec abilityCodec =
  let cardTypes =
        Fields.object $
          (,)
            <$> Fields.required "mode" ChangeMode.codec fst
            <*> Fields.required "cardTypes" (Common.set CardType.codec) snd
   in Arm.tagged
        tagOf
        [ Arm.payload "SetPowerToughness" SetPowerToughness.codec CopyException.SetPowerToughness $ \x -> case x of
            CopyException.SetPowerToughness y -> Just y
            _ -> Nothing,
          Arm.payload "GainKeywords" (Common.set Keyword.codec) CopyException.GainKeywords $ \x -> case x of
            CopyException.GainKeywords y -> Just y
            _ -> Nothing,
          Arm.nullary "GainThisAbility" CopyException.GainThisAbility,
          Arm.payload "CardTypes" cardTypes (uncurry CopyException.CardTypes) $ \x -> case x of
            CopyException.CardTypes mode y -> Just (mode, y)
            _ -> Nothing,
          Arm.payload "AddSubtypes" (Common.set Subtype.codec) CopyException.AddSubtypes $ \x -> case x of
            CopyException.AddSubtypes y -> Just y
            _ -> Nothing,
          Arm.payload "AddSupertypes" (Common.set Supertype.codec) CopyException.AddSupertypes $ \x -> case x of
            CopyException.AddSupertypes y -> Just y
            _ -> Nothing,
          Arm.payload "SetCreatureSubtypes" (Common.set Subtype.codec) CopyException.SetCreatureSubtypes $ \x -> case x of
            CopyException.SetCreatureSubtypes y -> Just y
            _ -> Nothing,
          Arm.payload "RemoveSupertypes" (Common.set Supertype.codec) CopyException.RemoveSupertypes $ \x -> case x of
            CopyException.RemoveSupertypes y -> Just y
            _ -> Nothing,
          Arm.payload "SetName" CardName.codec CopyException.SetName $ \x -> case x of
            CopyException.SetName y -> Just y
            _ -> Nothing,
          Arm.payload "SetColors" (Common.set Color.codec) CopyException.SetColors $ \x -> case x of
            CopyException.SetColors y -> Just y
            _ -> Nothing,
          Arm.nullary "NoManaCost" CopyException.NoManaCost,
          Arm.nullary "DontCopyColors" CopyException.DontCopyColors,
          Arm.payload "GainAbility" abilityCodec CopyException.GainAbility $ \x -> case x of
            CopyException.GainAbility y -> Just y
            _ -> Nothing
        ]

tagOf :: CopyException.CopyException ability -> String
tagOf x = case x of
  CopyException.SetPowerToughness {} -> "SetPowerToughness"
  CopyException.GainKeywords {} -> "GainKeywords"
  CopyException.GainThisAbility {} -> "GainThisAbility"
  CopyException.CardTypes {} -> "CardTypes"
  CopyException.AddSubtypes {} -> "AddSubtypes"
  CopyException.AddSupertypes {} -> "AddSupertypes"
  CopyException.SetCreatureSubtypes {} -> "SetCreatureSubtypes"
  CopyException.RemoveSupertypes {} -> "RemoveSupertypes"
  CopyException.SetName {} -> "SetName"
  CopyException.SetColors {} -> "SetColors"
  CopyException.NoManaCost {} -> "NoManaCost"
  CopyException.DontCopyColors {} -> "DontCopyColors"
  CopyException.GainAbility {} -> "GainAbility"
