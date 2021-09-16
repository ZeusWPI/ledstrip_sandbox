#!/bin/bash

scp -r main root@10.1.0.212:ledstrip_sandbox/
ssh root@10.1.0.212 "cd ledstrip_sandbox/ && cmake --build build"