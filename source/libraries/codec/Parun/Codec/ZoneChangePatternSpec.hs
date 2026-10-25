module Parun.Codec.ZoneChangePatternSpec where

import qualified Parun.Codec.ZoneChangePattern as ZoneChangePattern
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DiscardCause as DiscardCause
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChangePattern as ZoneChangePattern

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ZoneChangePattern" $ do
  -- Rest in Peace: any object that would be put into a graveyard from
  -- anywhere. Both narrowing fields are at their defaults, so neither reaches
  -- the wire.
  Spec.it s "MkZoneChangePattern" $
    Common.assertCodec
      s
      ZoneChangePattern.codec
      ZoneChangePattern.MkZoneChangePattern
        { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
          ZoneChangePattern.whatObject = Filter.And [],
          ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer,
          ZoneChangePattern.whenDiscarded = Nothing,
          ZoneChangePattern.causedBy = Nothing,
          ZoneChangePattern.duringResolution = False
        }
      " {\"whenDestination\":{\"type\":\"Graveyard\"}} "
  -- CR 614.1a: Anafenza, the Foremost's "a nontoken creature an opponent owns
  -- would die". The characteristic filter is what distinguishes this from the
  -- shape above, so it has to survive the wire.
  Spec.it s "MkZoneChangePattern (Anafenza, a nontoken creature)" $
    Common.assertCodec
      s
      ZoneChangePattern.codec
      ZoneChangePattern.MkZoneChangePattern
        { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
          ZoneChangePattern.whatObject = Filter.And [Filter.HasCardType CardType.Creature, Filter.Not Filter.IsToken],
          ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.Opponent,
          ZoneChangePattern.whenDiscarded = Nothing,
          ZoneChangePattern.causedBy = Nothing,
          ZoneChangePattern.duringResolution = False
        }
      " {\"whatObject\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}}]},\"whenDestination\":{\"type\":\"Graveyard\"},\"whoseObject\":{\"type\":\"Opponent\"}} "
  -- CR 702.34a's "instead of putting it anywhere else": no destination named,
  -- which is the default, so the whole pattern is the empty object.
  Spec.it s "MkZoneChangePattern (flashback, any destination)" $
    Common.assertCodec
      s
      ZoneChangePattern.codec
      ZoneChangePattern.MkZoneChangePattern
        { ZoneChangePattern.whenDestination = Nothing,
          ZoneChangePattern.whatObject = Filter.IsSource,
          ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer,
          ZoneChangePattern.whenDiscarded = Nothing,
          ZoneChangePattern.causedBy = Nothing,
          ZoneChangePattern.duringResolution = False
        }
      " {\"whatObject\":{\"type\":\"IsSource\"}} "
  -- CR 608.2n: Rod of Absorption's "as it resolves".
  Spec.it s "MkZoneChangePattern (Rod of Absorption, during resolution)" $
    Common.assertCodec
      s
      ZoneChangePattern.codec
      ZoneChangePattern.MkZoneChangePattern
        { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
          ZoneChangePattern.whatObject = Filter.IsSource,
          ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer,
          ZoneChangePattern.whenDiscarded = Nothing,
          ZoneChangePattern.causedBy = Nothing,
          ZoneChangePattern.duringResolution = True
        }
      " {\"duringResolution\":true,\"whatObject\":{\"type\":\"IsSource\"},\"whenDestination\":{\"type\":\"Graveyard\"}} "
  -- CR 609.1: Obstinate Baloth's "a spell or ability an opponent controls
  -- causes you to discard this card".
  Spec.it s "MkZoneChangePattern (Obstinate Baloth, caused by an opponent)" $
    Common.assertCodec
      s
      ZoneChangePattern.codec
      ZoneChangePattern.MkZoneChangePattern
        { ZoneChangePattern.whenDestination = Just Zone.Graveyard,
          ZoneChangePattern.whatObject = Filter.IsSource,
          ZoneChangePattern.whoseObject = ControllerRelation.Related PlayerRelation.AnyPlayer,
          ZoneChangePattern.whenDiscarded = Just DiscardCause.ByEffect,
          ZoneChangePattern.causedBy = Just PlayerRelation.Opponent,
          ZoneChangePattern.duringResolution = False
        }
      " {\"causedBy\":{\"type\":\"Opponent\"},\"whatObject\":{\"type\":\"IsSource\"},\"whenDestination\":{\"type\":\"Graveyard\"},\"whenDiscarded\":{\"type\":\"ByEffect\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ZoneChangePattern.codec
