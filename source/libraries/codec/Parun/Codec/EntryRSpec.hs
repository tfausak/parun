module Parun.Codec.EntryRSpec where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.EntryR as EntryR
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.EntryR" $ do
  -- CR 110.5b, as a permanent enters tapped.
  Spec.it s "MkEntryR" $
    Common.assertCodec
      s
      (EntryR.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
      ( EntryR.MkEntryR
          { EntryR.matching = Filter.IsSource,
            EntryR.rewrite = EntryRewrite.Tapped
          }
      )
      " {\"matching\":{\"type\":\"IsSource\"},\"rewrite\":{\"type\":\"Tapped\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (EntryR.codec (GrantedAbility.codec Card.codec) (Effect.codec Card.codec (GrantedAbility.codec Card.codec)))
