multispawn mod

multispawn mod for minetest

This mod allows to define many named spawns through ingame formspec gui. To be allowed
to manage spawns, you need spawn_admin privs. This mod save its settings into world directory,
to the file spawn.conf

This mod needs latest git version of minetest.

Commands:

/spawnset
Create spawn

/spawnremove <spawnid|spawnnum>
Remove spawn

/spawnedit <spawnid|spawnnum>
Edit spawn

/defaultspawn <spawnid|spawnnum>
Set this spawn as default (New players and respawned dead players will be spawned here)

/spawnnear
Write name of nearest spawn

/spawn [spawnname|psawnid]
Spawns you to nearest/specified spawn

/spawnlist
list all available spawns


Licence: WTFPL

This version is not finished yet. It is working, but default values are not implemented yet, so is needed to set some spawn first.