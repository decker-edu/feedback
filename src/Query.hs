{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators #-}

module Query where

import Data.Aeson.TH
import Data.Char
import Database.Persist.Sqlite

import qualified Model as Model

import Network.URI

import Relude

data Credentials
  = Credentials { credLogin :: Text
                , credPassword ::  Text
                }
  deriving ( Show )

$( deriveJSON
  defaultOptions { fieldLabelModifier = drop 4 . map toLower }
  ''Credentials)

data CommentData
  = CommentData { commentMarkdown :: Text
                , commentToken :: Maybe Text
                , commentDeck :: Text
                , commentSlide :: Text
                }
  deriving ( Show )

$( deriveJSON
  defaultOptions { fieldLabelModifier = drop 7 . map toLower }
  ''CommentData)

data Select
  = Select { selectDeck :: Text
           , selectSlide :: Maybe Text
           , selectToken :: Maybe Text
           }
  deriving Show

$( deriveJSON
  defaultOptions { fieldLabelModifier = drop 6 . map toLower }
  ''Select)

data CommentId = CommentId { idKey :: Key Model.Comment, idToken :: Maybe Text }
  deriving Show

$( deriveJSON defaultOptions { fieldLabelModifier = drop 2 . map toLower } ''CommentId)
