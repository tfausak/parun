module Parun.Json.Object where

import qualified Data.ByteString.Builder as Builder
import qualified Data.Text as Text
import qualified Parun.Extra.Monoid as Monoid
import qualified Parun.Extra.Semigroup as Semigroup
import qualified Parun.Json.Array as Array
import qualified Parun.Json.Pair as Pair
import qualified Text.Parsec as Parsec

newtype Object a = MkObject
  { unwrap :: [Pair.Pair a]
  }
  deriving (Eq, Ord, Show)

decode :: Parsec.Parsec Text.Text u a -> Parsec.Parsec Text.Text u (Object a)
decode p =
  fmap MkObject
    . Parsec.between (Parsec.char '{' <* Array.decodeBlanks) (Parsec.char '}')
    $ Parsec.sepBy (Pair.decode p <* Array.decodeBlanks) (Parsec.char ',' <* Array.decodeBlanks)

encode :: (a -> Builder.Builder) -> Object a -> Builder.Builder
encode b =
  Semigroup.around (Builder.charUtf8 '{') (Builder.charUtf8 '}')
    . Monoid.sepBy (Builder.charUtf8 ',')
    . fmap (Pair.encode b)
    . unwrap
