Where should the dataminer look for content.ggpk? Two files should be here, specific to your machine setup:

* `en`, the English PoE installation. Most language files are pulled from here.
  This one's required. Blank is okay if PoE's installed in a normal location -
  that is, if `pypoe_exporter` can guess it. `yarn export` uses this.
* `zh`, the Chinese PoE installation. Chinese language files are pulled from here.
  This one's optional. `yarn export` ignores it; `yarn export:zh` uses it.
  Unlike other language files, Chinese files are committed to git, so you can
  update/export other languages without downloading the Chinese version.
