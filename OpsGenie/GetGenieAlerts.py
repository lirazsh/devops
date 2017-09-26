#!/usr/bin/python

import requests
import json

idList = []
alertData = []
_apiKey = 'GenieKey 75d7eadd-c38f-4f37-a6fd-e759dafcd41d'

jdata = json.loads(requests.get('https://api.opsgenie.com/v2/alerts?searchIdentifier=moovingon&searchIdentifierType=name',headers={'Authorization' : _apiKey}).content)

for i in jdata['data']:
	idList.append(i['id'])

for i in idList:
	alertData.append(requests.get('https://api.opsgenie.com/v2/alerts/' + i + '?identifierType=id', headers={'Authorization' : _apiKey}).content)

for i in alertData:
	print(json.dumps(json.loads(i), indent=4, sort_keys=True))
