{-
Copyright 2016 SlamData, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-}

module Quasar.Mount.SparkLocal
  ( Config
  , toJSON
  , fromJSON
  , parseDirPath
  -- , toPath
  -- , fromPath
  , module Exports
  ) where

import Prelude
import Data.Path.Pathy as P
import Data.Argonaut (Json, decodeJson, jsonEmptyObject, (.?), (:=), (~>))
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), maybe)
import Data.Path.Pathy (Abs, Dir, Path, Sandboxed, Unsandboxed, (</>))
import Quasar.Mount.Common (Host) as Exports

type Config = { path :: Maybe (Path Abs Dir Sandboxed) }

-- _.path

pathToConfig :: Maybe (Path Abs Dir Sandboxed) -> Config
pathToConfig path = { path }

sandbox
  ∷ forall a
  . Path Abs a Unsandboxed
  → Maybe (Path Abs a Sandboxed)
sandbox =
  map (P.rootDir </> _) <<< P.sandbox P.rootDir

parseDirPath :: String -> Maybe (Path Abs Dir Sandboxed)
parseDirPath = sandbox <=< P.parseAbsDir

toJSON ∷ Config → Json
toJSON config =
  let uri = P.printPath <$> config.path
  in "spark-local" := ("connectionUri" := uri ~> jsonEmptyObject) ~> jsonEmptyObject

fromJSON ∷ Json → Either String { path :: Maybe (Path Abs Dir Sandboxed) }
fromJSON
  = map (pathToConfig <<< Just)
  <<< maybe (Left "Couldn't sandbox") Right <<< parseDirPath
  <=< (_ .? "connectionUri")
  <=< (_ .? "spark-local")
  <=< decodeJson
