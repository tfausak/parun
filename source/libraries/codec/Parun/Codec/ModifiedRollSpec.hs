module Parun.Codec.ModifiedRollSpec where

import qualified Parun.Codec.ModifiedRoll as ModifiedRoll
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ModifiedRoll as ModifiedRoll
import qualified Parun.Types.PermissionLimit as PermissionLimit
import qualified Parun.Types.RollModifier as RollModifier
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TapPermanents as TapPermanents

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ModifiedRoll" $ do
  -- CR 706.2 as Clam-I-Am prints it, and the wire form
  -- data/cards/clam-i-am.json writes: a six-sided die that came up a 3.
  Spec.it s "MkModifiedRoll, Clam-I-Am's narrowed reroll" $
    Common.assertCodec
      s
      ModifiedRoll.codec
      ModifiedRoll.MkModifiedRoll
        { ModifiedRoll.sides = Just 6,
          ModifiedRoll.natural = Just 3,
          ModifiedRoll.modifier = RollModifier.Reroll,
          ModifiedRoll.cost = Nothing,
          ModifiedRoll.limit = PermissionLimit.Unlimited
        }
      " {\"sides\":6,\"natural\":3,\"modifier\":{\"type\":\"Reroll\"}} "
  -- Both narrowings and CR 706.2a's cost default away, which is Wall of
  -- Fortune's bare "a die" with its cost dropped.
  Spec.it s "MkModifiedRoll narrowing nothing" $
    Common.assertCodec
      s
      ModifiedRoll.codec
      ModifiedRoll.MkModifiedRoll
        { ModifiedRoll.sides = Nothing,
          ModifiedRoll.natural = Nothing,
          ModifiedRoll.modifier = RollModifier.Reroll,
          ModifiedRoll.cost = Nothing,
          ModifiedRoll.limit = PermissionLimit.Unlimited
        }
      " {\"modifier\":{\"type\":\"Reroll\"}} "
  -- CR 706.2a's associated cost, and the wire form
  -- data/cards/wall-of-fortune.json writes: a non-mana cost of one tap.
  Spec.it s "MkModifiedRoll, Wall of Fortune's costed reroll" $
    Common.assertCodec
      s
      ModifiedRoll.codec
      ModifiedRoll.MkModifiedRoll
        { ModifiedRoll.sides = Nothing,
          ModifiedRoll.natural = Nothing,
          ModifiedRoll.modifier = RollModifier.Reroll,
          ModifiedRoll.cost =
            Just
              Cost.MkCost
                { Cost.mana = Just (ManaCost.MkManaCost []),
                  Cost.components =
                    [ CostComponent.TapPermanents
                        TapPermanents.MkTapPermanents
                          { TapPermanents.count = CostAmount.Fixed 1,
                            TapPermanents.whichPermanents = Filter.HasSubtype Subtype.Wall,
                            TapPermanents.sharingACreatureType = False
                          }
                    ]
                },
          ModifiedRoll.limit = PermissionLimit.Unlimited
        }
      " {\"modifier\":{\"type\":\"Reroll\"},\"cost\":{\"mana\":[],\"components\":[{\"type\":\"TapPermanents\",\"value\":{\"count\":{\"type\":\"Fixed\",\"value\":1},\"whichPermanents\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Wall\"}}}}]}} "
  -- CR 706.2b's second step with a life cost and a budget, the wire form
  -- data/cards/night-shift-of-the-living-dead.json writes.
  Spec.it s "MkModifiedRoll, Night Shift of the Living Dead's budgeted adjustment" $
    Common.assertCodec
      s
      ModifiedRoll.codec
      ModifiedRoll.MkModifiedRoll
        { ModifiedRoll.sides = Nothing,
          ModifiedRoll.natural = Nothing,
          ModifiedRoll.modifier = RollModifier.IncreaseOrDecrease 1,
          ModifiedRoll.cost = Just Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost []), Cost.components = [CostComponent.PayLife (CostAmount.Fixed 1)]},
          ModifiedRoll.limit = PermissionLimit.OnceEachTurn
        }
      " {\"modifier\":{\"type\":\"IncreaseOrDecrease\",\"value\":1},\"cost\":{\"mana\":[],\"components\":[{\"type\":\"PayLife\",\"value\":{\"type\":\"Fixed\",\"value\":1}}]},\"limit\":{\"type\":\"OnceEachTurn\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ModifiedRoll.codec
