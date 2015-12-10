tell application "Finder"
   tell disk "wc"
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {400, 100, 900, 450}
      set theViewOptions to the icon view options of container window
      set arrangement of theViewOptions to not arranged
      set icon size of theViewOptions to 72
      set background picture of theViewOptions to file ".background:bg1-dmg.png"
      make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
      set position of item "enveomics.app" of container window to {100, 100}
      set position of item "Applications" of container window to {400, 100}
      set position of item "LICENSE.pdf" of container window to {175, 250}
      set position of item "README.pdf" of container window to {325, 250}
      update without registering applications
      delay 5
      close
   end tell
end tell
