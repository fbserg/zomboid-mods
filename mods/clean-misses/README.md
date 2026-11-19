# Clean Misses

On Apocalypse in Project Zomboid 42.22, a zombie can bleed and flinch after a shot costs it zero health. With **Firearms Use Damage Chance** set to **Zombies only**, the game can register contact even when the accuracy roll fails. Clean Misses selects **Disabled**, the native mode in which a failed roll counts as a miss. A successful roll proceeds to the usual damage calculation.

If you control the sandbox settings, selecting **Disabled** yourself gives the same default firearm feedback. The mod keeps that choice active when a world loads and when a ranged weapon swings. It adds no controls or dependencies.

Subscribe and enable **Clean Misses** in the world’s mod list. For servers, add Workshop item **3842265515** and enable mod **CleanMisses** for the server and clients. On a server previously set to **All types of target**, this also changes failed rolls against players. To remove, disable the mod and select the sandbox mode you want.

Weapon packs that use vanilla hit resolution inherit the setting. Custom projectile systems can use their own rules. Disable any minimum-hit-chance override if you want vanilla accuracy. Tested against the 42.22.2 combat resolver. The game supplies hit detection, damage and feedback.

[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3842265515) · [Report a problem](https://github.com/fbserg/zomboid-mods/issues/new)

With RadArchery enabled, each registered bow uses a built-in sight range of 3 to 14 tiles. Projectile reach, arrow bonuses and Archery skill still come from RadArchery.

## Optional firearm range adjustment

Select **Clean Misses → Gentler range penalty** in sandbox settings and reload the world. This uses a linear two-point penalty per tile outside the sight window for the native sighted calculation. It affects PvP as well as zombies. The option defaults to off.

For steady shots at 15 tiles with Archery 4, Aiming 0 and a Pinpoint Carbon Arrow, the regular Compound Bow passes the damage roll 6% of the time in stock RadArchery, 71% with the bow correction and 74% with the range option too. The Heavy Compound gives 6%, 76% and 79%. These figures assume a standing zombie, ordinary vision and zero other penalties.
