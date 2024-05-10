#update_hetzner.py
import requests
import os

# Получите значения из переменных окружения
api_token = os.getenv("HETZNER_DNS_KEY")
zone_id = os.getenv("HETZNER_ZONE_ID")
record_id = os.getenv("HETZNER_RECORD_ID")
new_ip = os.getenv("NEW_IP")
record_name = os.getenv("HETZNER_RECORD_NAME")


print(f"Zone ID: {zone_id}")
print(f"Record ID: {record_id}")
print(f"New IP: {new_ip}")
print(f"Record Name: {record_name}")
print(f" Key (first  chars): {api_token[:3]}...")
print(f"Length of  Key: {len(api_token)}")


headers = {
    "Content-Type": "application/json",
    "Auth-API-Token": api_token
}


data = {
    "value": new_ip,
    "ttl": 60, 
    "type": "A",
    "name": record_name,
    "zone_id": zone_id
}


url = f"https://dns.hetzner.com/api/v1/records/{record_id}"


response = requests.put(url, headers=headers, json=data)


if response.status_code == 200:
    print(f"Successfully updated A record {record_name} to {new_ip}")
else:
    print(f"Failed to update A record: {response.status_code}, {response.text}")
