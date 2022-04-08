Changelog
===========

2.2.29
-------

* Fix mysterious 422/404 upload errors for large uploads or slow connections

2.2.26
-------

* Fix broken URP assets from previous release

2.2.25
-------

* Re-add error logging from the script scanner
* Fix warning about global game manager in package

2.2.24
-------

* Fix meta files from previous release

2.2.23
-------

* Fix username/password authentication (introduced in 2.2.22)

2.2.22
-------

* Fix upload config persistence issues

2.2.19
-------

* Fix asset pagination issue

2.2.18
-------

* Add MSA login support on Windows
* Add the toon shader used by the Altspace avatars
* Clicking on an asset in the Uploader window will now ping it in the Project view
* Add buttons to expand/collapse all upload entries
* Fix build escaping issues that cause server validation to fail
* Hide all configs after the first in non-Advanced mode
* Fix kit thumbnail upload

2.2.16
-------

* Fix some shaders for single-pass instanced rendering

2.2.13
-------

* Add local script allow-list, so certain MonoBehaviours are not stripped out during build.
* Fix preserved credentials after signing out.
* Allow cameras in kits and templates, but only if they are drawing to a render texture.
* Automatically strip audio listeners, which break in-game audio.

2.2.10
-------

* Fix creating kit prefabs containing SpriteRenderers

2.2.8
------

* Fix upload auth token expiration across timezones

2.2.6
------

* Clean up some powershell errors
* Add bulk-add for upload entry items
* Fix preview scenes performance warning?

2.2.5
------

* Update Cmd API to be consistent across light baking and uploading
* Return error exit codes when a build fails from the Cmd API

2.2.4
------

* Downgrade missing powershell to a warning, switch to built-in powershell
* Better error handling in scene/prefab validators
* Add default "blank" item in kit/template dropdowns to prevent accidental uploads
* Fix build module detection on Mac
* Count skinned meshes in scene polygon counts
* Use Unity background progress bar for uploads (bottom-right of Editor)

2.2.3
------

* Fix exception when reporting upload errors

2.2.2
------

* Fix "could not create file" errors from the self-updater

2.2.1
------

* Filter out assets shared by a friend from the upload list
* Fix polygon counter for unindexed meshes

2.2.0
------

Initial release of the new Uploader.