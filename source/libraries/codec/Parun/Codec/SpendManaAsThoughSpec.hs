module Parun.Codec.SpendManaAsThoughSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.SpendManaAsThough as SpendManaAsThough
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaFilter as ManaFilter
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.SpendManaAsThough as SpendManaAsThough

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SpendManaAsThough" $ do
  -- CR 609.4b, as Celestial Dawn's first clause widens white to the five
  -- colours of CR 106.1a.
  Spec.it s "a permission" $
    Common.assertCodec
      s
      SpendManaAsThough.codec
      ( SpendManaAsThough.MkSpendManaAsThough
          { SpendManaAsThough.which = ManaFilter.OfType (ManaType.Colored Color.White),
            SpendManaAsThough.asThough = Set.fromList (fmap ManaType.Colored [Color.White, Color.Blue]),
            SpendManaAsThough.only = False,
            SpendManaAsThough.casting = Nothing
          }
      )
      " {\"which\":{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":\"White\"}},\"asThough\":[{\"type\":\"Colored\",\"value\":\"White\"},{\"type\":\"Colored\",\"value\":\"Blue\"}],\"only\":false} "
  -- Celestial Dawn's second clause, which carries the word "only".
  Spec.it s "a restriction" $
    Common.assertCodec
      s
      SpendManaAsThough.codec
      ( SpendManaAsThough.MkSpendManaAsThough
          { SpendManaAsThough.which = ManaFilter.NotOfType (ManaType.Colored Color.White),
            SpendManaAsThough.asThough = Set.singleton ManaType.Colorless,
            SpendManaAsThough.only = True,
            SpendManaAsThough.casting = Nothing
          }
      )
      " {\"which\":{\"type\":\"NotOfType\",\"value\":{\"type\":\"Colored\",\"value\":\"White\"}},\"asThough\":[{\"type\":\"Colorless\"}],\"only\":true} "
  -- Vizier of the Menagerie's "to cast creature spells".
  Spec.it s "a clause about one kind of spell" $
    Common.assertCodec
      s
      SpendManaAsThough.codec
      ( SpendManaAsThough.MkSpendManaAsThough
          { SpendManaAsThough.which = ManaFilter.Any,
            SpendManaAsThough.asThough = Set.singleton ManaType.Colorless,
            SpendManaAsThough.only = False,
            SpendManaAsThough.casting = Just (Filter.HasCardType CardType.Creature)
          }
      )
      " {\"which\":{\"type\":\"Any\"},\"asThough\":[{\"type\":\"Colorless\"}],\"only\":false,\"casting\":{\"type\":\"HasCardType\",\"value\":\"Creature\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SpendManaAsThough.codec
