import requests
import json

class MsTeamsClass:

    def __init__(self,webhookurl):
        self.webhookurl=webhookurl

    def sendmessage(self,msgtxt):

        msgpayload={"text":msgtxt}
        headers={'Content-Type': 'application/json'}

        response = requests.post(self.webhookurl, headers=headers, data=json.dumps(msgpayload))
        print(response.status_code)
        return ({"status":response.status_code,"resptxt":response.text})
