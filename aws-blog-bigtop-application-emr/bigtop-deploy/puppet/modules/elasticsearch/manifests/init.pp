# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class elasticsearch {
  class client {

    $clusterId = generate ("/bin/bash", "-c", "cat /mnt/var/lib/instance-controller/extraInstanceData.json |grep \"jobFlowId\" | cut -d':' -f2 | tr -d '\"' |tr -d ',' |tr -d ' '")
    notice("clusterId variable is: ${clusterId}")
    $region = generate ("/bin/bash", "-c", "cat /mnt/var/lib/instance-controller/extraInstanceData.json |grep 'region\"' | cut -d':' -f2 | tr -d '\"' |tr -d ',' |tr -d ' '")
    notice("region variable is: ${region}")
    $isMaster = generate ("/bin/bash", "-c", "cat /mnt/var/lib/info/instance.json | grep \"isMaster\" | cut -d':' -f2 | tr -d '\"' |tr -d ',' |tr -d ' '")
    notice("isMaster variable is: ${isMaster}")

    if ($isMaster){
      include master
    }
    else {
      include slave
    }
  }

  class master ($elasticsearch_port = 9200, $isMaster = "true") {
    include common
  }

  class slave ($elasticsearch_port = 9202, $isMaster = "false"){
    include common
  }

  class common () {
    package { ["elasticsearch"]: ensure => latest, }

    file {
      "/etc/elasticsearch/elasticsearch.yml":
      content => template("elasticsearch/elasticsearch.yml"),
      require => [Package["elasticsearch"]],
    }

    exec { "install aws plugin":
      command => "/usr/share/elasticsearch/bin/plugin -install elasticsearch/elasticsearch-cloud-aws/2.6.0",
      require => [Package["elasticsearch"]],
    }
    
    service { "elasticsearch":
      ensure =>running,
      subscribe => File["/etc/elasticsearch/elasticsearch.yml"],
      require => [Package["elasticsearch"]],
      hasrestart => true,
    }

  }
}
