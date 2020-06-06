OLGhostMaster - Ghost Master
version 3.00
June 6, 2020

by Greg "OverloadUT" Laabs

OverloadUT@gmail.com
https://github.com/OverloadUT/OLGhostMaster

*******
*ABOUT*
*******

Ghost Master is a free-for-all gametype, like Deathmatch. When a player
is killed, they respawn as a ghost bound to their killer. Ghosts cannot
receive nor deal damage. When a ghost picks up items, they are given to
their master and the ghost earns "favor." If a ghost can earn 100 favor,
they "earn their freedom" and respawn as a player again. Another way for
a ghost to earn favor is by "tagging" enemy players. Ghosts can shoot a
tagging orb by pressing primary fire. Once a player has been tagged, the
ghost's master can easily see the location of the tagged player.

The objective is to capture every other player in the match as a ghost.


ChangeLog:

3.00
+ The mod has been renamed to Ghost Master and all language has been
  changed to be ghost-themed.
= The tutorial has been removed.

2.00
+ Added the "reward system." When a ghost becomes free, they gets weapons,
  health, ammo, adrenaline and armor depending on how much favor they had.
  This can be turned off in the game options.
+ Added an option that makes ghosts ethereal. Projectiles and players
  will pass right through ghosts. Off by default.
+ Made it so that bots are much more accurate when firing at a tagged
  player. Before, tagging players for a bot did nothing.
= Fixed a bug that made many of the announcements not work in multiplayer.
= Added all new voices for the announcements.
= Added all new voices to the tutorial, and changed the timings to match.

1.00
+ First release!


**************
*INSTALLATION*
**************

Unzip the contents of GhostMaster30.zip into your UT2004 directory. It
will place the files in the proper locations.

To play Ghost Master, fire up UT2004, go to instant action or host game,
then choose Ghost Master from the list of gametypes.

Refer to the dedicated server section below for information on running a
Ghost Master dedicated server.


******************
*GHOST MASTER HUD*
******************

There are a few extra things to understand on the Ghost Master HUD:

When you are a master, the score indicator in the top left (below the clock)
can be read as follows:
* The big number on the right represents the number of ghosts you control.
* The small number in the top left represents the number of other masters in
  the game.
* The small number in the bottom left represents the number of ghosts not under
  your control.
  
When you are a ghost, the score indicator in the top left is replaced with an
indicator showing how much favor you have accumulated.


******************
*DEDICATED SERVER*
******************

To run a dedicated server, add ?Game=OLGhostMaster.OLGhostGame to the commandline
of your server. (It would also be a good idea to add ServerPackages=OLGhostMaster
in your server's ini file.)