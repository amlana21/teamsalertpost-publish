import boto3
import uuid
import datetime

class DynadbActions:

    def __init__(self,tablename,clientinput):
        self.tablename=tablename
        self.clientinput=clientinput
        self.dbclient = boto3.client(self.clientinput['svcname'], aws_access_key_id=self.clientinput['accesskeyid'],
                                      aws_secret_access_key=self.clientinput['secretkey'],
                                      region_name=self.clientinput['region'])


    def add_item(self,input,teamsalertsent):
        dbresponse = self.dbclient.put_item(
            Item={
                'id':{
                  'S':str(uuid.uuid4())
                },
                'timestamp': {
                    'S': input['@timestamp'],
                },
                'error_message': {
                    'S': input['@message'],
                },
                'alert_sent': {
                    'BOOL': teamsalertsent,
                }
            },
            ReturnConsumedCapacity='TOTAL',
            TableName=self.tablename,
        )
        print(dbresponse['ResponseMetadata']['HTTPStatusCode'])
        return dbresponse['ResponseMetadata']['HTTPStatusCode']

    def query_items(self,duration):
        format = "%Y-%m-%d %H:%M:%S.%f"
        errcount=0
        dbresponse=self.dbclient.scan(
            TableName=self.tablename
                    )
        for v in dbresponse['Items']:
            # print(v['timestamp']['S'])
            dt_object = datetime.datetime.strptime(v['timestamp']['S'], format)
            timediff=datetime.datetime.now()-dt_object
            timediff_hrs=timediff.total_seconds()/(60*60)
            if timediff_hrs<=duration:
                errcount+=1
        print(errcount)
        return errcount

