import boto3
from datetime import datetime, timedelta
import time

class CloudWatchActions:

    def __init__(self,clientinput):
        self.clientinput=clientinput
        self.logclient=boto3.client(self.clientinput['svcname'],aws_access_key_id=self.clientinput['accesskeyid'],aws_secret_access_key=self.clientinput['secretkey'],region_name=self.clientinput['region'])


    def querylogs(self,hours,srchkeyword,loggroupname):
        query = f'filter @message like "{srchkeyword}" | fields @timestamp, @message | sort @timestamp desc | limit 5'
        response = self.execute_log_query(loggroupname, query, hours, self.logclient)
        formatted_results = [self.convert_dictionary_to_object(r) for r in response['results']]
        return formatted_results


    @staticmethod
    def execute_log_query(log_group, query, hours, client):
        start_time = int((datetime.today() - timedelta(hours=hours)).timestamp())
        end_time = int(datetime.now().timestamp())
        start_query_response = client.start_query(logGroupName=log_group, startTime=start_time, endTime=end_time,
                                                  queryString=query, )
        query_id = start_query_response['queryId']
        print('Running Query...')
        while True:
            response = client.get_query_results(queryId=query_id)
            if response['status'] != 'Running': break
            time.sleep(3)
        print(response['status'])
        return response

    @staticmethod
    def convert_dictionary_to_object(d):
        o = {}
        for f in d:
            o[f['field']] = f['value']
        return o