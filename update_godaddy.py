# update_godaddy.py

import requests
import os

godaddy_key = os.getenv("TF_VAR_godaddy_key")
godaddy_secret_key = os.getenv("TF_VAR_godaddy_secret_key")
domain = os.getenv("TF_VAR_godaddy_domain")
record_name = os.getenv("TF_VAR_godaddy_record_name")
new_ip = os.getenv("NEW_IP")


# debug
if godaddy_key:
    print(f"GoDaddy Key (first 5 chars): {godaddy_key[:5]}...")
    print(f"Length of GoDaddy Key: {len(godaddy_key)}")
else:
    print("GoDaddy Key not found.")

if godaddy_secret_key:
    print(f"GoDaddy Secret Key (first 5 chars): {godaddy_secret_key[:5]}...")
    print(f"Length of GoDaddy Secret Key: {len(godaddy_secret_key)}")
else:
    print("GoDaddy Secret Key not found.")


headers = {
    "Authorization": f"sso-key {godaddy_key}:{godaddy_secret_key}",
    "Content-Type": "application/json"
}

data = [{"data": new_ip, "ttl": 600}]

url = f"https://api.godaddy.com/v1/domains/{domain}/records/A/{record_name}"


print(f"Request URL: {url}")

response = requests.put(url, headers=headers, json=data)

if response.status_code == 200:
    print(f"Successfully updated A record {record_name}.{domain} to {new_ip}")
else:
    print(f"Failed to update A record: {response.status_code}, {response.text}")
