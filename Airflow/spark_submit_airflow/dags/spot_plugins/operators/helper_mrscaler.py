import requests
import json


def create_cluster(BODY, SPOT_TOKEN, SPOT_ACCOUNT_ID):
    payload = BODY
    token = SPOT_TOKEN
    account_id = SPOT_ACCOUNT_ID
    headers = {'Authorization': 'Bearer ' + token}
    url = f'https://api.spotinst.io/aws/emr/mrScaler?accountId={account_id}'
    response = requests.request("POST", url, headers=headers, json = payload)
    json_response = response.json()
    return json_response['response']['items'][0]['id']

def terminate_cluster(mrScaler_id, SPOT_TOKEN):
    response = mrScaler_id
    token = SPOT_TOKEN
    payload  = {}
    headers = {'Authorization': 'Bearer ' + token}
    url = f"https://api.spotinst.io/aws/emr/mrScaler/{response}"
    response = requests.request("DELETE", url, headers=headers, json = payload)
    json_response = response.json()
    return json_response



