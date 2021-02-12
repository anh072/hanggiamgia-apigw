# hanggiamgia-apigw

## How to deploy locally
Make sure you have access key with permissions for Cloudformation, Api Gateway, Lambda, S3 and IAM

Before you can deploy, you need to run the build first which will generate `.aws-sam` folder with artifacts inside
```
make localBuild
```

Now you can deploy
```
make deployApp
```

You can also test locally
```
make localTest
```