import json
import requests
import sys
import glob


ret_val=0
print("Verifying recorded md5sum for containers and making sure that recipies are present")
with open("data.json") as f:
    data = json.load(f)
    for c in data["containers"]:
        if not c["name"].split('.')[:-2] in [ x.split('.')[:-2] for x in glob.glob("Recipes/*.def")]:
            print(f"No .def file found for container {c['name']}")
            ret_val=1
            continue
        x = requests.head(f"{data['source_url']}/{c['name']}")
        if x.status_code != 200:
            print(f"Container {c['name']} does not seem to exist")
            continue
            ret_val=1
        if c["md5sum"] != x.headers["etag"]:
            print(f"Container {c['name']} md5sum missmatch. Please sync repository and container")
            print(f"ALSO VERIFY THAT RECIPIE IS CORRECT")
            ret_val=1
    print("Verifying that no extra containers are present")
    x =  requests.get(f"{data['source_url']}")
    present = [c['name'] for c in data["containers"]]
    for obj in x.content.decode("utf-8").split('\n'):
        if obj not in present:
            print("Container {c['name']} is not reported in the repository")
            ret_val=1
sys.exit(ret_val)

