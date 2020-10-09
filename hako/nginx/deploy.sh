#/bin/sh -ex

envchain asonas-aws aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 282782318939.dkr.ecr.ap-northeast-1.amazonaws.com
docker build -t nginx .
docker tag nginx:latest 282782318939.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest
docker push 282782318939.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest
