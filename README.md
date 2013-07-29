r9util
======

[![Build Status](https://travis-ci.org/kayakco/puppet-r9util.png)](https://travis-ci.org/kayakco/puppet-r9util)

This module contains miscellaneous utilities for use in KAYAK's Puppet modules.

## Types

### r9util::java_properties

Set properties in Java properties files with augeas. Uses Craig Dunn's Properties augeas lens.

### r9util::download

Download a file with curl.

### r9util::system_user

Bundles Puppet's user and group types together for convenience.

## Functions

### deep_merge

Deep merging of data structures consisting of nested hashes and arrays. Offers several types of array merges.

### predictable_pretty_json

Renders predictable pretty JSON under Ruby 1.8.7 by sorting hashes by key before printing results.

