#!/bin/bash

scp -r main root@10.0.0.10:ledstrip_sandbox/
ssh root@10.0.0.10 "cd ledstrip_sandbox/ && cmake --build build"
