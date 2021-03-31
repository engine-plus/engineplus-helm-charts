#!/usr/bin/python
# -*- coding: UTF-8 -*-
# generate airflow rest api rondom authorization token

import secrets
import sys


def main():
    airflow_rest_authorization_random_token = secrets.token_hex(32)
    print(airflow_rest_authorization_random_token)
    sys.exit(0)


if __name__ == '__main__':
    main()
