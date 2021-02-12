# jwt-authorizer

## How to test locally

Make sure you are in `jwt-authorizer` folder. Also, this function is running python3.8 so you are required to have python3.8 installed locally in your computer.

To build dependencies. This will generate .aws-sam folder which contains all the dependency code.
```
sam build
```

`events` folder contains test environment variables and expected event payload sent to the lambda function.

To send the test event to the lambda function
```
sam local invoke --env-vars events/env.json -e events/event.json "Authorizer"
```
