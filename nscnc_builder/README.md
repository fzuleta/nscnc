# NS_CNC Mach4 breakdown profile

This repo is to understand the NSCNC mach4 profile, to be able to upgrade it.

#### this is what I know so far
- **Screens/NS_CNC_Mira_Series_V1.03.set** is actually a zip file, it contains an xml and images for the UI. BUT, the screen.xml also contains what will be built as the `ScreenScript.lua` (which is readonly). I've extracted the screen_load, plc, and signal scripts to `src/lua` to be able to understand them more.

- the `src/lua/profiles/macros` go into `Profiles/NS_CNC_3/Macros`.

- the `src/lua/modules/NS_CNC.lua` goes into `Modules/NS_CNC.lua`.

