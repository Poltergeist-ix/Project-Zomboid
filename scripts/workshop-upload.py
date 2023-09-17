"""

Build, clean files required for workshop upload. Upload content to workshop.
Supported OS: Windows
Project needs to have json with "$schema": "https://raw.githubusercontent.com/Konijima/project-zomboid-studio/master/pzstudio.schema.json"

"""

import json
import os
import subprocess
import sys
import pathlib

Visitibility_Values = {"public":"0","friendsOnly":"1","private":"2","unlisted":"3"}

class workshop_upload:

    def __init__(self,dir):
        self.dir = dir

    def prepare(self):
        with open(os.path.join(self.dir,"project.json"),"r",encoding="utf-8") as f:
            self.info = json.load(f)
        with open(os.path.join(self.dir,"workshop","description.txt"),"r",encoding="utf-8") as f:
            description = f.read()
        with open(os.path.join(self.dir,"workshop","change-logs.txt"),"r",encoding="utf-8") as f:
            changes = []
            #version check
            for line in f:
                if not line.strip():
                    break
                elif line.strip().startswith("--"):
                    continue
                else:
                    changes.append(line)
            changes = "".join(changes)
        with open(os.path.join(self.dir,"workshop","__workshop.vdf"),"w",encoding="utf-8") as f:
            f.write('"workshopitem"\n')
            f.write('{\n')
            f.write('\t"appid"\t\t"108600"\n')
            if "id" in self.info["workshop"] and self.info["workshop"]["id"] != 0:
                f.write('\t"publishedfileid"\t\t"' + str(self.info["workshop"]["id"]) + '"\n')
                self.ItemPreviouslyPublished = True
            else:
                f.write('\t"publishedfileid"\t\t"' + "0" + '"\n')
                self.ItemPreviouslyPublished = False
            f.write('\t"contentfolder"\t\t"' + os.path.join(self.dir,"workshop","contents") + '"\n')
            f.write('\t"previewfile"\t\t"' + os.path.join(self.dir,"workshop","preview.png") + '"\n') #TODO gif
            f.write('\t"visibility"\t\t"' + Visitibility_Values[self.info["workshop"]["visibility"]] +'"\n')
            f.write('\t"title"\t\t"' + self.info["title"] + '"\n')
            f.write('\t"description"\t\t"' + description + '"\n')
            if changes:
                f.write('\t"changenote"\t\t"' + changes + '"\n')
            f.write('}\n')

        modsDir = os.path.join(self.dir,"workshop","contents","mods")
        pathlib.Path(modsDir).mkdir(parents=True,exist_ok=True)
        for id in self.info["mods"]:
            if id in self.info["workshop"]["excludes"]:
                continue
            # os.symlink(os.path.join(self.dir,id),os.path.join(modsDir,id),target_is_directory=True)
            if not os.path.exists(os.path.join(modsDir,id)):
                subprocess.check_call('mklink /J "%s" "%s"' % (os.path.join(modsDir,id),os.path.join(self.dir,id)), shell=True) #fixme windows

    def clean(self):
        if not self.ItemPreviouslyPublished:
            with open(os.path.join(self.dir,"workshop","__workshop.vdf"),"r",encoding="utf-8") as f:
                for line in f:
                    if "publishedfileid" in line:
                        self.info["worksohp"]["id"] = int(line.replace("publishedfileid","").replace('"',"").strip())
                        break
            with open(os.path.join(self.dir,"project.json"),"w",encoding="utf-8") as f:
                json.dump(self.info,f,indent=2)
            
        os.remove(os.path.join(self.dir,"workshop","__workshop.vdf"))
        from shutil import rmtree
        rmtree(os.path.join(self.dir,"workshop","contents"))

if __name__ == "__main__":
    import getopt
    options, args = getopt.getopt(sys.argv[2:],"")
    obj = workshop_upload(sys.argv[1])
    obj.prepare()
    
    ### Fixme: login might need to login from cmd before
    ### replace user, password, steamcmd location
    res = subprocess.run([r"\steamcmd.exe", "+login user password", "+workshop_build_item " + os.path.join(obj.dir,"workshop","__workshop.vdf"), "+quit"])

    obj.clean()
