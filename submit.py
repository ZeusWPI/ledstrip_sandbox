import json
import requests
import time






for i in range(10):
    try:
        with open(f'demo/{i}.lua') as codefile:
            c = codefile.read()
    except:
        continue
    time.sleep(0.3)
    j = {
        "code": c,
        "owner": "j",
        "id": i
    }
    r = requests.put('http://10.1.0.212:8080/api/code.json', json=j)
    print(r)
    print(r.text)