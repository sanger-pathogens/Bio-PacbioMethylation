#!/bin/bash

cpanm Dist::Zilla --notest
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
