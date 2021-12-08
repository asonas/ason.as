local appId = std.extVar('appId');

local fileProvider = std.native('provide.file');

local logConfiguration(appId) = {
  log_driver: 'awslogs',
  options: {
    'awslogs-group': std.format('/ecs/hako/%s', appId),
    'awslogs-region': 'ap-northeast-1',
    'awslogs-stream-prefix': 'ecs',
  },
};

{
  appContainer(appCpu, appMemory, appImageName):: {
    image: '282782318939.dkr.ecr.ap-northeast-1.amazonaws.com/ason.as',
    cpu: appCpu,
    memory: appMemory,
    log_configuration: logConfiguration(appId),
    env: {
      ENV: 'production',
    },
  },
  frontContainer(cpu, memory):: {
    cpu: cpu,
    memory: memory,
    image_tag: '282782318939.dkr.ecr.ap-northeast-1.amazonaws.com/nginx',
    log_configuration: logConfiguration(appId),
  },
}
