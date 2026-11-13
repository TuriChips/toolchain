#!/usr/bin/env bash
# Fixture stand-in for a chip's random test: honours RUN_DIR like the real one.
echo PASS > "${RUN_DIR:-logs}/random-fixture.log"
