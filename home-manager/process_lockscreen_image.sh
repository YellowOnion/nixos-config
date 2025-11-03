#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gmic

gmic bg.png blur 5 rgb2hsv split c bg_noisemask.png lightness[-1] mul[-2,-1] sub[-2] 10% add[-1] 10% append[-3--1] c hsv2rgb output[-1] bg_lock.png
