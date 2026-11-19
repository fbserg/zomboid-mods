# Care Packages decisions

## Native parcel container

Use a craftable native inventory container and store the seal, label and revision in its item mod data. The failed corpse codec in `experiments/care-packages` stays as historical evidence. The new parcel keeps the same native item and nested inventories for each seal/open action. Normal save, transfer and food ageing own the contents. Reopen this choice if a supported game build stops saving or transferring native nested containers faithfully.

The carrier must hold the parcel in their main inventory to seal or open it. Game actions validate ownership and the seal revision at completion. The vanilla floor and container handoffs transfer the entire item. Hide sealed contents in the regular inventory tabs and nearby crafting sources, and reject queued transfers from or into sealed cargo. The address is a gift label. The note stays readable on the parcel after it is opened. Keep this design while the parcel is useful as a keepsake.

The parcel is a mod-defined item. Empty parcels before removing the mod so the game does not remove packed goods along with their carrier.

## Workshop draft cover

Use an original pixel parcel mark and wordmark for the draft preview and two native
screenshots for the gallery. The installed image tool was unavailable during preparation.
Revisit the wide promotional illustration before Workshop publication.
