# About #

This is a simple WebRTC player based on libwebrtc from Google. It requires macOS 10.15 and up (since in 10.14 and possibly lower versions the symbol names between libwebrtc from Google and libwebrtc from WebKit collide and video does not work).

Currently you must manually build libwebrtc (which is kind of trivial if you follow https://webrtc.org/native-code/development/) and then change the path to it in the project settings.

The player is meant to support different signalling mechanisms (via adding classes that act as plugins), currently it only works with https://github.com/AirenSoft/OvenMediaEngine
