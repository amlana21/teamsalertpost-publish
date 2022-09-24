from fastapi import FastAPI,Response
from fastapi.responses import PlainTextResponse,JSONResponse
import uvicorn
from pydantic import BaseModel
from teamsfuncs import MsTeamsClass
from cloudwatchactions import CloudWatchActions
from dynadbactions import DynadbActions
import os

accsskeyid=os.environ.get('ACCESSKEY_ID')
secretkey=os.environ.get('SECRETKEY')
region='us-east-1'
dynatablename=os.environ.get('DDB_TABLE_NAME')

class InputBody(BaseModel):
    loggroupname: str
    duration: int
    errorkeyword: str

app = FastAPI()
teamswebhook=os.environ.get('TEAMS_WEB_HOOK_URL')

@app.get("/",response_class=JSONResponse)
async def root():
    print('hello')
    return {"message": "Hello World"}

@app.post("/sendalert",response_class=JSONResponse)
async def send_alert(inputpayload: InputBody):
    # print(messagetext)
    respstatus={"status":"error"}
    cloudwatchsuccess=True
    teamsalertsent=False
    dbadded=False
    queryResp=[]
    try:
        cloudwatchobj=CloudWatchActions({'svcname':'logs','accesskeyid':accsskeyid,'secretkey':secretkey,'region':region})
        queryResp=cloudwatchobj.querylogs(inputpayload.duration,inputpayload.errorkeyword,inputpayload.loggroupname)
        print(queryResp)
    except Exception as e:
        print(f'Error in Querying Cloudwatch: {e}')
        respstatus['errortxt'] = str(e)
        cloudwatchsuccess=False
    if cloudwatchsuccess and len(queryResp)>0:
        try:
            teamsobj=MsTeamsClass(teamswebhook)
            sentstatus=teamsobj.sendmessage(f"A service has errored and triggered an alarm. Here is the latest error detail:\n Timestamp: {queryResp[0]['@timestamp']}   Error_Message: {queryResp[0]['@message']}. Please check Log Group: {inputpayload.loggroupname} for details.")
            if sentstatus['status']==200:
                respstatus['teamstatus']="sent"
                teamsalertsent=True
            else:
                raise Exception(sentstatus['resptxt'])
        except Exception as e:
            print(e)
            respstatus['errortxt'] = str(e)
            respstatus['teamstatus'] = "error"

        try:
            dynaobj=DynadbActions(dynatablename,{'svcname':'dynamodb','accesskeyid':accsskeyid,'secretkey':secretkey,'region':region})
            dberrstatus=[]
            for v in queryResp:
                addresp=dynaobj.add_item(v,teamsalertsent)
                if not(addresp==200):
                    dberrstatus.append(addresp)
            if len(dberrstatus)>0:
                raise Exception(f'{len(dberrstatus)} have failed to be added to the DB')
            dbadded=True
            respstatus['dbstatus'] = "added"
            respstatus['status']='success'
        except Exception as e:
            respstatus['dbstatus'] = "error"
            respstatus['dberror'] = str(e)
    else:
        try:
            teamsobj=MsTeamsClass(teamswebhook)
            sentstatus=teamsobj.sendmessage(f"A service has errored and triggered an alarm. Please check Log Group: {inputpayload.loggroupname} for details.")
            if sentstatus['status']==200:
                respstatus['teamstatus']="sent"
                teamsalertsent=True
            else:
                raise Exception(sentstatus['resptxt'])
        except Exception as e:
            print(e)
            respstatus['errortxt'] = str(e)
            respstatus['teamstatus'] = "error"
        respstatus['status']='success'
        respstatus['reason']='log group api not updated'


    return respstatus


@app.get("/queryalertdb",response_class=JSONResponse)
async def query_alert():
    respstatus={"status":"error"}
    try:
        dynaobj=DynadbActions(dynatablename,{'svcname':'dynamodb','accesskeyid':accsskeyid,'secretkey':secretkey,'region':region})
        errcount=dynaobj.query_items(2)
        respstatus['status']='success'
        respstatus['errorcount']=errcount
    except Exception as e:
        respstatus['errmsg']=str(e)
        print(e)
    return respstatus

@app.get("/queryalertprom",response_class=PlainTextResponse)
async def query_alertprom():
    errcount=0
    try:
        dynaobj=DynadbActions(dynatablename,{'svcname':'dynamodb','accesskeyid':accsskeyid,'secretkey':secretkey,'region':region})
        errcount=dynaobj.query_items(2)
    except Exception as e:
        print(e)
        print('Responding with default valuedue to api error..')
    return f'error_count {errcount}'


if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=5000, reload=True)