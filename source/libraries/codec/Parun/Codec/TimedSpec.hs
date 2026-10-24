module Parun.Codec.TimedSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Text as Text
import qualified Parun.Codec.Timed as Timed
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CombatStep as CombatStep.Type
import qualified Parun.Types.Entry as Entry.Type
import qualified Parun.Types.Label as Label.Type
import qualified Parun.Types.Move as Move.Type
import qualified Parun.Types.Phase as Phase.Type
import qualified Parun.Types.Reference as Reference.Type
import qualified Parun.Types.Timed as Timed.Type
import qualified Parun.Types.When as When.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Timed" $ do
  Spec.it s "one flat object" $
    Common.assertCodec
      s
      Timed.codec
      (Timed.Type.MkTimed (When.Type.MkWhen 1 (Phase.Type.Combat CombatStep.Type.CombatDamage) (Label.Type.MkLabel (Text.pack "alice"))) (Just (ref "bear")) (Entry.Type.Do (Move.Type.AssignDamage (Map.singleton (ref "wall") 2))))
      " {\"turn\":1,\"step\":\"CombatDamage\",\"player\":\"alice\",\"source\":\"$bear\",\"do\":{\"AssignDamage\":{\"$wall\":2}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Timed.codec

ref :: String -> Reference.Type.Reference
ref = Reference.Type.Labelled . Label.Type.MkLabel . Text.pack
