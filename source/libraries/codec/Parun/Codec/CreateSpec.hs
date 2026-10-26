module Parun.Codec.CreateSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Create as Create
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Create as Create
import qualified Parun.Types.EntryAttack as EntryAttack
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | The @card@ and @ability@ parameters are instantiated at 'Text.Text': this
-- codec reaches them only through the supplied codecs, so any type proves the
-- shape.
codec :: Codec.Codec (Create.Create Text.Text Text.Text)
codec = Create.codec Common.text Common.text

-- CR 111.2's default creator under CR 109.5, which every case but the last
-- elides.
you :: PlayerRef.PlayerRef
you = PlayerRef.Relative PlayerRelation.You

plain :: EntryRiders.EntryRiders Quantity.Quantity Text.Text
plain =
  EntryRiders.defaultValue

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Create" $ do
  -- CR 111.1 with no rider, no slot and CR 111.2's default creator: two keys,
  -- which is most tokens in the pool.
  Spec.it s "MkCreate, every default elided" $
    Common.assertCodec
      s
      codec
      ( Create.MkCreate
          { Create.quantity = Quantity.Literal 2,
            Create.card = Text.pack "Spirit Token",
            Create.riders = plain,
            Create.slot = Nothing,
            Create.creator = you
          }
      )
      " {\"quantity\":{\"type\":\"Literal\",\"value\":2},\"card\":\"Spirit Token\"} "
  -- The slot alone. Under the positional payload this and the riders-alone case
  -- below were BOTH the three-element form, told apart by JSON TYPE; two named
  -- keys need no such argument.
  Spec.it s "MkCreate, slot alone" $
    Common.assertCodec
      s
      codec
      ( Create.MkCreate
          { Create.quantity = Quantity.Literal 1,
            Create.card = Text.pack "Spirit Token",
            Create.riders = plain,
            Create.slot = Just (SlotName.MkSlotName (Text.pack "token")),
            Create.creator = you
          }
      )
      " {\"quantity\":{\"type\":\"Literal\",\"value\":1},\"card\":\"Spirit Token\",\"slot\":\"token\"} "
  -- CR 110.5b's riders alone.
  Spec.it s "MkCreate, riders alone" $
    Common.assertCodec
      s
      codec
      ( Create.MkCreate
          { Create.quantity = Quantity.Literal 2,
            Create.card = Text.pack "Spirit Token",
            Create.riders = plain {EntryRiders.attacking = Just EntryAttack.Chosen},
            Create.slot = Nothing,
            Create.creator = you
          }
      )
      " {\"quantity\":{\"type\":\"Literal\",\"value\":2},\"card\":\"Spirit Token\",\"riders\":{\"attacking\":{\"type\":\"Chosen\"}}} "
  -- CR 111.2's creator alone, the key a card writes when the sentence names
  -- somebody other than "you".
  Spec.it s "MkCreate, a creator other than you" $
    Common.assertCodec
      s
      codec
      ( Create.MkCreate
          { Create.quantity = Quantity.Literal 1,
            Create.card = Text.pack "Centaur Token",
            Create.riders = plain,
            Create.slot = Nothing,
            Create.creator = PlayerRef.HolderOfBound Holder.Controller Hop.Itself (SlotName.MkSlotName (Text.pack "victim"))
          }
      )
      " {\"quantity\":{\"type\":\"Literal\",\"value\":1},\"card\":\"Centaur Token\",\"creator\":{\"type\":\"HolderOfBound\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"hop\":{\"type\":\"Itself\"},\"slot\":\"victim\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
