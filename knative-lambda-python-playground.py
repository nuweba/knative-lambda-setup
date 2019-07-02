"""
A very simple function simulating DynamoDB atomic update of executions count per version,
and also plays a little bit with Python syntax to export some environment information.

Written by Eyal Avni @ Nuweba
"""

import json
import os
import random
import subprocess
import boto3
import math
from collections import Iterable

EXPECTED_ITEMS_IN_ENV_VAR_PAIR = 2
FUNCTION_VERSION, FUNCTION_CREATOR = os.environ["FUNCTION_VERSION"], os.environ["FUNCTION_CREATOR"]

PLAYGROUND_CONFIG = {
    'table': 'PythonPlaygroundDB',
    'primary_key': 'functionVersion',
    'counter_field_name': 'executions'
}

UPDATE_STATEMENT = 'SET {counter_field_name} = {counter_field_name} + :inc'.format(**PLAYGROUND_CONFIG)

dynamodb = boto3.client('dynamodb')

def increase_execution_count(version):
    response = dynamodb.update_item(
        TableName=PLAYGROUND_CONFIG['table'], 
        Key={
            PLAYGROUND_CONFIG['primary_key'] :{'S': version}
        },
        UpdateExpression=UPDATE_STATEMENT,
        ExpressionAttributeValues={
            ':inc': {'N': '1'}
        },
        ReturnValues="UPDATED_NEW"
    )
    return int(response['Attributes']['executions']['N'])
    
def should_track_executions(event):
    """ A very not beautiful function, can also go with false-first """
    if event and isinstance(event, Iterable):
        if "queryStringParameters" in event:
            if "track" in event["queryStringParameters"]:
                return True
    return False

def print_playground():
    """
        If you can explain each line that's happening here, talk to us, you might be a good fit for Nuweba's team!
    """
    print(subprocess.getoutput("ps x"))
    empty_items = 0
    for i, env_var in enumerate(subprocess.getoutput("cat /proc/1/environ").split("\u0000")):
        env_contents = env_var.split("=")
        if len(env_contents) != EXPECTED_ITEMS_IN_ENV_VAR_PAIR:
            empty_items += 1
            continue
        print("{0} {1} is {2}!".format(*["In case you didn't know," if i == 0 else random.choice(["And", "Also", "Yes and", "I'm telling you,"])] + env_contents))
    print("Well.. that's it!")
    if empty_items > 0:
        print("Oh, and by the way, there even was %s in the list!" % ("even an empty item" if empty_items == 1 else "%d empty items" % (empty_items, ), ))

def lambda_handler(event, context):
    print_playground()
    
    execution_count_sentence = ""
    if should_track_executions(event):
         # lambda in Lambda! How beautiful 🙄 (and using an emoji in code comments..)
        ordinal = lambda n: "%d%s" % (n,"tsnrhtdd"[(n//10%10!=1)*(n%10<4)*n%10::4])
        execution_count_sentence = " for the %s time" % (ordinal(int(increase_execution_count(FUNCTION_VERSION))), )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Python Runtime%s! Version: %s, created by: %s' % (execution_count_sentence, FUNCTION_VERSION, FUNCTION_CREATOR))
    }