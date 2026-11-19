# Clean Misses

On Apocalypse in Project Zomboid 42.22, a zombie can bleed and flinch after a shot costs it zero health. With **Firearms Use Damage Chance** set to **Zombies only**, the game can register contact even when the accuracy roll fails. Clean Misses selects **Disabled**, the native mode in which a failed roll counts as a miss. A successful roll proceeds to the usual damage calculation.

If you control the sandbox settings, selecting **Disabled** yourself gives the same vanilla firearm behavior. The mod keeps that choice active when a world loads and when a ranged weapon swings. It adds no controls or dependencies.

Subscribe and enable **Clean Misses** in the world’s mod list. For servers, add Workshop item **3842265515** and enable mod **CleanMisses** for the server and clients. On a server previously set to **All types of target**, this also changes failed rolls against players. To remove, disable the mod and select the sandbox mode you want.

Weapon packs that use vanilla hit resolution inherit the setting. Custom projectile systems can use their own rules. Disable any minimum-hit-chance override if you want vanilla accuracy. Tested against the 42.22.2 combat resolver. The game supplies hit detection, damage and feedback.

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3842265515) · [Report a problem](https://github.com/fbserg/zomboid-mods/issues/new)

With RadArchery enabled, each registered bow uses a built-in sight range of 3 to 14 tiles. Projectile reach, arrow bonuses and Archery skill still come from RadArchery. For vanilla guns, Clean Misses changes hit feedback only. Shots per kill at distance can still be high.
