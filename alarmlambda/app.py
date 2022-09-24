import requests
import os
import json


def lambda_handler(event, context):
    api_url=os.getenv('API_URL')
    log_duration_hrs=os.getenv('LOG_DURATION')
    error_keyword=os.getenv('ERR_KEYWORD')
    grpname=getLogGrpName(event)
    send_alert(grpname,api_url,log_duration_hrs,error_keyword)
    return {'status':'success'}
    

def send_alert(loggrpname,api_url,log_duration_hrs,error_keyword):
    alert_url=f'{api_url}/sendalert'
    reqbody={"loggroupname":f'/aws/lambda/{loggrpname}',"duration":log_duration_hrs,"errorkeyword":error_keyword}
    response = requests.request(method="POST", url=alert_url,json = reqbody)
    respdata = response.json()
    print(respdata)

def getLogGrpName(event):
    grpname=json.loads(event['Records'][0]['Sns']['Message'])
    print(grpname['AlarmName'])
    return grpname['AlarmName']