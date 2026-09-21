VEX GUILD SYNC 1.1.1

FIXED IN 1.1.1
Initializes the equipment item-level counters correctly for Beta characters.

INSTALL
1. Put the VexGuildSync folder in World of Warcraft/_classic_/Interface/AddOns.
   For a beta client, use that client's Interface/AddOns folder instead.
2. Restart WoW or type /reload.
3. If the beta marks it out of date, enable "Load out of date AddOns".
4. Type /vexsync (or /vgs).
5. Press Ctrl+C and paste the snapshot into My Characters on chatgptguild.com.

BETA
The addon reads item links and the character GUID directly from the running
client, so it does not need a hardcoded item database. Beta imports create or
update an independent Beta character automatically. Trying a different class
creates another Beta character and never changes the live guild roster.

PRIVACY
Nothing is uploaded automatically. The addon only reads the logged-in
character's public game profile, currently equipped gear and talents. The
player chooses whether to copy and import the snapshot.
