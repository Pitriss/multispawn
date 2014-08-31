multispawn mod for minetest

This mod allows you to define many named spawns through the ingame formspec gui.
To be allowed to manage spawns, you need spawn_admin privs. This mod saves its
settings into the world directory, in the file spawn.conf.

Spawns can be added/removed/edited without server restart.

This mod needs 0.4.8 or some latest git versions of 0.4.7

Commands:

/spawnset
Create spawn

/spawnremove <spawnid|spawnnum>
Remove spawn

/spawnedit <spawnid|spawnnum>
Edit spawn

/spawndefault <spawnid|spawnnum>
Set this spawn as default (New players and respawned dead players will be spawned here)

/spawnnear (playername)
Write name of (yours or playernames) nearest spawn

/spawn [spawnname|spawnid]
Spawns you to nearest/specified spawn

/spawnlist
List all available spawns

Credits:
Thanks to fairiestoy and Ritchie for suggestions, advice and testing, lathan for language fixes and sending patches.

Licence: WTFPL
