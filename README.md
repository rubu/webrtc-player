# About #

This is a simple WebRTC player based on libwebrtc from Google. It requires macOS 10.15 and up (since in 10.14 and possibly lower versions the symbol names between libwebrtc from Google and libwebrtc from WebKit collide and video does not work).

The player is meant to support different signalling mechanisms (via adding classes that act as plugins), currently it only works with https://github.com/AirenSoft/OvenMediaEngine