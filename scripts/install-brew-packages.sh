#!/bin/bash

# Install Program Using Homebrew

# Update brew
brew update

# Install all our dependencies with bundle (See Brewfile)
brew bundle --file ../brew/Brewfile --verbose
