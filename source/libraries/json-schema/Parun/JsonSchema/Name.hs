module Parun.JsonSchema.Name where

import qualified Data.Text as Text
import qualified Data.Typeable as Typeable
import qualified Parun.Extra.Builder as Builder
import qualified Parun.JsonPointer.Pointer as Pointer
import qualified Parun.JsonPointer.Token as Token
import qualified Parun.Uri.Fragment as Fragment

-- | The name a schema definition is filed under in @$defs@.
--
-- Names are derived from 'Typeable.TypeRep', never written by hand.
newtype Name = MkName
  { unwrap :: Text.Text
  }
  deriving (Eq, Ord, Show)

typeName :: (Typeable.Typeable a) => proxy a -> Name
typeName = MkName . Text.pack . show . Typeable.typeRep

-- | The @$ref@ that reaches the definition filed under a name: @Cost Keyword@
-- is filed under that name and referenced as @#/$defs/Cost%20Keyword@.
fragment :: Name -> Text.Text
fragment name =
  Text.pack
    . ('#' :)
    . Builder.toString
    . Fragment.encode
    . Pointer.encode
    . Pointer.MkPointer
    $ [Token.MkToken $ Text.pack "$defs", Token.MkToken $ unwrap name]
