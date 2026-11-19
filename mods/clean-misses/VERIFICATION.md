# Workshop presentation update, November 18, 2026

SERGBOOK verified the 1.0.1 Workshop download against source commit af6360c. Every file under CleanMisses/42 matched. Steam reported item 3842265515 public, returned the authored description verbatim and served the single fence illustration. The 128px and 268px covers retain the title and the hole beside the zombie.

The 42.22.2 combat probe loaded Lua from that download. After each of the game-start, server-start and ranged-swing events, a forced failed roll returned a miss and a successful roll returned a damaging hit record. All six assertions passed. This presentation update preserves the original gameplay script. Those method-level checks cover neither two connected players nor custom projectile systems.

## Version 1.2 range checks on SERGBOOK

The native range suite loaded the sandbox option through the 42.22.2 parser and executed the shipped Lua callbacks. It checked 16 expected thresholds, sampled 10,000 native zombie hit records per case, and verified restoration of the original combat coefficients. Receipt 20261119T040325-71ab1245b7bb passed. At 15 tiles the regular compound returned 572, 7,076 and 7,407 damage-eligible records. The heavy compound returned 625, 7,621 and 7,892. The three cases represent stock, bow correction only and both adjustments. Input base chances 75 and 80 include Archery 4 and the Pinpoint Carbon Arrow bonus. These checks sample hit records under controlled inputs. They do not measure live projectile impacts, health loss, kills or two-client networking.

## Steam download, loaded world and zombie health

On SERGBOOK the world suite verified the downloaded Workshop runtime against the release source, loaded Build 42.22.2, and created a disposable dedicated-server world. It instantiated inventory weapons, a player and a zombie. The probe supplied distance to the full game accuracy calculation. It saved the enabled sandbox option, quit, and repeated the measurements after a fresh server boot. It did not simulate cursor placement, projectile travel or trigger pulls.

In run 20261119T040748-46b610eabc5e, the Hunting Rifle at 20 tiles returned a 6% roll with the option off and 20% with it on. For 512 trials per condition, the probe requested the game's hit record, passed each contact to the native zombie hit method with identical input damage, and checked current health against the reset starting health. Health fell in 29/512 baseline trials and 98/512 enabled trials. These are frequencies of health loss, not shots to kill. Fresh test worlds produced different absolute rifle probabilities.

| Weapon | Tiles | Off | On |
|---|---:|---:|---:|
| Pistol | 5 | 55% | 55% |
| Pistol | 15 | 6% | 25% |
| Shotgun | 10 | 51% | 56% |
| Hunting and Varmint Rifles | 10 | 46% | 46% |
| Hunting and Varmint Rifles | 15 | 15% | 33% |
| Hunting and Varmint Rifles | 20 | 6% | 20% |
| Hunting and Varmint Rifles | 30 | 6% | 6% |
| Hunting Rifle with 8x scope | 10 | 18% | 35% |
| Hunting Rifle with 8x scope | 20 | 48% | 48% |
| Hunting Rifle with 8x scope | 30 | 6% | 19% |

Percentages round the game's integer threshold into success probabilities for a roll from 0 to 99 inclusive. Distances above the item's maximum range were excluded. A scope changes both edges of the sight window. Reducing its outside-window penalty can improve a too-close shot as well as a long shot. Weapon damage inputs stay the same. The test observed no improvement for the unscoped rifles at 30 tiles in this world because both results reached the minimum chance.

The network suite booted a dedicated server with the option enabled, then connected two independent game clients with the downloaded release. Both reported the active 2 and 0 coefficients over their connections and received the server acknowledgement. This covers client configuration on join. The suite did not fire client-originated projectiles or measure latency. The native roll suite also passed again across all 16 cases and 160,000 rolls.

## RadArchery bow damage

The dedicated-world bow suite loaded RadArchery 1.9.1 and the verified Clean Misses Workshop download on 42.22.2. It ran RadArchery's actual client equip scripts on test actors with Archery 4 and selected a real Pinpoint Carbon Arrow item for a bow with one round. All 21 inventory bow variants received the expected skill and arrow accuracy bonus, twice the bow's script minimum damage for this arrow, the corrected 3–14 sight range and a higher 15-tile damage threshold. All 21 passed again after saving the optional range setting and restarting the game server.

For the black regular and Heavy Compound variants, the fixture compared native zombie health before and after each contact, with 512 native hit rolls per condition, using the arrow-adjusted minimum damage. The original sight behavior was reproduced by resetting the item's sight fields to zero to exclude local script edits. With stock sight fields and the normal damage-chance mode, 22 regular and 44 heavy trials reduced health. With the sight correction and Clean Misses' default mode, 317 regular and 348 heavy trials reduced health. With the optional range adjustment also enabled, 325 regular and 376 heavy trials reduced health. These are samples from one world, with distance supplied to the native calculation. The test does not draw or release the bow, simulate a projectile trajectory or verify arrow recovery over the network.
