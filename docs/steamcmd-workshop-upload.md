# Upload workshop content with steamcmd

## summary

Details of how to upload workshop items with steamcmd. Helps to automate upload of mods or even use animated previews.


**Required**: steamcmd
**Not required**: launch steam, launch game

## create the vdf file

```
"workshopitem"
{
	"appid"					"108600"
	"publishedfileid"		"5674"
	"contentfolder"			"D:\\Content\\workshopitem"
	"previewfile"			"D:\\Content\\preview.jpg"
	"visibility"			"0"
	"title"					"My Amazing Mod"
	"description"			"My Amazing Mod adds amazing features."
	"changenote"			"Version 1.2"
}
```

***Fields***:
- appid: the id of the app, 108600 is for Project Zomboid
- publishedfileid: the id of the workshop item
- contentfolder: directory of uploaded files. For PZ it should contain the `mods` directory, it contains all the mod directories. `contents:mods/mod`
- previewfile: file used for the workshop preview, dimensions are 256 x 256, size is 1Mb max. You can use either png or gif files. Size is determined by game's workshop settings.
- visibility: public = 0 / friends-only = 1 / private = 2 / unlisted = 3
- title: title - name of the workshop item
- description: description for the workshop item
- changenote: changenotes for the current version of the workshop item

***Notes***:      	
- appid must always be set
- To create a new item, publishedfileid must not be set or set to 0. After successfull creation, the publishedfileid will be automatically set in the file.
- To update an existing item the publishedfileid must be set and you must be the creator of the workshop item.
- The remaining key/value pairs should be included in the VDF if the key should be updated.
- The keys map to the various ISteamUGC::SetItem[...] methods.

## upload

Once the VDF has been created, steamcmd.exe can be run with the `workshop_build_item <build config filename>` file parameter. For example:
```
steamcmd.exe +login myLoginName myPassword +workshop_build_item workshop_green_hat.vdf +quit
```

Notes:
- uploading contents that have not changed does not make a new version.

# Reference

Steam documentation: [https://partner.steamgames.com/doc/features/workshop/implementation#SteamCmd](https://partner.steamgames.com/doc/features/workshop/implementation#SteamCmd)  

***Alternative ways to upalod content include using `ISteamUGC` while steam is running or uploading through the game.***