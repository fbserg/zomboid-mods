# Workshop presentation update, November 18, 2026

SERGBOOK verified the 1.0.1 Workshop download against source commit af6360c. Every file under CleanMisses/42 matched. Steam reported item 3842265515 public, returned the authored description verbatim and served the single fence illustration. The 128px and 268px covers retain the title and the hole beside the zombie.

The 42.22.2 combat probe loaded Lua from that download. After each of the game-start, server-start and ranged-swing events, a forced failed roll returned a miss and a successful roll returned a damaging hit record. All six assertions passed. This presentation update preserves the original gameplay script. Those method-level checks cover neither two connected players nor custom projectile systems.

## Version 1.2 range checks on SERGBOOK

The native range suite loaded the sandbox option through the 42.22.2 parser and executed the shipped Lua callbacks. It checked 16 expected thresholds, sampled 10,000 native zombie hit records per case, and verified restoration of the original combat coefficients. Receipt 20261119T040325-71ab1245b7bb passed. At 15 tiles the regular compound returned 572, 7,076 and 7,407 damage-eligible records. The heavy compound returned 625, 7,621 and 7,892. The three cases represent stock, bow correction only and both adjustments. Input base chances 75 and 80 include Archery 4 and the Pinpoint Carbon Arrow bonus. These checks sample hit records under controlled inputs. They do not measure live projectile impacts, health loss, kills or two-client networking.
