#!/usr/bin/env python3

import os
import json
import requests
import time


SERVER = os.getenv("LEDSTRIP_SERVER", "http://10.0.0.10:8080")


for i in range(10):
    try:
        with open(f'demo/{i}.lua') as codefile:
            c = codefile.read()
    except:
        continue

    payload = {
        "code": c,
        "owner": "j",
        "id": i
    }
    print(c)
    r = requests.put(SERVER + '/api/code.json', json=payload)
    print(r)
    print(r.text)
