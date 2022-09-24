import json

def lambda_handler(event, context):
    print('Here is the error....')
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
