{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module Engine where

import API

import Control.Monad.Logger

import qualified Data.Text as Text
import qualified Data.Text.IO as Text
import Data.Time.Clock

import Database.Persist
import Database.Persist.Sqlite

import Model

import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Cors

import Relude hiding ( group )

import Servant
import Servant.JS
import Servant.JS.Vanilla

import System.Directory
import System.Environment
import System.FilePath

-- | Starts the server. If policy is Nothing, no CORS headers are served.
-- This mode is meant to be used behind an Apache proxy server that handles the
-- generation of CORS headers. Otherwise, the list of CORS origin URLs is
-- parsed and passed to the CORS middleware (with credentials enabled).
app :: Maybe CorsResourcePolicy -> Application
app policy
  = case policy of
    Just policy -> corsWare policy $ serve deckerAPI deckerServer
    Nothing -> serve deckerAPI deckerServer

-- | Transform a comma separated string of origin URLs into a list for the cors 
-- middleware.
readOrigins :: String -> Maybe ( [ Origin ], Bool )
readOrigins line
  = case map Text.strip $ Text.splitOn "," $ toText line of
    [ "*" ] -> Nothing
    list -> Just ( map encodeUtf8 list, True )

corsPolicy :: Maybe ( [ Origin ], Bool ) -> CorsResourcePolicy
corsPolicy origins
  = CorsResourcePolicy
  { corsOrigins = origins
  , corsMethods = [ "GET", "HEAD", "POST", "DELETE" ]
  , corsRequestHeaders = [ "Authorization", "Content-Type" ]
  , corsExposedHeaders = Just [ "Content-Type" ]
  , corsMaxAge = Nothing
  , corsVaryOrigin = False
  , corsRequireOrigin = False
  , corsIgnoreFailures = False
  }

corsWare :: CorsResourcePolicy -> Middleware
corsWare policy = do cors (const $ Just policy)

daemon :: IO ()
daemon
  = do origins <- lookupEnv "DECKER_CORS_ORIGINS"
       putStrLn $ "CORS origins: " <> fromMaybe "<unset>" origins
       saveDocs "static/doc.md"
       runSqlite "db/engine.db" $ do runMigration migrateAll
       let policy = corsPolicy . readOrigins <$> origins
       if (isJust policy)
          then putStrLn $ "CORS origins: " <> show (corsOrigins <$> policy)
          else putStrLn "No CORS"
       run 8081 (app policy)

addExport :: Text -> Text
addExport = Text.unlines . map insert . Text.lines
  where
    insert
      line = if "var " `Text.isPrefixOf` line then "export " <> line else line

mock :: ReaderT SqlBackend IO (Key Comment)
mock
  = do now <- liftIO getCurrentTime
       p1 <- insert $ Person "person1"
       p2 <- insert $ Person "person2"
       insert
         $ Comment
           "What is the purpose of this stuff? Nobody ever needs to know this."
           "cgg"
           "intro-slide"
           (Just p1)
           now
       insert
         $ Comment
           "May I go to the bathroom?"
           "cgg"
           "intro-slide"
           (Just p1)
           now
       insert $ Comment "Wat?" "cgg" "intro-slide" (Just p2) now
       insert
         $ Comment
           "Fucking hell, this is really anonymous! Keep on swearing."
           "cgg"
           "slide-2"
           Nothing
           now
